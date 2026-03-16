import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../app_database.dart';
import '../tables/products.dart';
import '../tables/sales.dart';
import 'products_dao.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [Sales, SaleItems, Products])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.database);

  // ==================== CREATE ====================

  Future<Sale> createSale({
    required SalesCompanion sale,
    required List<SaleItemsCompanion> items,
    String? tableNumber,
    String? specialInstructions,
    bool createKitchenOrder = true, // KDS 주문 자동 생성 여부
  }) async {
    return await transaction(() async {
      final saleId = await into(sales).insert(sale);

      await batch((batch) {
        batch.insertAll(
          saleItems,
          items.map((item) => item.copyWith(saleId: Value(saleId))),
        );
      });

      final productsDao = ProductsDao(db);
      for (final item in items) {
        await productsDao.updateStock(
          productId: item.productId.value,
          quantity: -item.quantity.value,
          type: 'out',
          reason: 'sale',
          saleId: saleId,
        );
      }

      // KDS 주문 자동 생성 (restaurant/cafe용)
      if (createKitchenOrder) {
        try {
          final insertedSale = await (select(sales)..where((s) => s.id.equals(saleId))).getSingle();
          final kitchenOrdersDao = db.kitchenOrdersDao;
          await kitchenOrdersDao.createOrderFromSale(
            saleId: saleId,
            tableNumber: tableNumber,
            specialInstructions: specialInstructions,
            orderType: insertedSale.orderType,
          );
        } catch (e) {
          // KDS 기능이 없는 경우 무시
          debugPrint('Kitchen order creation skipped: $e');
        }
      }

      return await (select(sales)..where((s) => s.id.equals(saleId))).getSingle();
    });
  }

  // ==================== READ ====================

  Future<Sale> getSaleById(int id) {
    return (select(sales)..where((s) => s.id.equals(id))).getSingle();
  }

  Future<List<SaleItem>> getSaleItems(int saleId) {
    return (select(saleItems)..where((si) => si.saleId.equals(saleId))).get();
  }

  Future<List<Sale>> getSalesByDateRange(DateTime from, DateTime to) {
    return (select(sales)
          ..where((s) =>
              s.saleDate.isBiggerOrEqualValue(from) &
              s.saleDate.isSmallerOrEqualValue(to))
          ..orderBy([(s) => OrderingTerm.desc(s.saleDate)]))
        .get();
  }

  Future<List<Sale>> getTodaySales() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getSalesByDateRange(startOfDay, endOfDay);
  }

  Future<List<Sale>> searchSales({required String query, int limit = 20}) async {
    final q = query.trim().toLowerCase();
    return (select(sales)
      ..where((s) =>
        s.saleNumber.lower().like('%$q%') |
        s.customerName.lower().like('%$q%')
      )
      ..where((s) => s.status.equals('completed'))
      ..orderBy([(s) => OrderingTerm(expression: s.saleDate, mode: OrderingMode.desc)])
      ..limit(limit)
    ).get();
  }

  Stream<List<Sale>> watchTodaySales() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return (select(sales)
          ..where((s) => s.saleDate.isBiggerOrEqualValue(startOfDay))
          ..orderBy([(s) => OrderingTerm.desc(s.saleDate)]))
        .watch();
  }

  /// B-103: 날짜 범위 기반 실시간 스트림 (FutureProvider → StreamProvider 전환용)
  /// completed / refunded 상태만 표시 (open, pending, split 등 미결제 제외)
  Stream<List<Sale>> watchSalesByDateRange(DateTime from, DateTime to) {
    return (select(sales)
          ..where((s) =>
              s.saleDate.isBiggerOrEqualValue(from) &
              s.saleDate.isSmallerOrEqualValue(to) &
              s.status.isIn(['completed', 'refunded']))
          ..orderBy([(s) => OrderingTerm.desc(s.saleDate)]))
        .watch();
  }

  /// Watch open tab for a specific table (Phase 1: Open Tab support)
  /// Returns the active open-tab Sale for the given tableId, or null.
  Stream<Sale?> watchOpenTabByTableId(int tableId) {
    return (select(sales)
          ..where((s) =>
              s.tableId.equals(tableId) &
              s.isOpenTab.equals(true) &
              s.status.equals('open'))
          ..limit(1))
        .watchSingleOrNull();
  }

  // ==================== UPDATE ====================

  Future<int> updateSaleStatus(int saleId, String status) {
    return (update(sales)..where((s) => s.id.equals(saleId)))
        .write(SalesCompanion(
      status: Value(status),
      needsSync: const Value(true),
    ));
  }

  Future<void> refundSale(int saleId, int employeeId, {String? reason}) async {
    await transaction(() async {
      // Get sale details for refund record
      final sale = await (select(sales)..where((s) => s.id.equals(saleId))).getSingleOrNull();
      if (sale == null) {
        throw Exception('Sale not found');
      }

      // ✅ CRITICAL FIX 2: Update sale status to refunded
      await updateSaleStatus(saleId, 'refunded');

      // ✅ Create refund record with reason
      await into(db.refunds).insert(
        RefundsCompanion.insert(
          originalSaleId: saleId,
          originalSaleNumber: sale.saleNumber,
          refundAmount: sale.total,
          refundType: 'full',
          reason: Value(reason), // ✅ Store reason
          employeeId: Value(employeeId),
        ),
      );

      // Restock items
      final items = await getSaleItems(saleId);
      final productsDao = ProductsDao(db);

      for (final item in items) {
        await productsDao.updateStock(
          productId: item.productId,
          quantity: item.quantity,
          type: 'in',
          reason: 'refund',
          employeeId: employeeId,
          saleId: saleId,
        );
      }
    });
  }

  // ==================== ROUND NUMBER ====================

  /// Get next round number for an existing sale (for additional orders)
  Future<int> getNextRoundNumber(int saleId) async {
    final query = selectOnly(saleItems)
      ..addColumns([saleItems.roundNumber.max()])
      ..where(saleItems.saleId.equals(saleId));
    final result = await query.getSingle();
    final maxRound = result.read(saleItems.roundNumber.max()) ?? 0;
    return maxRound + 1;
  }

  /// Add items to an existing open-tab sale (additional round)
  Future<void> addItemsToSale({
    required int saleId,
    required List<SaleItemsCompanion> items,
    required int roundNumber,
    String? tableNumber,
    bool createKitchenOrder = true,
  }) async {
    await transaction(() async {
      // Insert new items with round number
      await batch((batch) {
        batch.insertAll(
          saleItems,
          items.map((item) => item.copyWith(
            saleId: Value(saleId),
            roundNumber: Value(roundNumber),
          )),
        );
      });

      // Deduct stock
      final productsDao = ProductsDao(db);
      for (final item in items) {
        await productsDao.updateStock(
          productId: item.productId.value,
          quantity: -item.quantity.value,
          type: 'out',
          reason: 'sale',
          saleId: saleId,
        );
      }

      // Update sale totals
      final allItems = await getSaleItems(saleId);
      final newSubtotal = allItems.fold<double>(0, (sum, i) => sum + i.total);
      await (update(sales)..where((s) => s.id.equals(saleId)))
          .write(SalesCompanion(
        subtotal: Value(newSubtotal),
        total: Value(newSubtotal),
        needsSync: const Value(true),
      ));

      // Create kitchen order for new round
      if (createKitchenOrder) {
        try {
          final sale = await (select(sales)..where((s) => s.id.equals(saleId))).getSingle();
          await db.kitchenOrdersDao.createOrderFromSale(
            saleId: saleId,
            tableNumber: tableNumber,
            specialInstructions: 'Round $roundNumber',
            orderType: sale.orderType,
          );
        } catch (e) {
          debugPrint('Kitchen order creation skipped: $e');
        }
      }
    });
  }

  // ==================== STATISTICS ====================

  /// B-103: 총 매출 실시간 스트림 (결제/환불 즉시 반영)
  Stream<double> watchTotalSales(DateTime from, DateTime to) {
    final query = selectOnly(sales)
      ..addColumns([sales.total.sum()])
      ..where(
        sales.saleDate.isBiggerOrEqualValue(from) &
            sales.saleDate.isSmallerOrEqualValue(to) &
            sales.status.equals('completed'),
      );
    return query.watch().map((rows) => rows.first.read(sales.total.sum()) ?? 0);
  }

  /// B-103: 주문 건수 실시간 스트림
  Stream<int> watchOrderCount(DateTime from, DateTime to) {
    final query = selectOnly(sales)
      ..addColumns([sales.id.count()])
      ..where(
        sales.saleDate.isBiggerOrEqualValue(from) &
            sales.saleDate.isSmallerOrEqualValue(to) &
            sales.status.equals('completed'),
      );
    return query.watch().map((rows) => rows.first.read(sales.id.count()) ?? 0);
  }

  /// B-103: 결제 방법별 매출 실시간 스트림
  Stream<List<PaymentMethodTotal>> watchPaymentBreakdown(DateTime from, DateTime to) {
    final query = selectOnly(sales)
      ..addColumns([sales.paymentMethod, sales.total.sum()])
      ..where(
        sales.saleDate.isBiggerOrEqualValue(from) &
            sales.saleDate.isSmallerOrEqualValue(to) &
            sales.status.equals('completed'),
      )
      ..groupBy([sales.paymentMethod])
      ..orderBy([OrderingTerm.desc(sales.total.sum())]);

    return query.watch().map((rows) => rows
        .map((row) => PaymentMethodTotal(
              method: row.read(sales.paymentMethod)!,
              total: row.read(sales.total.sum()) ?? 0,
            ))
        .toList());
  }

  Future<double> getTotalSales(DateTime from, DateTime to) async {
    final query = selectOnly(sales)
      ..addColumns([sales.total.sum()])
      ..where(
        sales.saleDate.isBiggerOrEqualValue(from) &
            sales.saleDate.isSmallerOrEqualValue(to) &
            sales.status.equals('completed'),
      );

    final result = await query.getSingle();
    return result.read(sales.total.sum()) ?? 0;
  }

  Future<double> getTodayTotalSales() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getTotalSales(startOfDay, endOfDay);
  }

  Future<List<ProductSalesStats>> getTopSellingProducts({
    required int limit,
    DateTime? from,
    DateTime? to,
  }) async {
    final query = selectOnly(saleItems)
      ..addColumns([
        saleItems.productId,
        saleItems.productName,
        saleItems.quantity.sum(),
        saleItems.total.sum(),
      ])
      ..groupBy([saleItems.productId, saleItems.productName])
      ..orderBy([OrderingTerm.desc(saleItems.quantity.sum())])
      ..limit(limit);

    if (from != null && to != null) {
      query.join([
        innerJoin(sales, sales.id.equalsExp(saleItems.saleId)),
      ]);
      query.where(
        sales.saleDate.isBiggerOrEqualValue(from) &
            sales.saleDate.isSmallerOrEqualValue(to),
      );
    }

    final results = await query.get();

    return results.map((row) {
      return ProductSalesStats(
        productId: row.read(saleItems.productId)!,
        productName: row.read(saleItems.productName)!,
        totalQuantity: row.read(saleItems.quantity.sum())!,
        totalSales: row.read(saleItems.total.sum())!,
      );
    }).toList();
  }
  // ==================== REPORT QUERIES ====================

  /// 일별 매출 데이터 (Line chart 용)
  Future<List<DailySalesData>> getDailySalesData(DateTime from, DateTime to) async {
    final salesList = await (select(sales)
          ..where((s) =>
              s.saleDate.isBiggerOrEqualValue(from) &
              s.saleDate.isSmallerOrEqualValue(to) &
              s.status.equals('completed'))
          ..orderBy([(s) => OrderingTerm.asc(s.saleDate)]))
        .get();

    final Map<String, DailySalesData> dailyMap = {};
    for (final sale in salesList) {
      final dateKey =
          '${sale.saleDate.year}-${sale.saleDate.month.toString().padLeft(2, '0')}-${sale.saleDate.day.toString().padLeft(2, '0')}';
      if (dailyMap.containsKey(dateKey)) {
        dailyMap[dateKey] = DailySalesData(
          date: DateTime(sale.saleDate.year, sale.saleDate.month, sale.saleDate.day),
          totalSales: dailyMap[dateKey]!.totalSales + sale.total,
          orderCount: dailyMap[dateKey]!.orderCount + 1,
        );
      } else {
        dailyMap[dateKey] = DailySalesData(
          date: DateTime(sale.saleDate.year, sale.saleDate.month, sale.saleDate.day),
          totalSales: sale.total,
          orderCount: 1,
        );
      }
    }

    // from ~ to 사이 빈 날짜 채우기
    final result = <DailySalesData>[];
    var current = DateTime(from.year, from.month, from.day);
    final endDate = DateTime(to.year, to.month, to.day);
    while (!current.isAfter(endDate)) {
      final dateKey =
          '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
      result.add(dailyMap[dateKey] ??
          DailySalesData(date: current, totalSales: 0, orderCount: 0));
      current = current.add(const Duration(days: 1));
    }

    return result;
  }

  /// 결제 방법별 매출 합계 (Pie chart 용)
  Future<Map<String, double>> getPaymentMethodTotals(DateTime from, DateTime to) async {
    final salesList = await (select(sales)
          ..where((s) =>
              s.saleDate.isBiggerOrEqualValue(from) &
              s.saleDate.isSmallerOrEqualValue(to) &
              s.status.equals('completed')))
        .get();

    final map = <String, double>{};
    for (final sale in salesList) {
      map[sale.paymentMethod] = (map[sale.paymentMethod] ?? 0) + sale.total;
    }
    return map;
  }

  /// 시간대별 매출 분포 (0~23시)
  Future<Map<int, double>> getHourlySalesDistribution(DateTime from, DateTime to) async {
    final salesList = await (select(sales)
          ..where((s) =>
              s.saleDate.isBiggerOrEqualValue(from) &
              s.saleDate.isSmallerOrEqualValue(to) &
              s.status.equals('completed')))
        .get();

    final map = <int, double>{};
    for (var h = 0; h < 24; h++) {
      map[h] = 0;
    }
    for (final sale in salesList) {
      final hour = sale.saleDate.hour;
      map[hour] = (map[hour] ?? 0) + sale.total;
    }
    return map;
  }

  /// 주문 건수 (기간별) — SQL COUNT 사용으로 최적화
  Future<int> getOrderCount(DateTime from, DateTime to) async {
    final query = selectOnly(sales)
      ..addColumns([sales.id.count()])
      ..where(
        sales.saleDate.isBiggerOrEqualValue(from) &
            sales.saleDate.isSmallerOrEqualValue(to) &
            sales.status.equals('completed'),
      );
    final result = await query.getSingle();
    return result.read(sales.id.count()) ?? 0;
  }

  /// 결제 방법별 매출 합계 — SQL GROUP BY 사용으로 최적화
  Future<List<PaymentMethodTotal>> getPaymentBreakdown(DateTime from, DateTime to) async {
    final query = selectOnly(sales)
      ..addColumns([sales.paymentMethod, sales.total.sum()])
      ..where(
        sales.saleDate.isBiggerOrEqualValue(from) &
            sales.saleDate.isSmallerOrEqualValue(to) &
            sales.status.equals('completed'),
      )
      ..groupBy([sales.paymentMethod])
      ..orderBy([OrderingTerm.desc(sales.total.sum())]);

    final results = await query.get();
    return results.map((row) {
      return PaymentMethodTotal(
        method: row.read(sales.paymentMethod)!,
        total: row.read(sales.total.sum()) ?? 0,
      );
    }).toList();
  }
}

/// 결제 방법별 합계 모델
class PaymentMethodTotal {
  final String method;
  final double total;

  PaymentMethodTotal({required this.method, required this.total});
}

/// 일별 매출 데이터 모델
class DailySalesData {
  final DateTime date;
  final double totalSales;
  final int orderCount;

  DailySalesData({
    required this.date,
    required this.totalSales,
    required this.orderCount,
  });
}

class ProductSalesStats {
  final int productId;
  final String productName;
  final int totalQuantity;
  final double totalSales;

  ProductSalesStats({
    required this.productId,
    required this.productName,
    required this.totalQuantity,
    required this.totalSales,
  });
}

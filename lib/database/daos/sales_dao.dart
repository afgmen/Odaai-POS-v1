import 'package:drift/drift.dart';

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
          final kitchenOrdersDao = db.kitchenOrdersDao;
          await kitchenOrdersDao.createOrderFromSale(
            saleId: saleId,
            tableNumber: tableNumber,
            specialInstructions: specialInstructions,
          );
        } catch (e) {
          // KDS 기능이 없는 경우 무시
          print('Kitchen order creation skipped: $e');
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

  Stream<List<Sale>> watchTodaySales() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return (select(sales)
          ..where((s) => s.saleDate.isBiggerOrEqualValue(startOfDay))
          ..orderBy([(s) => OrderingTerm.desc(s.saleDate)]))
        .watch();
  }

  // ==================== UPDATE ====================

  Future<int> updateSaleStatus(int saleId, String status) {
    return (update(sales)..where((s) => s.id.equals(saleId)))
        .write(SalesCompanion(
      status: Value(status),
      needsSync: const Value(true),
    ));
  }

  Future<void> refundSale(int saleId, int employeeId) async {
    await transaction(() async {
      await updateSaleStatus(saleId, 'refunded');

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

  // ==================== STATISTICS ====================

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

  /// 주문 건수 (기간별)
  Future<int> getOrderCount(DateTime from, DateTime to) async {
    final salesList = await (select(sales)
          ..where((s) =>
              s.saleDate.isBiggerOrEqualValue(from) &
              s.saleDate.isSmallerOrEqualValue(to) &
              s.status.equals('completed')))
        .get();
    return salesList.length;
  }
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

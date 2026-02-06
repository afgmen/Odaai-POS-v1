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
          reason: '판매',
          saleId: saleId,
        );
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
          reason: '환불',
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

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/products.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [Products, StockMovements])
class ProductsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductsDaoMixin {
  ProductsDao(super.database);

  // ==================== CREATE ====================

  Future<Product> createProduct(ProductsCompanion product) async {
    final id = await into(products).insert(product);
    return (select(products)..where((p) => p.id.equals(id))).getSingle();
  }

  Future<void> createProducts(List<ProductsCompanion> productList) async {
    await batch((batch) {
      batch.insertAll(products, productList);
    });
  }

  // ==================== READ ====================

  Future<List<Product>> getAllProducts() {
    return (select(products)
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  Future<Product?> getProductById(int id) {
    return (select(products)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  Future<Product?> getProductBySku(String sku) {
    return (select(products)..where((p) => p.sku.equals(sku)))
        .getSingleOrNull();
  }

  Future<Product?> getProductByBarcode(String barcode) {
    return (select(products)..where((p) => p.barcode.equals(barcode)))
        .getSingleOrNull();
  }

  Future<List<Product>> getProductsByCategory(String category) {
    return (select(products)
          ..where((p) => p.category.equals(category) & p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  Future<List<Product>> getLowStockProducts() {
    return (select(products)
          ..where((p) =>
              p.stock.isSmallerOrEqual(p.minStock) &
              p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.stock)]))
        .get();
  }

  Future<List<Product>> searchProducts(String query) {
    final pattern = '%$query%';
    return (select(products)
          ..where((p) =>
              (p.name.like(pattern) |
                  p.sku.like(pattern) |
                  p.barcode.like(pattern)) &
              p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  Stream<List<Product>> watchAllProducts() {
    return (select(products)
          ..where((p) => p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch();
  }

  Stream<List<Product>> watchLowStockProducts() {
    return (select(products)
          ..where((p) =>
              p.stock.isSmallerOrEqual(p.minStock) &
              p.isActive.equals(true)))
        .watch();
  }

  // ==================== UPDATE ====================

  Future<int> updateProduct(Product product) async {
    return await (update(products)..where((p) => p.id.equals(product.id)))
        .write(product.toCompanion(true));
  }

  Future<void> updateStock({
    required int productId,
    required int quantity,
    required String type,
    String? reason,
    int? employeeId,
    int? saleId,
  }) async {
    await transaction(() async {
      final product = await (select(products)
            ..where((p) => p.id.equals(productId)))
          .getSingle();

      final oldStock = product.stock;
      final newStock = oldStock + quantity;

      if (newStock < 0) {
        throw Exception('Insufficient stock. Current: $oldStock');
      }

      await (update(products)..where((p) => p.id.equals(productId)))
          .write(ProductsCompanion(
        stock: Value(newStock),
        updatedAt: Value(DateTime.now()),
        needsSync: const Value(true),
      ));

      await into(stockMovements).insert(
        StockMovementsCompanion.insert(
          productId: productId,
          productName: product.name,
          type: type,
          quantity: quantity,
          stockBefore: oldStock,
          stockAfter: newStock,
          reason: Value(reason),
          employeeId: Value(employeeId),
          saleId: Value(saleId),
        ),
      );
    });
  }

  // ==================== DELETE ====================

  Future<int> deleteProduct(int id) async {
    return await (update(products)..where((p) => p.id.equals(id)))
        .write(ProductsCompanion(
      isActive: const Value(false),
      updatedAt: Value(DateTime.now()),
      needsSync: const Value(true),
    ));
  }

  // ==================== STATISTICS ====================

  Future<Map<String, int>> getProductCountByCategory() async {
    final query = selectOnly(products)
      ..addColumns([products.category, products.id.count()])
      ..where(products.isActive.equals(true))
      ..groupBy([products.category]);

    final results = await query.get();

    return Map.fromEntries(
      results.map((row) {
        final category = row.read(products.category)!;
        final count = row.read(products.id.count())!;
        return MapEntry(category, count);
      }),
    );
  }

  Future<double> getTotalInventoryValue() async {
    final expr = products.cost * products.stock.cast<double>();
    final query = selectOnly(products)
      ..addColumns([expr.sum()]  )
      ..where(products.isActive.equals(true));

    final result = await query.getSingle();
    return result.read(expr.sum()) ?? 0;
  }

  // ==================== IMAGE MANAGEMENT ====================

  /// Update product image URL
  Future<void> updateProductImageUrl(int productId, String? imageUrl) async {
    await (update(products)..where((p) => p.id.equals(productId)))
        .write(ProductsCompanion(
      imageUrl: Value(imageUrl),
      updatedAt: Value(DateTime.now()),
      needsSync: const Value(true),
    ));
  }

  /// Get products without images
  Future<List<Product>> getProductsWithoutImage() {
    return (select(products)
          ..where((p) =>
              p.imageUrl.isNull() & p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  /// Get products with images
  Future<List<Product>> getProductsWithImage() {
    return (select(products)
          ..where((p) =>
              p.imageUrl.isNotNull() & p.isActive.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .get();
  }

  /// Get image coverage rate (%)
  Future<double> getImageCoverageRate() async {
    final totalQuery = selectOnly(products)
      ..addColumns([products.id.count()])
      ..where(products.isActive.equals(true));

    final withImageQuery = selectOnly(products)
      ..addColumns([products.id.count()])
      ..where(products.imageUrl.isNotNull() & products.isActive.equals(true));

    final totalResult = await totalQuery.getSingle();
    final withImageResult = await withImageQuery.getSingle();

    final total = totalResult.read(products.id.count()) ?? 0;
    final withImage = withImageResult.read(products.id.count()) ?? 0;

    if (total == 0) return 0;
    return (withImage / total) * 100;
  }
}

class StockUpdate {
  final int productId;
  final int quantity;
  final String type;
  final String? reason;

  StockUpdate({
    required this.productId,
    required this.quantity,
    required this.type,
    this.reason,
  });
}

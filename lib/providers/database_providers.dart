import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/daos/products_dao.dart';
import '../database/daos/sales_dao.dart';
import '../database/daos/sync_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() {
    db.close();
  });
  return db;
});

final productsDaoProvider = Provider<ProductsDao>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductsDao(db);
});

final salesDaoProvider = Provider<SalesDao>((ref) {
  final db = ref.watch(databaseProvider);
  return SalesDao(db);
});

final syncDaoProvider = Provider<SyncDao>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncDao(db);
});

final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  final dao = ref.watch(productsDaoProvider);
  return dao.watchAllProducts();
});

final todaySalesStreamProvider = StreamProvider<List<Sale>>((ref) {
  final dao = ref.watch(salesDaoProvider);
  return dao.watchTodaySales();
});

final todayTotalSalesProvider = FutureProvider<double>((ref) async {
  final dao = ref.watch(salesDaoProvider);
  return await dao.getTodayTotalSales();
});

final activeProductsProvider = StreamProvider<List<Product>>((ref) {
  final dao = ref.watch(productsDaoProvider);
  return dao.watchAllProducts();
});

/// 상품 데이터 변경 신호 — Products Management에서 CUD 발생 시 증가
/// POS filteredProductsProvider가 이를 watch하여 즉시 갱신됨
final productChangeSignalProvider = StateProvider<int>((ref) => 0);

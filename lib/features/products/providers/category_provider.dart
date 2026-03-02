import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';

/// Provider for active categories list (as Future for initial load)
final activeCategoriesListProvider = FutureProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.categoriesDao.getAllCategories();
});

/// Provider for category by id
final categoryByIdProvider = FutureProvider.family<Category?, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.categoriesDao.getCategoryById(id);
});

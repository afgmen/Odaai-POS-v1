import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';

/// Provider for active categories list (StreamProvider for real-time updates)
/// B-UAT: FutureProvider → StreamProvider로 변경하여 새 카테고리 추가 시 즉시 반영
final activeCategoriesListProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.categoriesDao.watchAllCategories();
});

/// Provider for category by id
final categoryByIdProvider = FutureProvider.family<Category?, int>((ref, id) {
  final db = ref.watch(databaseProvider);
  return db.categoriesDao.getCategoryById(id);
});

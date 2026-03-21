import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase> with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// Get all active categories sorted by sortOrder
  Future<List<Category>> getAllCategories() {
    return (select(categories)
          ..where((tbl) => tbl.isActive.equals(true))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]))
        .get();
  }

  /// Get category by id
  Future<Category?> getCategoryById(int id) {
    return (select(categories)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Create new category
  Future<int> createCategory({
    required String name,
    String? description,
    int sortOrder = 0,
    double? vatRate,
  }) {
    return into(categories).insert(
      CategoriesCompanion.insert(
        name: name,
        description: Value(description),
        sortOrder: Value(sortOrder),
        vatRate: Value(vatRate),
      ),
    );
  }

  /// Update category
  Future<bool> updateCategory({
    required int id,
    String? name,
    String? description,
    int? sortOrder,
    Object? vatRate = _absent,
  }) {
    return (update(categories)..where((tbl) => tbl.id.equals(id))).write(
      CategoriesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        description: description != null ? Value(description) : const Value.absent(),
        sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
        vatRate: vatRate == _absent
            ? const Value.absent()
            : Value(vatRate as double?),
      ),
    ).then((rows) => rows > 0);
  }

  static const _absent = Object();

  /// Soft delete category (set isActive = false)
  Future<bool> deleteCategory(int id) {
    return (update(categories)..where((tbl) => tbl.id.equals(id))).write(
      const CategoriesCompanion(isActive: Value(false)),
    ).then((rows) => rows > 0);
  }

  /// Get category by name (for migration)
  Future<Category?> getCategoryByName(String name) {
    return (select(categories)..where((tbl) => tbl.name.equals(name))).getSingleOrNull();
  }
}

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/product_modifiers.dart';

part 'modifier_dao.g.dart';

@DriftAccessor(tables: [ModifierGroups, ModifierOptions, ProductModifierLinks, SaleItemModifiers])
class ModifierDao extends DatabaseAccessor<AppDatabase> with _$ModifierDaoMixin {
  ModifierDao(super.db);

  // ==================== ModifierGroups ====================
  
  Future<List<ModifierGroup>> getAllModifierGroups() {
    return (select(modifierGroups)
          ..where((g) => g.isActive.equals(true))
          ..orderBy([(g) => OrderingTerm.asc(g.sortOrder)]))
        .get();
  }

  Future<ModifierGroup?> getModifierGroupById(int id) {
    return (select(modifierGroups)..where((g) => g.id.equals(id))).getSingleOrNull();
  }

  Future<int> createModifierGroup({
    required String name,
    bool isRequired = false,
    bool allowMultiple = false,
    int maxSelections = 1,
    int sortOrder = 0,
  }) {
    return into(modifierGroups).insert(
      ModifierGroupsCompanion.insert(
        name: name,
        isRequired: Value(isRequired),
        allowMultiple: Value(allowMultiple),
        maxSelections: Value(maxSelections),
        sortOrder: Value(sortOrder),
      ),
    );
  }

  Future<bool> updateModifierGroup({
    required int id,
    String? name,
    bool? isRequired,
    bool? allowMultiple,
    int? maxSelections,
    int? sortOrder,
  }) {
    return (update(modifierGroups)..where((g) => g.id.equals(id))).write(
      ModifierGroupsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        isRequired: isRequired != null ? Value(isRequired) : const Value.absent(),
        allowMultiple: allowMultiple != null ? Value(allowMultiple) : const Value.absent(),
        maxSelections: maxSelections != null ? Value(maxSelections) : const Value.absent(),
        sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
      ),
    ).then((rows) => rows > 0);
  }

  Future<bool> deleteModifierGroup(int id) {
    return (update(modifierGroups)..where((g) => g.id.equals(id))).write(
      const ModifierGroupsCompanion(isActive: Value(false)),
    ).then((rows) => rows > 0);
  }

  // ==================== ModifierOptions ====================

  Future<List<ModifierOption>> getModifierOptionsForGroup(int groupId) {
    return (select(modifierOptions)
          ..where((o) => o.groupId.equals(groupId) & o.isActive.equals(true))
          ..orderBy([(o) => OrderingTerm.asc(o.sortOrder)]))
        .get();
  }

  Future<ModifierOption?> getModifierOptionById(int id) {
    return (select(modifierOptions)..where((o) => o.id.equals(id))).getSingleOrNull();
  }

  Future<int> createModifierOption({
    required int groupId,
    required String name,
    double priceAdjustment = 0,
    int sortOrder = 0,
  }) {
    return into(modifierOptions).insert(
      ModifierOptionsCompanion.insert(
        groupId: groupId,
        name: name,
        priceAdjustment: Value(priceAdjustment),
        sortOrder: Value(sortOrder),
      ),
    );
  }

  Future<bool> updateModifierOption({
    required int id,
    String? name,
    double? priceAdjustment,
    int? sortOrder,
  }) {
    return (update(modifierOptions)..where((o) => o.id.equals(id))).write(
      ModifierOptionsCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        priceAdjustment: priceAdjustment != null ? Value(priceAdjustment) : const Value.absent(),
        sortOrder: sortOrder != null ? Value(sortOrder) : const Value.absent(),
      ),
    ).then((rows) => rows > 0);
  }

  Future<bool> deleteModifierOption(int id) {
    return (update(modifierOptions)..where((o) => o.id.equals(id))).write(
      const ModifierOptionsCompanion(isActive: Value(false)),
    ).then((rows) => rows > 0);
  }

  // ==================== ProductModifierLinks ====================

  Future<List<ModifierGroup>> getModifierGroupsForProduct(int productId) async {
    final links = await (select(productModifierLinks)
          ..where((l) => l.productId.equals(productId))
          ..orderBy([(l) => OrderingTerm.asc(l.sortOrder)]))
        .get();

    final groupIds = links.map((l) => l.modifierGroupId).toList();
    if (groupIds.isEmpty) return [];

    return (select(modifierGroups)
          ..where((g) => g.id.isIn(groupIds) & g.isActive.equals(true))
          ..orderBy([(g) => OrderingTerm.asc(g.sortOrder)]))
        .get();
  }

  Future<void> linkProductToModifierGroup(int productId, int groupId, {int sortOrder = 0}) {
    return into(productModifierLinks).insert(
      ProductModifierLinksCompanion.insert(
        productId: productId,
        modifierGroupId: groupId,
        sortOrder: Value(sortOrder),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> unlinkProductFromModifierGroup(int productId, int groupId) {
    return (delete(productModifierLinks)
          ..where((l) => l.productId.equals(productId) & l.modifierGroupId.equals(groupId)))
        .go();
  }

  Future<List<ProductModifierLink>> getProductModifierLinks(int productId) {
    return (select(productModifierLinks)
          ..where((l) => l.productId.equals(productId))
          ..orderBy([(l) => OrderingTerm.asc(l.sortOrder)]))
        .get();
  }

  // ==================== SaleItemModifiers ====================

  Future<void> saveSaleItemModifiers(int saleItemId, List<SaleItemModifiersCompanion> modifiers) {
    return batch((batch) {
      batch.insertAll(saleItemModifiers, modifiers);
    });
  }

  Future<List<SaleItemModifier>> getSaleItemModifiers(int saleItemId) {
    return (select(saleItemModifiers)..where((m) => m.saleItemId.equals(saleItemId))).get();
  }
}

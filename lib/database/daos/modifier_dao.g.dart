// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modifier_dao.dart';

// ignore_for_file: type=lint
mixin _$ModifierDaoMixin on DatabaseAccessor<AppDatabase> {
  $ModifierGroupsTable get modifierGroups => attachedDatabase.modifierGroups;
  $ModifierOptionsTable get modifierOptions => attachedDatabase.modifierOptions;
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $ProductModifierLinksTable get productModifierLinks =>
      attachedDatabase.productModifierLinks;
  $SalesTable get sales => attachedDatabase.sales;
  $SaleItemsTable get saleItems => attachedDatabase.saleItems;
  $SaleItemModifiersTable get saleItemModifiers =>
      attachedDatabase.saleItemModifiers;
  ModifierDaoManager get managers => ModifierDaoManager(this);
}

class ModifierDaoManager {
  final _$ModifierDaoMixin _db;
  ModifierDaoManager(this._db);
  $$ModifierGroupsTableTableManager get modifierGroups =>
      $$ModifierGroupsTableTableManager(
        _db.attachedDatabase,
        _db.modifierGroups,
      );
  $$ModifierOptionsTableTableManager get modifierOptions =>
      $$ModifierOptionsTableTableManager(
        _db.attachedDatabase,
        _db.modifierOptions,
      );
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$ProductModifierLinksTableTableManager get productModifierLinks =>
      $$ProductModifierLinksTableTableManager(
        _db.attachedDatabase,
        _db.productModifierLinks,
      );
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db.attachedDatabase, _db.sales);
  $$SaleItemsTableTableManager get saleItems =>
      $$SaleItemsTableTableManager(_db.attachedDatabase, _db.saleItems);
  $$SaleItemModifiersTableTableManager get saleItemModifiers =>
      $$SaleItemModifiersTableTableManager(
        _db.attachedDatabase,
        _db.saleItemModifiers,
      );
}

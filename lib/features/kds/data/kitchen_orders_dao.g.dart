// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kitchen_orders_dao.dart';

// ignore_for_file: type=lint
mixin _$KitchenOrdersDaoMixin on DatabaseAccessor<AppDatabase> {
  $SalesTable get sales => attachedDatabase.sales;
  $KitchenOrdersTable get kitchenOrders => attachedDatabase.kitchenOrders;
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $SaleItemsTable get saleItems => attachedDatabase.saleItems;
  $RestaurantTablesTable get restaurantTables =>
      attachedDatabase.restaurantTables;
  KitchenOrdersDaoManager get managers => KitchenOrdersDaoManager(this);
}

class KitchenOrdersDaoManager {
  final _$KitchenOrdersDaoMixin _db;
  KitchenOrdersDaoManager(this._db);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db.attachedDatabase, _db.sales);
  $$KitchenOrdersTableTableManager get kitchenOrders =>
      $$KitchenOrdersTableTableManager(_db.attachedDatabase, _db.kitchenOrders);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$SaleItemsTableTableManager get saleItems =>
      $$SaleItemsTableTableManager(_db.attachedDatabase, _db.saleItems);
  $$RestaurantTablesTableTableManager get restaurantTables =>
      $$RestaurantTablesTableTableManager(
        _db.attachedDatabase,
        _db.restaurantTables,
      );
}

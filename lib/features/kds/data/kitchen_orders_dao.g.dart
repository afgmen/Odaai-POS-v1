// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kitchen_orders_dao.dart';

// ignore_for_file: type=lint
mixin _$KitchenOrdersDaoMixin on DatabaseAccessor<AppDatabase> {
  $SalesTable get sales => attachedDatabase.sales;
  $KitchenOrdersTable get kitchenOrders => attachedDatabase.kitchenOrders;
  $ProductsTable get products => attachedDatabase.products;
  $SaleItemsTable get saleItems => attachedDatabase.saleItems;
  KitchenOrdersDaoManager get managers => KitchenOrdersDaoManager(this);
}

class KitchenOrdersDaoManager {
  final _$KitchenOrdersDaoMixin _db;
  KitchenOrdersDaoManager(this._db);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db.attachedDatabase, _db.sales);
  $$KitchenOrdersTableTableManager get kitchenOrders =>
      $$KitchenOrdersTableTableManager(_db.attachedDatabase, _db.kitchenOrders);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$SaleItemsTableTableManager get saleItems =>
      $$SaleItemsTableTableManager(_db.attachedDatabase, _db.saleItems);
}

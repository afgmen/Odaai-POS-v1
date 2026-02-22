// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_orders_dao.dart';

// ignore_for_file: type=lint
mixin _$DeliveryOrdersDaoMixin on DatabaseAccessor<AppDatabase> {
  $SalesTable get sales => attachedDatabase.sales;
  $KitchenOrdersTable get kitchenOrders => attachedDatabase.kitchenOrders;
  $DeliveryOrdersTable get deliveryOrders => attachedDatabase.deliveryOrders;
  DeliveryOrdersDaoManager get managers => DeliveryOrdersDaoManager(this);
}

class DeliveryOrdersDaoManager {
  final _$DeliveryOrdersDaoMixin _db;
  DeliveryOrdersDaoManager(this._db);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db.attachedDatabase, _db.sales);
  $$KitchenOrdersTableTableManager get kitchenOrders =>
      $$KitchenOrdersTableTableManager(_db.attachedDatabase, _db.kitchenOrders);
  $$DeliveryOrdersTableTableManager get deliveryOrders =>
      $$DeliveryOrdersTableTableManager(
        _db.attachedDatabase,
        _db.deliveryOrders,
      );
}

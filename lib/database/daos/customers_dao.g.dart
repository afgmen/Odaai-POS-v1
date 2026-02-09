// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customers_dao.dart';

// ignore_for_file: type=lint
mixin _$CustomersDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomersTable get customers => attachedDatabase.customers;
  $SalesTable get sales => attachedDatabase.sales;
  $ProductsTable get products => attachedDatabase.products;
  $SaleItemsTable get saleItems => attachedDatabase.saleItems;
  $CashDrawerLogsTable get cashDrawerLogs => attachedDatabase.cashDrawerLogs;
  $RefundsTable get refunds => attachedDatabase.refunds;
  $RefundItemsTable get refundItems => attachedDatabase.refundItems;
  CustomersDaoManager get managers => CustomersDaoManager(this);
}

class CustomersDaoManager {
  final _$CustomersDaoMixin _db;
  CustomersDaoManager(this._db);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db.attachedDatabase, _db.sales);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$SaleItemsTableTableManager get saleItems =>
      $$SaleItemsTableTableManager(_db.attachedDatabase, _db.saleItems);
  $$CashDrawerLogsTableTableManager get cashDrawerLogs =>
      $$CashDrawerLogsTableTableManager(
        _db.attachedDatabase,
        _db.cashDrawerLogs,
      );
  $$RefundsTableTableManager get refunds =>
      $$RefundsTableTableManager(_db.attachedDatabase, _db.refunds);
  $$RefundItemsTableTableManager get refundItems =>
      $$RefundItemsTableTableManager(_db.attachedDatabase, _db.refundItems);
}

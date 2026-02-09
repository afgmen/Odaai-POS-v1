// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_dao.dart';

// ignore_for_file: type=lint
mixin _$LoyaltyDaoMixin on DatabaseAccessor<AppDatabase> {
  $SalesTable get sales => attachedDatabase.sales;
  $EmployeesTable get employees => attachedDatabase.employees;
  $PointTransactionsTable get pointTransactions =>
      attachedDatabase.pointTransactions;
  $MembershipTiersTable get membershipTiers => attachedDatabase.membershipTiers;
  $LoyaltySettingsTable get loyaltySettings => attachedDatabase.loyaltySettings;
  $CustomersTable get customers => attachedDatabase.customers;
  LoyaltyDaoManager get managers => LoyaltyDaoManager(this);
}

class LoyaltyDaoManager {
  final _$LoyaltyDaoMixin _db;
  LoyaltyDaoManager(this._db);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db.attachedDatabase, _db.sales);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$PointTransactionsTableTableManager get pointTransactions =>
      $$PointTransactionsTableTableManager(
        _db.attachedDatabase,
        _db.pointTransactions,
      );
  $$MembershipTiersTableTableManager get membershipTiers =>
      $$MembershipTiersTableTableManager(
        _db.attachedDatabase,
        _db.membershipTiers,
      );
  $$LoyaltySettingsTableTableManager get loyaltySettings =>
      $$LoyaltySettingsTableTableManager(
        _db.attachedDatabase,
        _db.loyaltySettings,
      );
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
}

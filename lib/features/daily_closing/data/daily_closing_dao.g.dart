// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_closing_dao.dart';

// ignore_for_file: type=lint
mixin _$DailyClosingDaoMixin on DatabaseAccessor<AppDatabase> {
  $EmployeesTable get employees => attachedDatabase.employees;
  $DailyClosingsTable get dailyClosings => attachedDatabase.dailyClosings;
  $SalesTable get sales => attachedDatabase.sales;
  DailyClosingDaoManager get managers => DailyClosingDaoManager(this);
}

class DailyClosingDaoManager {
  final _$DailyClosingDaoMixin _db;
  DailyClosingDaoManager(this._db);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$DailyClosingsTableTableManager get dailyClosings =>
      $$DailyClosingsTableTableManager(_db.attachedDatabase, _db.dailyClosings);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db.attachedDatabase, _db.sales);
}

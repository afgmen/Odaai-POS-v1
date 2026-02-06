import 'package:drift/drift.dart';

class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get name => text()();
  TextColumn get passwordHash => text()();
  TextColumn get role => text().withDefault(const Constant('cashier'))(); // 'admin' | 'cashier' | 'manager'
  TextColumn get pin => text().nullable()(); // 4자리 PIN (해시)
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

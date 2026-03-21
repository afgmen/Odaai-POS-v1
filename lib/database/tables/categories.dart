import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get description => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  RealColumn get vatRate => real().nullable()(); // null = use store-wide default
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

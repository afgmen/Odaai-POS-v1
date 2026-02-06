import 'package:drift/drift.dart';

import 'products.dart';

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get saleNumber => text().unique()();
  DateTimeColumn get saleDate => dateTime().withDefault(currentDateAndTime)();
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get tax => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get total => real().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text()(); // 'cash' | 'card' | 'qr'
  IntColumn get employeeId => integer().nullable()();
  IntColumn get customerId => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('completed'))();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()();
  TextColumn get sku => text()();
  RealColumn get unitPrice => real()();
  IntColumn get quantity => integer()();
  RealColumn get total => real()();
}

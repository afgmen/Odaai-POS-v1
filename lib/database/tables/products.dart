import 'package:drift/drift.dart';
import 'categories.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sku => text().unique()();
  TextColumn get name => text()();
  TextColumn get barcode => text().nullable()();
  RealColumn get price => real().withDefault(const Constant(0))();
  RealColumn get cost => real().withDefault(const Constant(0))();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  IntColumn get minStock => integer().withDefault(const Constant(0))();
  TextColumn get category => text().nullable()();
  IntColumn get categoryId => integer().nullable().references(Categories, #id)();
  TextColumn get imageUrl => text().nullable()();
  // B-118: 제품별 VAT 세율 (0, 5, 8, 10) — 베트남 정부 규정
  RealColumn get vatRate => real().withDefault(const Constant(10.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class StockMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()();
  TextColumn get type => text()(); // 'in' | 'out'
  IntColumn get quantity => integer()();
  IntColumn get stockBefore => integer()();
  IntColumn get stockAfter => integer()();
  TextColumn get reason => text().nullable()();
  IntColumn get employeeId => integer().nullable()();
  IntColumn get saleId => integer().nullable()();
  // B-115: 입고 출처 — Oda 공급업체 API 연동 대비 확장 가능 설계
  TextColumn get supplierName => text().nullable()(); // 텍스트 fallback (현재 사용)
  IntColumn get supplierId => integer().nullable()(); // nullable FK (향후 Oda 연동)
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

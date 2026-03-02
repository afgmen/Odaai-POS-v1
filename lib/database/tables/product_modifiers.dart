import 'package:drift/drift.dart';
import 'products.dart';
import 'sales.dart';

/// Modifier Groups (e.g., "Size", "Toppings", "Sugar Level")
class ModifierGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  BoolColumn get isRequired => boolean().withDefault(const Constant(false))();
  BoolColumn get allowMultiple => boolean().withDefault(const Constant(false))();
  IntColumn get maxSelections => integer().withDefault(const Constant(1))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Modifier Options (e.g., "Large +10,000đ", "Less ice")
class ModifierOptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer().references(ModifierGroups, #id)();
  TextColumn get name => text()();
  RealColumn get priceAdjustment => real().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Product ↔ ModifierGroup Links
class ProductModifierLinks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get modifierGroupId => integer().references(ModifierGroups, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  
  @override
  List<Set<Column>> get uniqueKeys => [
    {productId, modifierGroupId}, // Prevent duplicate links
  ];
}

/// Sale Item Modifiers (snapshot of selected modifiers for each sale item)
class SaleItemModifiers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleItemId => integer().references(SaleItems, #id)();
  IntColumn get modifierOptionId => integer().nullable()(); // nullable for deleted options
  TextColumn get modifierName => text()(); // Snapshot
  TextColumn get optionName => text()(); // Snapshot
  RealColumn get priceAdjustment => real()(); // Snapshot
}

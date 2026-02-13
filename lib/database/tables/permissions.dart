import 'package:drift/drift.dart';

/// Master permission list table
/// Stores all available permissions in the system
class Permissions extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text().named('id')();

  /// Permission name in module.action format (e.g., "revenue.daily.view")
  TextColumn get name => text().unique()();

  /// Module name (e.g., "revenue", "inventory", "pos")
  TextColumn get module => text()();

  /// Human-readable description
  TextColumn get description => text()();

  /// Whether this permission involves sensitive data
  BoolColumn get isSensitive => boolean().withDefault(const Constant(false))();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

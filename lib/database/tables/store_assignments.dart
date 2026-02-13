import 'package:drift/drift.dart';

/// Store assignment table for Area Managers
/// Tracks which stores an AREA_MANAGER can access
class StoreAssignments extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text().named('id')();

  /// Foreign key to employees.id
  IntColumn get userId => integer()();

  /// Foreign key to stores.id
  TextColumn get storeId => text()();

  /// When this assignment was created
  DateTimeColumn get assignedAt => dateTime().withDefault(currentDateAndTime)();

  /// Foreign key to employees.id (who created this assignment)
  IntColumn get assignedBy => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

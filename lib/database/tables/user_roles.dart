import 'package:drift/drift.dart';

/// User-to-role assignment table
/// Maps each user to their role and store scope
class UserRoles extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text().named('id')();

  /// Foreign key to employees.id
  IntColumn get userId => integer()();

  /// Role name (OWNER, AREA_MANAGER, STORE_MANAGER, STAFF)
  TextColumn get role => text()();

  /// Store access scope (ALL_STORES, ASSIGNED_STORES, OWN_STORE)
  TextColumn get scope => text()();

  /// When this role was assigned
  DateTimeColumn get assignedAt => dateTime().withDefault(currentDateAndTime)();

  /// Foreign key to employees.id (who assigned this role)
  IntColumn get assignedBy => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

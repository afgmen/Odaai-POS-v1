import 'package:drift/drift.dart';

/// Role-to-permission mapping table
/// Stores which permissions are enabled for each role
class RolePermissions extends Table {
  /// Unique identifier (UUID)
  TextColumn get id => text().named('id')();

  /// Role name (OWNER, AREA_MANAGER, STORE_MANAGER, STAFF)
  TextColumn get role => text()();

  /// Foreign key to permissions.id
  TextColumn get permissionId => text()();

  /// Whether this permission is enabled for this role
  BoolColumn get isEnabled => boolean().withDefault(const Constant(false))();

  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Foreign key to employees.id (who updated)
  IntColumn get updatedBy => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

import 'package:drift/drift.dart';
import '../app_database.dart';

part 'permissions_dao.g.dart';

@DriftAccessor(tables: [Permissions])
class PermissionsDao extends DatabaseAccessor<AppDatabase> with _$PermissionsDaoMixin {
  PermissionsDao(AppDatabase db) : super(db);

  /// Get permission by name
  Future<Permission?> getPermissionByName(String name) {
    return (select(permissions)..where((p) => p.name.equals(name))).getSingleOrNull();
  }

  /// Get all permissions
  Future<List<Permission>> getAllPermissions() {
    return select(permissions).get();
  }

  /// Get permissions by module
  Future<List<Permission>> getPermissionsByModule(String module) {
    return (select(permissions)..where((p) => p.module.equals(module))).get();
  }

  /// Get sensitive permissions only
  Future<List<Permission>> getSensitivePermissions() {
    return (select(permissions)..where((p) => p.isSensitive.equals(true))).get();
  }

  /// Insert new permission
  Future<void> insertPermission(PermissionsCompanion permission) {
    return into(permissions).insert(permission);
  }

  /// Batch insert permissions
  Future<void> insertPermissions(List<PermissionsCompanion> permissionsList) {
    return batch((batch) {
      batch.insertAll(permissions, permissionsList);
    });
  }
}

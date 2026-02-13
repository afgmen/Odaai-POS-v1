import 'package:drift/drift.dart';
import '../app_database.dart';

part 'role_permissions_dao.g.dart';

@DriftAccessor(tables: [RolePermissions, Permissions])
class RolePermissionsDao extends DatabaseAccessor<AppDatabase> with _$RolePermissionsDaoMixin {
  RolePermissionsDao(AppDatabase db) : super(db);

  /// Get all permissions for a specific role
  Future<List<RolePermission>> getRolePermissions(String role) {
    return (select(rolePermissions)..where((rp) => rp.role.equals(role))).get();
  }

  /// Get enabled permissions for a specific role
  Future<List<RolePermission>> getEnabledRolePermissions(String role) {
    return (select(rolePermissions)
      ..where((rp) => rp.role.equals(role) & rp.isEnabled.equals(true)))
      .get();
  }

  /// Get specific role permission
  Future<RolePermission?> getRolePermission(String role, String permissionId) {
    return (select(rolePermissions)
      ..where((rp) => rp.role.equals(role) & rp.permissionId.equals(permissionId)))
      .getSingleOrNull();
  }

  /// Update role permission
  Future<void> updateRolePermission(RolePermission permission) {
    return update(rolePermissions).replace(permission);
  }

  /// Insert role permission
  Future<void> insertRolePermission(RolePermissionsCompanion permission) {
    return into(rolePermissions).insert(permission);
  }

  /// Batch insert role permissions
  Future<void> insertRolePermissions(List<RolePermissionsCompanion> permissionsList) {
    return batch((batch) {
      batch.insertAll(rolePermissions, permissionsList);
    });
  }

  /// Check if role has specific permission enabled
  Future<bool> hasPermission(String role, String permissionName) async {
    final permission = await db.permissionsDao.getPermissionByName(permissionName);
    if (permission == null) return false;

    final rolePermission = await getRolePermission(role, permission.id);
    return rolePermission?.isEnabled ?? false;
  }
}

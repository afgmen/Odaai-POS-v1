import 'package:uuid/uuid.dart';
import '../../../../database/app_database.dart';
import '../permission_error.dart';
import 'permission_service.dart';
import 'audit_log_service.dart';

/// Service for Owner to manage role permissions
/// Allows customization of which permissions each role has
class RolePermissionService {
  final AppDatabase _db;
  final AuditLogService _auditLog;
  final PermissionService _permissionService;

  RolePermissionService(this._db, this._auditLog, this._permissionService);

  /// Update a role's permission (Owner only)
  ///
  /// [actorId] - User ID performing the action (must be OWNER)
  /// [role] - Role to update (AREA_MANAGER, STORE_MANAGER, STAFF)
  /// [permissionName] - Permission to enable/disable (e.g., 'revenue.daily.view')
  /// [enabled] - Whether to enable or disable the permission
  Future<void> updatePermission({
    required int actorId,
    required String role,
    required String permissionName,
    required bool enabled,
  }) async {
    // Validate: actor is OWNER
    final actorRole = await _db.userRolesDao.getUserRole(actorId);
    if (actorRole?.role != 'OWNER') {
      throw PermissionError.notOwner();
    }

    // Validate: cannot modify OWNER role
    if (role == 'OWNER') {
      throw PermissionError.ownerModificationForbidden();
    }

    // Get permission from database
    final permission = await _db.permissionsDao.getPermissionByName(permissionName);
    if (permission == null) {
      throw PermissionError(
        code: 'PERMISSION_NOT_FOUND',
        message: 'Permission not found: $permissionName',
      );
    }

    // Get current value (if exists)
    final existing = await _db.rolePermissionsDao.getRolePermission(role, permission.id);
    final oldValue = existing?.isEnabled ?? false;

    // Update or insert
    if (existing != null) {
      // Update existing permission
      final updated = existing.copyWith(
        isEnabled: enabled,
        updatedAt: DateTime.now(),
        updatedBy: actorId,
      );
      await _db.rolePermissionsDao.updateRolePermission(updated);
    } else {
      // Insert new permission mapping
      await _db.rolePermissionsDao.insertRolePermission(
        RolePermissionsCompanion.insert(
          id: const Uuid().v4(),
          role: role,
          permissionId: permission.id,
          isEnabled: enabled,
          updatedBy: actorId,
        ),
      );
    }

    // Clear permission cache for this role
    _permissionService.clearRoleCache(role);

    // Create audit log
    final actor = await _db.employeesDao.getEmployeeById(actorId);
    await _auditLog.logPermissionChange(
      eventType: 'ROLE_PERMISSION_UPDATED',
      actorId: actorId,
      actorName: '${actor?.name ?? 'Unknown'} (${actorRole!.role})',
      targetRole: role,
      permission: permissionName,
      oldValue: oldValue.toString(),
      newValue: enabled.toString(),
    );
  }

  /// Get all permissions for a role with their enabled status
  ///
  /// Returns a map of permission name → enabled status
  Future<Map<String, bool>> getRolePermissions(String role) async {
    // Get all available permissions
    final allPermissions = await _db.permissionsDao.getAllPermissions();

    // Get role's current permission settings
    final rolePermissions = await _db.rolePermissionsDao.getRolePermissions(role);

    // Create map with all permissions and their status
    final result = <String, bool>{};
    for (final permission in allPermissions) {
      final rolePermission = rolePermissions
          .where((rp) => rp.permissionId == permission.id)
          .firstOrNull;

      result[permission.name] = rolePermission?.isEnabled ?? false;
    }

    return result;
  }

  /// Get permissions grouped by module for a role
  ///
  /// Returns a map of module name → {permission name → enabled status}
  Future<Map<String, Map<String, bool>>> getRolePermissionsByModule(String role) async {
    final permissions = await getRolePermissions(role);

    final grouped = <String, Map<String, bool>>{};
    for (final entry in permissions.entries) {
      final module = _getModule(entry.key);
      grouped[module] = grouped[module] ?? {};
      grouped[module]![entry.key] = entry.value;
    }

    return grouped;
  }

  /// Batch update multiple permissions for a role
  ///
  /// [actorId] - User ID performing the action (must be OWNER)
  /// [role] - Role to update
  /// [permissions] - Map of permission name → enabled status
  Future<void> batchUpdatePermissions({
    required int actorId,
    required String role,
    required Map<String, bool> permissions,
  }) async {
    // Validate: actor is OWNER
    final actorRole = await _db.userRolesDao.getUserRole(actorId);
    if (actorRole?.role != 'OWNER') {
      throw PermissionError.notOwner();
    }

    // Validate: cannot modify OWNER role
    if (role == 'OWNER') {
      throw PermissionError.ownerModificationForbidden();
    }

    // Update each permission
    for (final entry in permissions.entries) {
      await updatePermission(
        actorId: actorId,
        role: role,
        permissionName: entry.key,
        enabled: entry.value,
      );
    }
  }

  /// Reset role permissions to default template
  ///
  /// [actorId] - User ID performing the action (must be OWNER)
  /// [role] - Role to reset
  Future<void> resetToDefault({
    required int actorId,
    required String role,
  }) async {
    // Validate: actor is OWNER
    final actorRole = await _db.userRolesDao.getUserRole(actorId);
    if (actorRole?.role != 'OWNER') {
      throw PermissionError.notOwner();
    }

    // Validate: cannot modify OWNER role
    if (role == 'OWNER') {
      throw PermissionError.ownerModificationForbidden();
    }

    // Get default permissions for role
    final defaults = _getDefaultPermissions(role);

    // Batch update to defaults
    await batchUpdatePermissions(
      actorId: actorId,
      role: role,
      permissions: defaults,
    );

    // Log reset action
    final actor = await _db.employeesDao.getEmployeeById(actorId);
    await _auditLog.logPermissionChange(
      eventType: 'ROLE_PERMISSIONS_RESET',
      actorId: actorId,
      actorName: '${actor?.name ?? 'Unknown'} (${actorRole!.role})',
      targetRole: role,
      oldValue: 'custom',
      newValue: 'default_template',
    );
  }

  /// Get module name from permission
  String _getModule(String permission) {
    final parts = permission.split('.');
    return parts.isNotEmpty ? parts[0] : 'unknown';
  }

  /// Get default permissions for a role
  /// This matches the default templates from the Design document
  Map<String, bool> _getDefaultPermissions(String role) {
    switch (role) {
      case 'AREA_MANAGER':
        return {
          // Revenue - enabled
          'revenue.dashboard.view': true,
          'revenue.daily.view': true,
          'revenue.weekly.view': true,
          'revenue.monthly.view': true,
          'revenue.multistore.view': true,
          // Inventory - enabled
          'inventory.view': true,
          'inventory.edit': true,
          // Staff - enabled
          'staff.view': true,
          'staff.manage': true,
          // POS - partial
          'pos.refund': true,
          'pos.discount': true,
          // Settings - disabled
          'settings.store.edit': false,
          'settings.tax.edit': false,
          'settings.payment.edit': false,
          'settings.integration.edit': false,
        };

      case 'STORE_MANAGER':
        return {
          // POS - enabled
          'pos.open': true,
          'pos.refund': true,
          'pos.discount': true,
          // Orders - enabled
          'order.create': true,
          'order.cancel': true,
          // Inventory - enabled
          'inventory.view': true,
          'inventory.edit': true,
          // Revenue - partial (daily only)
          'revenue.dashboard.view': true,
          'revenue.daily.view': true,
          'revenue.weekly.view': false,
          'revenue.monthly.view': false,
          // Settings - disabled
          'settings.store.edit': false,
          'settings.tax.edit': false,
          'settings.payment.edit': false,
          'settings.integration.edit': false,
        };

      case 'STAFF':
        return {
          // POS - basic only
          'pos.open': true,
          // Orders - basic only
          'order.create': true,
          // All revenue - disabled
          'revenue.dashboard.view': false,
          'revenue.daily.view': false,
          'revenue.weekly.view': false,
          'revenue.monthly.view': false,
          // All settings - disabled
          'settings.store.edit': false,
          'settings.tax.edit': false,
          'settings.payment.edit': false,
          'settings.integration.edit': false,
          // Inventory edit - disabled
          'inventory.edit': false,
          // Staff manage - disabled
          'staff.manage': false,
        };

      default:
        return {};
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/services/permission_service.dart';
import '../domain/services/role_permission_service.dart';
import '../domain/services/audit_log_service.dart';
import '../../../database/app_database.dart';
import 'auth_provider.dart';

/// Database Provider (assuming it exists in your project)
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// PermissionService Provider
final permissionServiceProvider = Provider<PermissionService>((ref) {
  final database = ref.watch(databaseProvider);
  return PermissionService(database);
});

/// RolePermissionService Provider
final rolePermissionServiceProvider = Provider<RolePermissionService>((ref) {
  final database = ref.watch(databaseProvider);
  final auditLog = ref.watch(auditLogServiceProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  return RolePermissionService(database, auditLog, permissionService);
});

/// AuditLogService Provider
final auditLogServiceProvider = Provider<AuditLogService>((ref) {
  final database = ref.watch(databaseProvider);
  return AuditLogService(database);
});

/// RBAC Setting Provider (reactive - watches database changes)
/// Returns true if RBAC is enabled, false if disabled
final rbacSettingProvider = FutureProvider<bool>((ref) async {
  final permissionService = ref.watch(permissionServiceProvider);
  return await permissionService.isRBACEnabled();
});

/// RBAC Setting Notifier for toggling RBAC on/off
final rbacSettingNotifierProvider = StateNotifierProvider<RbacSettingNotifier, AsyncValue<bool>>((ref) {
  final database = ref.watch(databaseProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  return RbacSettingNotifier(database, permissionService);
});

/// Notifier for managing RBAC toggle setting
class RbacSettingNotifier extends StateNotifier<AsyncValue<bool>> {
  final AppDatabase _db;
  final PermissionService _permissionService;

  RbacSettingNotifier(this._db, this._permissionService) : super(const AsyncValue.loading()) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    state = const AsyncValue.loading();
    try {
      final enabled = await _permissionService.isRBACEnabled();
      state = AsyncValue.data(enabled);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Toggle RBAC setting (Owner only)
  Future<void> toggle(bool enabled) async {
    state = const AsyncValue.loading();
    try {
      await _db.customStatement(
        "UPDATE system_settings SET value = ?, updated_at = CURRENT_TIMESTAMP WHERE key = 'rbac_enabled'",
        [enabled ? 'true' : 'false'],
      );

      // Clear permission cache when toggling
      _permissionService.clearCache();

      state = AsyncValue.data(enabled);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Permission Check Provider
/// Usage: ref.watch(hasPermissionProvider((permission: 'revenue.daily.view', storeId: '123')))
final hasPermissionProvider = FutureProvider.family<bool, ({String permission, String? storeId})>((ref, params) async {
  final permissionService = ref.watch(permissionServiceProvider);
  final currentSession = ref.watch(currentSessionProvider);

  if (currentSession == null) return false;

  return await permissionService.hasPermission(
    currentSession.employeeId,
    params.permission,
    storeId: params.storeId,
  );
});

/// User Permissions Provider
/// Returns all permissions for current user
final userPermissionsProvider = FutureProvider<Set<String>>((ref) async {
  final permissionService = ref.watch(permissionServiceProvider);
  final currentSession = ref.watch(currentSessionProvider);

  if (currentSession == null) return {};

  return await permissionService.getUserPermissions(currentSession.employeeId);
});

/// User Role Provider
/// Returns current user's role enum
final userRoleProvider = FutureProvider((ref) async {
  final permissionService = ref.watch(permissionServiceProvider);
  final currentSession = ref.watch(currentSessionProvider);

  if (currentSession == null) return null;

  return await permissionService.getUserRoleEnum(currentSession.employeeId);
});

/// Is Owner Provider
/// Returns true if current user is OWNER
final isOwnerProvider = FutureProvider<bool>((ref) async {
  final permissionService = ref.watch(permissionServiceProvider);
  final currentSession = ref.watch(currentSessionProvider);

  if (currentSession == null) return false;

  return await permissionService.isOwner(currentSession.employeeId);
});

/// Can Manage Users Provider
/// Returns true if current user can manage other users
final canManageUsersProvider = FutureProvider<bool>((ref) async {
  final permissionService = ref.watch(permissionServiceProvider);
  final currentSession = ref.watch(currentSessionProvider);

  if (currentSession == null) return false;

  return await permissionService.canManageUsers(currentSession.employeeId);
});

/// Can View Revenue Provider
/// Returns true if current user can view revenue data
final canViewRevenueProvider = FutureProvider.family<bool, String?>((ref, storeId) async {
  final permissionService = ref.watch(permissionServiceProvider);
  final currentSession = ref.watch(currentSessionProvider);

  if (currentSession == null) return false;

  return await permissionService.canViewRevenue(currentSession.employeeId, storeId: storeId);
});

/// User Store Access List Provider
/// Returns list of store IDs the user can access
final userStoreAccessProvider = FutureProvider<List<String>>((ref) async {
  final permissionService = ref.watch(permissionServiceProvider);
  final currentSession = ref.watch(currentSessionProvider);

  if (currentSession == null) return [];

  return await permissionService.getUserStoreIds(currentSession.employeeId);
});

/// Can Access Store Provider
/// Checks if user can access specific store
final canAccessStoreProvider = FutureProvider.family<bool, String>((ref, storeId) async {
  final permissionService = ref.watch(permissionServiceProvider);
  final currentSession = ref.watch(currentSessionProvider);

  if (currentSession == null) return false;

  return await permissionService.canAccessStore(currentSession.employeeId, storeId);
});

/// Role Permissions Provider
/// Returns all permissions for a specific role
final rolePermissionsProvider = FutureProvider.family<Map<String, bool>, String>((ref, role) async {
  final rolePermissionService = ref.watch(rolePermissionServiceProvider);
  return await rolePermissionService.getRolePermissions(role);
});

/// Role Permissions by Module Provider
/// Returns permissions grouped by module for a role
final rolePermissionsByModuleProvider = FutureProvider.family<Map<String, Map<String, bool>>, String>((ref, role) async {
  final rolePermissionService = ref.watch(rolePermissionServiceProvider);
  return await rolePermissionService.getRolePermissionsByModule(role);
});

/// Audit Logs Provider
/// Returns recent audit logs
final auditLogsProvider = FutureProvider.family<List<AuditLog>, int>((ref, limit) async {
  final auditLogService = ref.watch(auditLogServiceProvider);
  return await auditLogService.getRecentLogs(limit: limit);
});

/// Audit Logs by Role Provider
/// Returns audit logs for a specific role
final auditLogsByRoleProvider = FutureProvider.family<List<AuditLog>, String>((ref, role) async {
  final auditLogService = ref.watch(auditLogServiceProvider);
  return await auditLogService.getLogsForRole(role);
});

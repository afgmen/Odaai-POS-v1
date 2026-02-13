import '../../../../database/app_database.dart';
import '../employee_role.dart';
import '../permission_error.dart';

/// Core permission validation service
/// Handles permission checks with RBAC toggle and store scope validation
class PermissionService {
  final AppDatabase _db;

  // In-memory cache for performance (invalidated on permission updates)
  final Map<String, Map<String, bool>> _permissionCache = {};

  PermissionService(this._db);

  /// Check if RBAC system is enabled
  /// When disabled, all users have full access (backward compatible)
  Future<bool> isRBACEnabled() async {
    try {
      // Note: This assumes a system_settings table exists
      // If not, RBAC is considered disabled by default
      final result = await _db.customSelect(
        "SELECT value FROM system_settings WHERE key = 'rbac_enabled'",
      ).getSingleOrNull();

      return result?.data['value'] == 'true';
    } catch (_) {
      // If query fails (table doesn't exist, etc.), RBAC is disabled
      return false;
    }
  }

  /// Main permission check: validates permission + scope
  ///
  /// [userId] - Employee ID to check
  /// [permission] - Permission name (e.g., 'revenue.daily.view')
  /// [storeId] - Optional store ID for scope validation
  ///
  /// Returns true if user has permission, false otherwise
  Future<bool> hasPermission(
    int userId,
    String permission, {
    String? storeId,
  }) async {
    // If RBAC disabled, grant all access (backward compatible)
    final rbacEnabled = await isRBACEnabled();
    if (!rbacEnabled) return true;

    // Get user's role
    final userRole = await _getUserRole(userId);
    if (userRole == null) return false;

    // Owner always has all permissions
    if (userRole.role == 'OWNER') return true;

    // Check if role has this permission enabled
    final hasPermission = await _checkRolePermission(userRole.role, permission);
    if (!hasPermission) return false;

    // If no storeId provided, permission is sufficient
    if (storeId == null) return true;

    // Validate store scope
    return await _validateStoreScope(userId, userRole.scope, storeId);
  }

  /// Get user's role from user_roles table
  Future<UserRole?> _getUserRole(int userId) async {
    return await _db.userRolesDao.getUserRole(userId);
  }

  /// Check if role has permission enabled in role_permissions table
  Future<bool> _checkRolePermission(String role, String permissionName) async {
    // Check cache first
    final cacheKey = '$role:$permissionName';
    if (_permissionCache.containsKey(role)) {
      final cached = _permissionCache[role]![permissionName];
      if (cached != null) return cached;
    }

    // Query database
    final permission = await _db.permissionsDao.getPermissionByName(permissionName);
    if (permission == null) return false;

    final rolePermission = await _db.rolePermissionsDao.getRolePermission(role, permission.id);
    final hasPermission = rolePermission?.isEnabled ?? false;

    // Update cache
    _permissionCache[role] = _permissionCache[role] ?? {};
    _permissionCache[role]![permissionName] = hasPermission;

    return hasPermission;
  }

  /// Validate store scope (ALL_STORES / ASSIGNED_STORES / OWN_STORE)
  Future<bool> _validateStoreScope(
    int userId,
    String scope,
    String storeId,
  ) async {
    final storeScope = StoreScope.fromString(scope);

    switch (storeScope) {
      case StoreScope.ALL_STORES:
        return true;

      case StoreScope.ASSIGNED_STORES:
        // Check if store is in user's assigned stores
        return await _db.storeAssignmentsDao.hasStoreAccess(userId, storeId);

      case StoreScope.OWN_STORE:
        // Check if storeId matches user's primary store
        final employee = await _db.employeesDao.getEmployeeById(userId);
        return employee?.primaryStoreId == storeId;
    }
  }

  /// Get all permissions for a user
  Future<Set<String>> getUserPermissions(int userId) async {
    final rbacEnabled = await isRBACEnabled();
    if (!rbacEnabled) {
      // Return all permissions when RBAC disabled
      return await _getAllPermissionNames();
    }

    final userRole = await _getUserRole(userId);
    if (userRole == null) return {};

    if (userRole.role == 'OWNER') {
      return await _getAllPermissionNames();
    }

    return await _getRolePermissions(userRole.role);
  }

  /// Get all permissions for a specific role
  Future<Set<String>> _getRolePermissions(String role) async {
    final rolePermissions = await _db.rolePermissionsDao.getEnabledRolePermissions(role);

    final permissionIds = rolePermissions.map((rp) => rp.permissionId).toList();
    if (permissionIds.isEmpty) return {};

    final permissions = await _db.permissionsDao.getAllPermissions();
    final enabledPermissions = permissions
        .where((p) => permissionIds.contains(p.id))
        .map((p) => p.name)
        .toSet();

    return enabledPermissions;
  }

  /// Get all permission names in the system
  Future<Set<String>> _getAllPermissionNames() async {
    final permissions = await _db.permissionsDao.getAllPermissions();
    return permissions.map((p) => p.name).toSet();
  }

  /// Get user's store access list (for ASSIGNED_STORES scope)
  Future<List<String>> getUserStoreIds(int userId) async {
    final userRole = await _getUserRole(userId);
    if (userRole == null) return [];

    final storeScope = StoreScope.fromString(userRole.scope);

    switch (storeScope) {
      case StoreScope.ALL_STORES:
        // TODO: Return all store IDs from stores table
        // This requires a stores table to exist
        return [];

      case StoreScope.ASSIGNED_STORES:
        return await _db.storeAssignmentsDao.getUserStoreIds(userId);

      case StoreScope.OWN_STORE:
        final employee = await _db.employeesDao.getEmployeeById(userId);
        if (employee?.primaryStoreId != null) {
          return [employee!.primaryStoreId!];
        }
        return [];
    }
  }

  /// Check if user can access specific store
  Future<bool> canAccessStore(int userId, String storeId) async {
    final rbacEnabled = await isRBACEnabled();
    if (!rbacEnabled) return true;

    final userRole = await _getUserRole(userId);
    if (userRole == null) return false;

    if (userRole.role == 'OWNER') return true;

    return await _validateStoreScope(userId, userRole.scope, storeId);
  }

  /// Clear permission cache (call when permissions are updated)
  void clearCache() {
    _permissionCache.clear();
  }

  /// Clear cache for specific role
  void clearRoleCache(String role) {
    _permissionCache.remove(role);
  }

  /// Get user's role enum
  Future<EmployeeRole?> getUserRoleEnum(int userId) async {
    final userRole = await _getUserRole(userId);
    if (userRole == null) return null;

    return EmployeeRole.fromString(userRole.role);
  }

  /// Check if user is Owner
  Future<bool> isOwner(int userId) async {
    final userRole = await _getUserRole(userId);
    return userRole?.role == 'OWNER';
  }

  /// Check if user can manage other users
  Future<bool> canManageUsers(int userId) async {
    return await hasPermission(userId, 'staff.manage');
  }

  /// Check if user can view revenue data
  Future<bool> canViewRevenue(int userId, {String? storeId}) async {
    return await hasPermission(
      userId,
      'revenue.dashboard.view',
      storeId: storeId,
    );
  }
}

// ignore_for_file: constant_identifier_names

/// Four fixed roles for RBAC system (cannot be deleted or added)
enum EmployeeRole {
  OWNER,         // All permissions, ALL_STORES scope
  AREA_MANAGER,  // Customizable permissions, ASSIGNED_STORES scope
  STORE_MANAGER, // Customizable permissions, OWN_STORE scope
  STAFF;         // Customizable permissions, OWN_STORE scope

  /// Display name for UI
  String get displayName {
    switch (this) {
      case EmployeeRole.OWNER:
        return 'Owner';
      case EmployeeRole.AREA_MANAGER:
        return 'Area Manager';
      case EmployeeRole.STORE_MANAGER:
        return 'Store Manager';
      case EmployeeRole.STAFF:
        return 'Staff';
    }
  }

  /// Display name alias (kept for backward compatibility)
  String get displayNameKo => displayName;

  /// Description for UI
  String get description {
    switch (this) {
      case EmployeeRole.OWNER:
        return 'Full system access - all stores';
      case EmployeeRole.AREA_MANAGER:
        return 'Manage multiple assigned stores';
      case EmployeeRole.STORE_MANAGER:
        return 'Manage single store';
      case EmployeeRole.STAFF:
        return 'Basic POS operations';
    }
  }

  /// Description alias (kept for backward compatibility)
  String get descriptionKo => description;

  /// Default store scope for this role
  StoreScope get defaultScope {
    switch (this) {
      case EmployeeRole.OWNER:
        return StoreScope.ALL_STORES;
      case EmployeeRole.AREA_MANAGER:
        return StoreScope.ASSIGNED_STORES;
      case EmployeeRole.STORE_MANAGER:
      case EmployeeRole.STAFF:
        return StoreScope.OWN_STORE;
    }
  }

  /// Check if this role can be modified (Owner cannot be modified)
  bool get canModifyPermissions {
    return this != EmployeeRole.OWNER;
  }

  /// Convert from string
  static EmployeeRole fromString(String value) {
    switch (value.toUpperCase()) {
      case 'OWNER':
        return EmployeeRole.OWNER;
      case 'AREA_MANAGER':
        return EmployeeRole.AREA_MANAGER;
      case 'STORE_MANAGER':
        return EmployeeRole.STORE_MANAGER;
      case 'STAFF':
        return EmployeeRole.STAFF;
      default:
        return EmployeeRole.STAFF; // Default to STAFF for unknown values
    }
  }

  /// Convert to string for database storage
  String toDbString() {
    return name;
  }
}

/// Store scope for multi-store access control
enum StoreScope {
  ALL_STORES,       // OWNER only - access all stores
  ASSIGNED_STORES,  // AREA_MANAGER - access assigned stores only
  OWN_STORE;        // STORE_MANAGER, STAFF - access own store only

  String get displayName {
    switch (this) {
      case StoreScope.ALL_STORES:
        return 'All Stores';
      case StoreScope.ASSIGNED_STORES:
        return 'Assigned Stores';
      case StoreScope.OWN_STORE:
        return 'Own Store';
    }
  }

  /// Display name alias (kept for backward compatibility)
  String get displayNameKo => displayName;

  /// Convert from string
  static StoreScope fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ALL_STORES':
        return StoreScope.ALL_STORES;
      case 'ASSIGNED_STORES':
        return StoreScope.ASSIGNED_STORES;
      case 'OWN_STORE':
        return StoreScope.OWN_STORE;
      default:
        return StoreScope.OWN_STORE; // Default to OWN_STORE for unknown values
    }
  }

  /// Convert to string for database storage
  String toDbString() {
    return name;
  }
}

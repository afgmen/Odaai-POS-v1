# Role-Based Access Control (RBAC) Design Document

> **Summary**: Detailed design for implementing granular permission-based RBAC with owner-configurable toggles and multi-store scope validation
>
> **Project**: Oda POS
> **Version**: 1.0.0
> **Author**: Claude AI & JINLee
> **Date**: 2026-02-12
> **Status**: Draft
> **Planning Doc**: [role-based-access-control.plan.md](../../01-plan/features/role-based-access-control.plan.md)

### Pipeline References

| Phase | Document | Status |
|-------|----------|--------|
| Phase 1 | Schema Definition | N/A |
| Phase 2 | Coding Conventions | N/A |
| Phase 3 | Mockup | N/A |
| Phase 4 | API Spec | N/A |

---

## 1. Overview

### 1.1 Design Goals

- **Owner Control**: Enable Owner to turn RBAC on/off and customize permissions per role
- **Backward Compatibility**: When RBAC disabled, all employees have full access (no breaking changes)
- **Granular Permissions**: Use `module.action` format for fine-grained access control
- **Store Scope Enforcement**: Validate both permission AND store scope for multi-store operations
- **Audit Transparency**: Track all permission changes with comprehensive logging
- **Performance**: Permission checks must complete in <10ms with in-memory caching

### 1.2 Design Principles

- **Security by Default**: Sensitive permissions are explicitly granted, never implied
- **Separation of Concerns**: Permission logic isolated in dedicated service layer
- **Single Source of Truth**: Permission rules stored in database, cached in memory
- **Fail-Safe**: If RBAC check fails, deny access by default
- **Immutable Owner**: Owner permissions cannot be modified or restricted

---

## 2. Architecture

### 2.1 Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  PermissionGateWidget    RolesPermissionsScreen                 │
│  (UI Guard)              (Settings)                              │
│         │                      │                                 │
│         └──────────┬───────────┘                                 │
│                    │                                             │
├────────────────────┼─────────────────────────────────────────────┤
│                    ▼          Application Layer                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│              PermissionProvider (Riverpod)                       │
│                    │                                             │
│       ┌────────────┼────────────┐                                │
│       │            │            │                                │
│       ▼            ▼            ▼                                │
│  PermissionService  RolePermissionService  AuditLogService       │
│       │            │            │                                │
├───────┼────────────┼────────────┼────────────────────────────────┤
│       │            │            │         Domain Layer           │
├───────┼────────────┼────────────┼────────────────────────────────┤
│       │            │            │                                │
│  Permission    EmployeeRole  StoreScope                          │
│  (enum)        (enum)        (enum)                              │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│                    Infrastructure Layer                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│              AppDatabase (Drift)                                 │
│       │            │            │            │                   │
│       ▼            ▼            ▼            ▼                   │
│  PermissionsDao  RolePermissionsDao  UserRolesDao  AuditLogsDao │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow

#### Permission Check Flow
```
User Action
    │
    ▼
UI Component calls PermissionProvider.hasPermission()
    │
    ▼
Check if RBAC enabled (system_settings.rbac_enabled)
    │
    ├─ NO → Grant access (backward compatible)
    │
    └─ YES
        │
        ▼
    PermissionService.hasPermission(userId, permission, storeId?)
        │
        ├─ Get user's role from user_roles table
        │
        ├─ Get role's permissions from role_permissions table
        │
        ├─ Check permission exists
        │   ├─ NO → Deny access
        │   └─ YES
        │       │
        │       ▼
        │   Validate store scope (if storeId provided)
        │       │
        │       ├─ Get user's scope (ALL_STORES / ASSIGNED_STORES / OWN_STORE)
        │       │
        │       ├─ If ALL_STORES → Grant access
        │       │
        │       ├─ If ASSIGNED_STORES
        │       │   └─ Check store_assignments table
        │       │       ├─ Store assigned → Grant access
        │       │       └─ Store not assigned → Deny access
        │       │
        │       └─ If OWN_STORE
        │           └─ Check if storeId == user's primary_store_id
        │               ├─ Match → Grant access
        │               └─ No match → Deny access
        │
        └─ Return boolean result
```

#### Permission Update Flow (Owner Only)
```
Owner toggles permission in Settings
    │
    ▼
RolePermissionService.updatePermission(role, permission, enabled)
    │
    ├─ Validate: user is OWNER
    │
    ├─ Validate: role is not OWNER (cannot modify Owner permissions)
    │
    ├─ Get old permission value from DB
    │
    ├─ Update role_permissions table
    │
    ├─ Clear in-memory permission cache
    │
    ├─ Create audit log entry
    │   └─ AuditLogService.logPermissionChange(...)
    │
    └─ Broadcast state change to all PermissionProvider listeners
```

### 2.3 Dependencies

| Component | Depends On | Purpose |
|-----------|-----------|---------|
| PermissionGateWidget | PermissionProvider | UI guard for conditional rendering |
| PermissionProvider | PermissionService | Reactive permission state management |
| PermissionService | PermissionsDao, RolePermissionsDao, UserRolesDao | Permission validation logic |
| RolePermissionService | RolePermissionsDao, AuditLogsDao | Permission management for Owner |
| AuditLogService | AuditLogsDao | Audit trail recording |

---

## 3. Data Model

### 3.1 Entity Definitions

#### **Permission** (Master List)
```dart
class Permission {
  final String id;              // UUID
  final String name;            // e.g., "revenue.daily.view"
  final String module;          // e.g., "revenue"
  final String description;     // e.g., "View daily revenue reports"
  final bool isSensitive;       // true for revenue/settings
  final DateTime createdAt;
}
```

#### **RolePermission** (Role-to-Permission Mapping)
```dart
class RolePermission {
  final String id;              // UUID
  final EmployeeRole role;      // OWNER, AREA_MANAGER, STORE_MANAGER, STAFF
  final String permissionId;    // FK → permissions.id
  final bool isEnabled;         // true/false
  final DateTime updatedAt;
  final String updatedBy;       // FK → employees.id
}
```

#### **UserRole** (User-to-Role Assignment)
```dart
class UserRole {
  final String id;              // UUID
  final String userId;          // FK → employees.id
  final EmployeeRole role;      // OWNER, AREA_MANAGER, STORE_MANAGER, STAFF
  final StoreScope scope;       // ALL_STORES, ASSIGNED_STORES, OWN_STORE
  final DateTime assignedAt;
  final String assignedBy;      // FK → employees.id
}
```

#### **StoreAssignment** (Area Manager Store Access)
```dart
class StoreAssignment {
  final String id;              // UUID
  final String userId;          // FK → employees.id
  final String storeId;         // FK → stores.id
  final DateTime assignedAt;
  final String assignedBy;      // FK → employees.id
}
```

#### **AuditLog** (Permission Change History)
```dart
class AuditLog {
  final String id;              // UUID
  final String eventType;       // e.g., "ROLE_PERMISSION_UPDATED"
  final String actorId;         // FK → employees.id
  final String actorName;       // Denormalized (e.g., "John Doe (OWNER)")
  final String? targetRole;     // Role being modified
  final String? permission;     // Permission being changed
  final String? oldValue;       // JSON string
  final String? newValue;       // JSON string
  final DateTime timestamp;
  final String? ipAddress;      // Optional
}
```

### 3.2 Entity Relationships

```
┌──────────────┐
│  Permission  │ (Master permission definitions)
└──────┬───────┘
       │
       │ 1
       │
       │ N
┌──────┴────────────┐
│ RolePermission    │ (Role → Permission mapping)
│                   │
│ - role            │──┐
│ - permissionId    │  │
│ - isEnabled       │  │
└───────────────────┘  │
                       │
                       │
┌──────────────┐       │
│  Employee    │       │
└──────┬───────┘       │
       │               │
       │ 1             │
       │               │
       │ N             │
┌──────┴───────────┐   │
│  UserRole        │   │
│                  │   │
│ - userId         │   │
│ - role ──────────┼───┘ (matches RolePermission.role)
│ - scope          │
└──────┬───────────┘
       │
       │ 1
       │
       │ N
┌──────┴──────────────┐
│  StoreAssignment    │ (For AREA_MANAGER scope)
│                     │
│ - userId            │
│ - storeId           │
└─────────────────────┘


┌──────────────┐
│  AuditLog    │ (Audit trail)
│              │
│ - actorId ───┼──→ Employee.id
│ - targetRole │
│ - permission │
└──────────────┘
```

### 3.3 Database Schema (Drift)

#### **`permissions`** - Master permission list

```dart
class Permissions extends Table {
  TextColumn get id => text().named('id')(); // UUID (PK)
  TextColumn get name => text().unique()(); // e.g., "revenue.daily.view"
  TextColumn get module => text()(); // e.g., "revenue"
  TextColumn get description => text()();
  BoolColumn get isSensitive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### **`role_permissions`** - Role-to-permission mapping

```dart
class RolePermissions extends Table {
  TextColumn get id => text().named('id')(); // UUID (PK)
  TextColumn get role => text()(); // OWNER | AREA_MANAGER | STORE_MANAGER | STAFF
  TextColumn get permissionId => text()(); // FK → permissions.id
  BoolColumn get isEnabled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get updatedBy => text()(); // FK → employees.id

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {role, permissionId}, // Composite unique constraint
  ];
}
```

#### **`user_roles`** - User-to-role assignment

```dart
class UserRoles extends Table {
  TextColumn get id => text().named('id')(); // UUID (PK)
  IntColumn get userId => integer()(); // FK → employees.id
  TextColumn get role => text()(); // OWNER | AREA_MANAGER | STORE_MANAGER | STAFF
  TextColumn get scope => text()(); // ALL_STORES | ASSIGNED_STORES | OWN_STORE
  DateTimeColumn get assignedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get assignedBy => integer()(); // FK → employees.id

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {userId}, // One role per user
  ];
}
```

#### **`store_assignments`** - Area Manager store assignments

```dart
class StoreAssignments extends Table {
  TextColumn get id => text().named('id')(); // UUID (PK)
  IntColumn get userId => integer()(); // FK → employees.id
  TextColumn get storeId => text()(); // FK → stores.id
  DateTimeColumn get assignedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get assignedBy => integer()(); // FK → employees.id

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {userId, storeId}, // No duplicate assignments
  ];
}
```

#### **`audit_logs`** - Permission change audit trail

```dart
class AuditLogs extends Table {
  TextColumn get id => text().named('id')(); // UUID (PK)
  TextColumn get eventType => text()(); // ROLE_PERMISSION_UPDATED, etc.
  IntColumn get actorId => integer()(); // FK → employees.id
  TextColumn get actorName => text()(); // Denormalized for history
  TextColumn get targetRole => text().nullable()();
  TextColumn get permission => text().nullable()();
  TextColumn get oldValue => text().nullable()(); // JSON
  TextColumn get newValue => text().nullable()(); // JSON
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get ipAddress => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

#### **`employees`** (Updated) - Add RBAC fields

```dart
class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get name => text()();
  TextColumn get passwordHash => text()();

  // EXISTING FIELDS
  TextColumn get role => text().withDefault(const Constant('CASHIER'))();
  TextColumn get pinHash => text().nullable()();
  DateTimeColumn get pinChangedAt => dateTime().nullable()();
  DateTimeColumn get lastLoginAt => dateTime().nullable()();
  TextColumn get sessionToken => text().nullable()();
  DateTimeColumn get sessionExpiresAt => dateTime().nullable()();

  // NEW RBAC FIELDS
  TextColumn get defaultRole => text().withDefault(const Constant('STAFF'))(); // OWNER | AREA_MANAGER | STORE_MANAGER | STAFF
  TextColumn get storeScope => text().withDefault(const Constant('OWN_STORE'))(); // ALL_STORES | ASSIGNED_STORES | OWN_STORE
  TextColumn get primaryStoreId => text().nullable()(); // FK → stores.id

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### **`system_settings`** (Updated) - Add RBAC toggle

```dart
class SystemSettings extends Table {
  TextColumn get key => text()(); // PK
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}

// Seed data:
// INSERT INTO system_settings (key, value) VALUES ('rbac_enabled', 'false');
```

---

## 4. Domain Layer - Enums and Types

### 4.1 EmployeeRole Enum

```dart
/// Four fixed roles (cannot be deleted or added)
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
}
```

### 4.2 StoreScope Enum

```dart
/// Store access scope for multi-store operations
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
}
```

### 4.3 Permission Module Constants

```dart
/// Permission naming convention: module.action
class PermissionModules {
  // POS Module
  static const String POS_OPEN = 'pos.open';
  static const String POS_REFUND = 'pos.refund';
  static const String POS_DISCOUNT = 'pos.discount';
  static const String POS_PRICE_OVERRIDE = 'pos.price.override';
  static const String POS_CASH_DRAWER_OPEN = 'pos.cash.drawer.open';

  // Orders Module
  static const String ORDER_CREATE = 'order.create';
  static const String ORDER_CANCEL = 'order.cancel';
  static const String ORDER_VIEW = 'order.view';

  // Inventory Module
  static const String INVENTORY_VIEW = 'inventory.view';
  static const String INVENTORY_EDIT = 'inventory.edit';
  static const String INVENTORY_ADJUST = 'inventory.adjust';
  static const String INVENTORY_WRITEOFF = 'inventory.writeoff';

  // Revenue Module (Sensitive)
  static const String REVENUE_DASHBOARD_VIEW = 'revenue.dashboard.view';
  static const String REVENUE_DAILY_VIEW = 'revenue.daily.view';
  static const String REVENUE_WEEKLY_VIEW = 'revenue.weekly.view';
  static const String REVENUE_MONTHLY_VIEW = 'revenue.monthly.view';
  static const String REVENUE_MULTISTORE_VIEW = 'revenue.multistore.view';
  static const String REVENUE_EXPORT = 'revenue.export';
  static const String REVENUE_PNL_VIEW = 'revenue.pnl.view';

  // Staff Module
  static const String STAFF_VIEW = 'staff.view';
  static const String STAFF_MANAGE = 'staff.manage';
  static const String STAFF_ROLE_ASSIGN = 'staff.role.assign';

  // Settings Module
  static const String SETTINGS_STORE_EDIT = 'settings.store.edit';
  static const String SETTINGS_TAX_EDIT = 'settings.tax.edit';
  static const String SETTINGS_PAYMENT_EDIT = 'settings.payment.edit';
  static const String SETTINGS_INTEGRATION_EDIT = 'settings.integration.edit';

  /// Get module name from permission
  static String getModule(String permission) {
    final parts = permission.split('.');
    return parts.isNotEmpty ? parts[0] : 'unknown';
  }

  /// Get all permissions for a module
  static List<String> getPermissionsByModule(String module) {
    const allPermissions = [
      POS_OPEN, POS_REFUND, POS_DISCOUNT, POS_PRICE_OVERRIDE, POS_CASH_DRAWER_OPEN,
      ORDER_CREATE, ORDER_CANCEL, ORDER_VIEW,
      INVENTORY_VIEW, INVENTORY_EDIT, INVENTORY_ADJUST, INVENTORY_WRITEOFF,
      REVENUE_DASHBOARD_VIEW, REVENUE_DAILY_VIEW, REVENUE_WEEKLY_VIEW,
      REVENUE_MONTHLY_VIEW, REVENUE_MULTISTORE_VIEW, REVENUE_EXPORT, REVENUE_PNL_VIEW,
      STAFF_VIEW, STAFF_MANAGE, STAFF_ROLE_ASSIGN,
      SETTINGS_STORE_EDIT, SETTINGS_TAX_EDIT, SETTINGS_PAYMENT_EDIT, SETTINGS_INTEGRATION_EDIT,
    ];

    return allPermissions.where((p) => p.startsWith('$module.')).toList();
  }
}
```

### 4.4 Audit Event Types

```dart
/// Audit log event types
class AuditEventType {
  static const String ROLE_PERMISSION_UPDATED = 'ROLE_PERMISSION_UPDATED';
  static const String USER_ROLE_ASSIGNED = 'USER_ROLE_ASSIGNED';
  static const String USER_ROLE_CHANGED = 'USER_ROLE_CHANGED';
  static const String STORE_ASSIGNMENT_ADDED = 'STORE_ASSIGNMENT_ADDED';
  static const String STORE_ASSIGNMENT_REMOVED = 'STORE_ASSIGNMENT_REMOVED';
  static const String RBAC_SYSTEM_ENABLED = 'RBAC_SYSTEM_ENABLED';
  static const String RBAC_SYSTEM_DISABLED = 'RBAC_SYSTEM_DISABLED';
}
```

---

## 5. Application Layer - Services

### 5.1 PermissionService (Core Permission Logic)

**Location**: `lib/features/auth/domain/services/permission_service.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';

/// Core permission validation service
class PermissionService {
  final AppDatabase _db;

  // In-memory cache for performance (invalidated on permission updates)
  final Map<String, Map<String, bool>> _permissionCache = {};

  PermissionService(this._db);

  /// Check if RBAC system is enabled
  Future<bool> isRBACEnabled() async {
    final setting = await _db.select(_db.systemSettings)
      .where((s) => s.key.equals('rbac_enabled'))
      .getSingleOrNull();

    return setting?.value == 'true';
  }

  /// Main permission check: validates permission + scope
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
    return await _db.select(_db.userRoles)
      .where((r) => r.userId.equals(userId))
      .getSingleOrNull();
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
    final permission = await _db.select(_db.permissions)
      .where((p) => p.name.equals(permissionName))
      .getSingleOrNull();

    if (permission == null) return false;

    final rolePermission = await _db.select(_db.rolePermissions)
      .where((rp) => rp.role.equals(role) & rp.permissionId.equals(permission.id))
      .getSingleOrNull();

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
    switch (scope) {
      case 'ALL_STORES':
        return true;

      case 'ASSIGNED_STORES':
        // Check if store is in user's assigned stores
        final assignment = await _db.select(_db.storeAssignments)
          .where((sa) => sa.userId.equals(userId) & sa.storeId.equals(storeId))
          .getSingleOrNull();
        return assignment != null;

      case 'OWN_STORE':
        // Check if storeId matches user's primary store
        final employee = await _db.select(_db.employees)
          .where((e) => e.id.equals(userId))
          .getSingleOrNull();
        return employee?.primaryStoreId == storeId;

      default:
        return false;
    }
  }

  /// Get all permissions for a user
  Future<Set<String>> getUserPermissions(int userId) async {
    final rbacEnabled = await isRBACEnabled();
    if (!rbacEnabled) {
      // Return all permissions when RBAC disabled
      return _getAllPermissionNames();
    }

    final userRole = await _getUserRole(userId);
    if (userRole == null) return {};

    if (userRole.role == 'OWNER') {
      return _getAllPermissionNames();
    }

    return await _getRolePermissions(userRole.role);
  }

  /// Get all permissions for a specific role
  Future<Set<String>> _getRolePermissions(String role) async {
    final rolePermissions = await _db.select(_db.rolePermissions)
      .where((rp) => rp.role.equals(role) & rp.isEnabled.equals(true))
      .get();

    final permissionIds = rolePermissions.map((rp) => rp.permissionId).toList();

    final permissions = await _db.select(_db.permissions)
      .where((p) => p.id.isIn(permissionIds))
      .get();

    return permissions.map((p) => p.name).toSet();
  }

  /// Get all permission names in the system
  Future<Set<String>> _getAllPermissionNames() async {
    final permissions = await _db.select(_db.permissions).get();
    return permissions.map((p) => p.name).toSet();
  }

  /// Clear permission cache (call when permissions are updated)
  void clearCache() {
    _permissionCache.clear();
  }
}

/// Provider for PermissionService
final permissionServiceProvider = Provider<PermissionService>((ref) {
  final database = ref.watch(databaseProvider);
  return PermissionService(database);
});
```

### 5.2 RolePermissionService (Permission Management for Owner)

**Location**: `lib/features/auth/domain/services/role_permission_service.dart`

```dart
import '../../../database/app_database.dart';
import 'audit_log_service.dart';
import 'permission_service.dart';

/// Service for Owner to manage role permissions
class RolePermissionService {
  final AppDatabase _db;
  final AuditLogService _auditLog;
  final PermissionService _permissionService;

  RolePermissionService(this._db, this._auditLog, this._permissionService);

  /// Update a role's permission (Owner only)
  Future<void> updatePermission({
    required int actorId,
    required String role,
    required String permissionName,
    required bool enabled,
  }) async {
    // Validate: actor is OWNER
    final actor = await _getUserRole(actorId);
    if (actor?.role != 'OWNER') {
      throw Exception('Only OWNER can modify permissions');
    }

    // Validate: cannot modify OWNER role
    if (role == 'OWNER') {
      throw Exception('Cannot modify OWNER permissions');
    }

    // Get permission ID
    final permission = await _db.select(_db.permissions)
      .where((p) => p.name.equals(permissionName))
      .getSingle();

    // Get current value
    final existing = await _db.select(_db.rolePermissions)
      .where((rp) => rp.role.equals(role) & rp.permissionId.equals(permission.id))
      .getSingleOrNull();

    final oldValue = existing?.isEnabled ?? false;

    // Update or insert
    if (existing != null) {
      await _db.update(_db.rolePermissions).replace(
        existing.copyWith(
          isEnabled: enabled,
          updatedAt: DateTime.now(),
          updatedBy: actorId,
        ),
      );
    } else {
      await _db.into(_db.rolePermissions).insert(
        RolePermissionsCompanion.insert(
          id: _generateUUID(),
          role: role,
          permissionId: permission.id,
          isEnabled: enabled,
          updatedBy: actorId,
        ),
      );
    }

    // Clear permission cache
    _permissionService.clearCache();

    // Create audit log
    final actorEmployee = await _db.select(_db.employees)
      .where((e) => e.id.equals(actorId))
      .getSingle();

    await _auditLog.logPermissionChange(
      eventType: AuditEventType.ROLE_PERMISSION_UPDATED,
      actorId: actorId,
      actorName: '${actorEmployee.name} (${actor!.role})',
      targetRole: role,
      permission: permissionName,
      oldValue: oldValue.toString(),
      newValue: enabled.toString(),
    );
  }

  /// Get all permissions for a role with their enabled status
  Future<Map<String, bool>> getRolePermissions(String role) async {
    final allPermissions = await _db.select(_db.permissions).get();
    final rolePermissions = await _db.select(_db.rolePermissions)
      .where((rp) => rp.role.equals(role))
      .get();

    final result = <String, bool>{};
    for (final permission in allPermissions) {
      final rolePermission = rolePermissions.firstWhere(
        (rp) => rp.permissionId == permission.id,
        orElse: () => null,
      );
      result[permission.name] = rolePermission?.isEnabled ?? false;
    }

    return result;
  }

  Future<UserRole?> _getUserRole(int userId) async {
    return await _db.select(_db.userRoles)
      .where((r) => r.userId.equals(userId))
      .getSingleOrNull();
  }

  String _generateUUID() {
    // Use uuid package: Uuid().v4()
    return ''; // Placeholder
  }
}
```

### 5.3 AuditLogService (Audit Trail Recording)

**Location**: `lib/features/auth/domain/services/audit_log_service.dart`

```dart
import '../../../database/app_database.dart';

/// Service for recording audit logs
class AuditLogService {
  final AppDatabase _db;

  AuditLogService(this._db);

  /// Log permission change
  Future<void> logPermissionChange({
    required String eventType,
    required int actorId,
    required String actorName,
    String? targetRole,
    String? permission,
    String? oldValue,
    String? newValue,
    String? ipAddress,
  }) async {
    await _db.into(_db.auditLogs).insert(
      AuditLogsCompanion.insert(
        id: _generateUUID(),
        eventType: eventType,
        actorId: actorId,
        actorName: actorName,
        targetRole: Value(targetRole),
        permission: Value(permission),
        oldValue: Value(oldValue),
        newValue: Value(newValue),
        ipAddress: Value(ipAddress),
      ),
    );
  }

  /// Get audit logs with pagination
  Future<List<AuditLog>> getAuditLogs({
    int limit = 100,
    int offset = 0,
    String? eventTypeFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _db.select(_db.auditLogs);

    if (eventTypeFilter != null) {
      query = query..where((log) => log.eventType.equals(eventTypeFilter));
    }

    if (startDate != null) {
      query = query..where((log) => log.timestamp.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      query = query..where((log) => log.timestamp.isSmallerOrEqualValue(endDate));
    }

    query = query..orderBy([(log) => OrderingTerm.desc(log.timestamp)]);
    query = query..limit(limit, offset: offset);

    return await query.get();
  }

  String _generateUUID() {
    // Use uuid package: Uuid().v4()
    return ''; // Placeholder
  }
}
```

---

## 6. Presentation Layer - UI Components

### 6.1 PermissionGateWidget (UI Guard)

**Location**: `lib/core/widgets/permission_gate_widget.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/permission_provider.dart';

/// Widget that conditionally renders children based on permission
class PermissionGateWidget extends ConsumerWidget {
  final String permission;
  final String? storeId;
  final Widget child;
  final Widget? fallback;

  const PermissionGateWidget({
    super.key,
    required this.permission,
    this.storeId,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return fallback ?? const SizedBox.shrink();
    }

    final hasPermission = ref.watch(
      hasPermissionProvider(permission: permission, storeId: storeId),
    );

    return hasPermission.when(
      data: (allowed) => allowed ? child : (fallback ?? const SizedBox.shrink()),
      loading: () => fallback ?? const SizedBox.shrink(),
      error: (_, __) => fallback ?? const SizedBox.shrink(),
    );
  }
}

/// Usage example:
/// PermissionGateWidget(
///   permission: PermissionModules.REVENUE_DAILY_VIEW,
///   storeId: currentStoreId,
///   child: DailyRevenueCard(),
///   fallback: AccessDeniedCard(),
/// )
```

### 6.2 Settings Screen - RBAC Toggle

**Location**: `lib/features/settings/presentation/screens/security_settings_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rbacEnabled = ref.watch(rbacSettingProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Only OWNER can see/modify RBAC setting
    if (currentUser?.defaultRole != 'OWNER') {
      return const Center(
        child: Text('Access Denied: Owner Only'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Access Control'),
      ),
      body: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Role-Based Access Control',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: rbacEnabled.value ?? false,
                        onChanged: (value) async {
                          await ref.read(rbacSettingProvider.notifier).toggle(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    rbacEnabled.value == true
                      ? 'RBAC is ENABLED. Employees can only access features based on their role.'
                      : 'RBAC is DISABLED. All employees have full access to all features.',
                    style: TextStyle(
                      color: rbacEnabled.value == true ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'When enabled:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint('Staff cannot view financial reports'),
                  _buildBulletPoint('Only managers can access settings'),
                  _buildBulletPoint('Area managers can manage multiple stores'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.amber.shade700),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Changes take effect immediately',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Link to Roles & Permissions management
          if (rbacEnabled.value == true)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Manage Role Permissions'),
              subtitle: const Text('Customize permissions for each role'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/settings/roles-permissions');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
```

### 6.3 Roles & Permissions Management Screen (Owner Only)

**Location**: `lib/features/settings/presentation/screens/roles_permissions_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RolesPermissionsScreen extends ConsumerStatefulWidget {
  const RolesPermissionsScreen({super.key});

  @override
  ConsumerState<RolesPermissionsScreen> createState() => _RolesPermissionsScreenState();
}

class _RolesPermissionsScreenState extends ConsumerState<RolesPermissionsScreen> {
  String selectedRole = 'AREA_MANAGER';

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    // Only OWNER can access
    if (currentUser?.defaultRole != 'OWNER') {
      return const Scaffold(
        body: Center(child: Text('Access Denied: Owner Only')),
      );
    }

    final permissions = ref.watch(rolePermissionsProvider(selectedRole));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles & Permissions'),
      ),
      body: Row(
        children: [
          // Left sidebar: Role selector
          SizedBox(
            width: 250,
            child: ListView(
              children: [
                _buildRoleTile('AREA_MANAGER', 'Area Manager'),
                _buildRoleTile('STORE_MANAGER', 'Store Manager'),
                _buildRoleTile('STAFF', 'Staff'),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.shield, color: Colors.blue),
                  title: const Text('OWNER'),
                  subtitle: const Text('All Permissions (Cannot Modify)'),
                  enabled: false,
                ),
              ],
            ),
          ),

          const VerticalDivider(width: 1),

          // Right panel: Permission toggles
          Expanded(
            child: permissions.when(
              data: (permissionMap) => _buildPermissionList(permissionMap),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTile(String role, String displayName) {
    final isSelected = selectedRole == role;
    return ListTile(
      selected: isSelected,
      leading: Icon(
        Icons.person,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(displayName),
      onTap: () => setState(() => selectedRole = role),
    );
  }

  Widget _buildPermissionList(Map<String, bool> permissionMap) {
    // Group permissions by module
    final groupedPermissions = _groupPermissionsByModule(permissionMap);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: groupedPermissions.entries.map((entry) {
        return _buildPermissionModule(
          module: entry.key,
          permissions: entry.value,
        );
      }).toList(),
    );
  }

  Widget _buildPermissionModule({
    required String module,
    required Map<String, bool> permissions,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getModuleDisplayName(module),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (module == 'revenue')
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.red.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Sensitive - Financial Data',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 24),
            ...permissions.entries.map((permission) {
              return SwitchListTile(
                title: Text(_getPermissionDisplayName(permission.key)),
                subtitle: Text(permission.key),
                value: permission.value,
                onChanged: (enabled) async {
                  await ref.read(rolePermissionServiceProvider).updatePermission(
                    actorId: ref.read(currentUserProvider)!.id,
                    role: selectedRole,
                    permissionName: permission.key,
                    enabled: enabled,
                  );
                  ref.invalidate(rolePermissionsProvider(selectedRole));
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Map<String, Map<String, bool>> _groupPermissionsByModule(Map<String, bool> permissions) {
    final grouped = <String, Map<String, bool>>{};
    for (final entry in permissions.entries) {
      final module = PermissionModules.getModule(entry.key);
      grouped[module] = grouped[module] ?? {};
      grouped[module]![entry.key] = entry.value;
    }
    return grouped;
  }

  String _getModuleDisplayName(String module) {
    switch (module) {
      case 'pos': return 'POS Permissions';
      case 'order': return 'Order Permissions';
      case 'inventory': return 'Inventory Permissions';
      case 'revenue': return 'Revenue Permissions';
      case 'staff': return 'Staff Permissions';
      case 'settings': return 'Settings Permissions';
      default: return module.toUpperCase();
    }
  }

  String _getPermissionDisplayName(String permission) {
    // Convert "revenue.daily.view" → "View Daily Revenue"
    final parts = permission.split('.');
    return parts.skip(1).map((p) => _capitalize(p)).join(' ');
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
```

---

## 7. Error Handling

### 7.1 Error Types

| Error Code | Message | Cause | Handling |
|-----------|---------|-------|----------|
| PERMISSION_DENIED | Permission denied | User lacks required permission | Show "Access Denied" dialog with explanation |
| INVALID_SCOPE | Invalid store scope | User accessing store outside their scope | Show "Store Access Denied" message |
| RBAC_DISABLED | RBAC system is disabled | System configuration | Should not happen (backward compatible mode) |
| OWNER_MODIFICATION_FORBIDDEN | Cannot modify Owner permissions | Attempted to change Owner permissions | Show error dialog |
| INVALID_ROLE | Invalid role specified | Role does not exist | Show error dialog |

### 7.2 Error Response Format

```dart
class PermissionError implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  PermissionError({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'PermissionError($code): $message';
}

// Usage:
throw PermissionError(
  code: 'PERMISSION_DENIED',
  message: 'You do not have permission to view revenue data',
  details: {'permission': 'revenue.daily.view', 'role': 'STAFF'},
);
```

---

## 8. Security Considerations

- [x] **Defense in Depth**: Permission checks at UI, Service, and DAO layers
- [x] **Fail-Safe Default**: If permission check fails or errors, deny access
- [x] **Owner Protection**: Owner permissions cannot be modified by anyone
- [x] **Sensitive Data Hiding**: Revenue data hidden at query level (DAO filters by scope)
- [x] **Audit Trail**: All permission changes logged with actor, timestamp, old/new values
- [x] **Session Validation**: Permission checks require valid user session
- [x] **SQL Injection Prevention**: Drift parameterized queries prevent SQL injection
- [x] **Cache Invalidation**: Permission cache cleared immediately on updates

---

## 9. Test Plan

### 9.1 Test Scope

| Type | Target | Tool |
|------|--------|------|
| Unit Test | PermissionService logic | Flutter Test |
| Unit Test | RolePermissionService | Flutter Test |
| Integration Test | Permission + Scope validation | Flutter Test |
| UI Test | PermissionGateWidget rendering | Widget Test |
| Manual Test | RBAC toggle behavior | Manual QA |

### 9.2 Key Test Cases

**Unit Tests (PermissionService):**
- [ ] RBAC disabled → all permissions granted
- [ ] RBAC enabled + OWNER role → all permissions granted
- [ ] RBAC enabled + STAFF role + revenue permission → denied
- [ ] RBAC enabled + STORE_MANAGER + OWN_STORE scope + own store → granted
- [ ] RBAC enabled + STORE_MANAGER + OWN_STORE scope + different store → denied
- [ ] RBAC enabled + AREA_MANAGER + ASSIGNED_STORES scope + assigned store → granted
- [ ] RBAC enabled + AREA_MANAGER + ASSIGNED_STORES scope + unassigned store → denied

**Integration Tests (Permission + Scope):**
- [ ] Create AREA_MANAGER with 2 assigned stores → can access both
- [ ] AREA_MANAGER tries to access unassigned store → denied
- [ ] Update role from STAFF to STORE_MANAGER → permissions updated
- [ ] Remove store assignment from AREA_MANAGER → access revoked

**UI Tests (PermissionGateWidget):**
- [ ] User with permission → child widget visible
- [ ] User without permission → fallback widget visible
- [ ] RBAC disabled → all widgets visible

**Manual Tests:**
- [ ] Toggle RBAC on → staff can no longer see revenue
- [ ] Toggle RBAC off → staff can see revenue again
- [ ] Owner customizes STAFF permissions → changes apply immediately
- [ ] Check audit log records permission changes

---

## 10. Clean Architecture

### 10.1 Layer Structure

| Layer | Responsibility | Location |
|-------|---------------|----------|
| **Presentation** | UI components, widgets, screens | `lib/features/auth/presentation/`, `lib/core/widgets/` |
| **Application** | Riverpod providers, state management | `lib/features/auth/providers/` |
| **Domain** | Services, business logic, enums | `lib/features/auth/domain/services/`, `lib/features/auth/domain/` |
| **Infrastructure** | DAOs, database access | `lib/database/daos/`, `lib/database/tables/` |

### 10.2 Dependency Rules

```
┌─────────────────────────────────────────────────────────────┐
│                    Dependency Direction                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Presentation ──→ Application ──→ Domain ←── Infrastructure│
│   (Widgets)        (Providers)     (Services)   (DAOs)      │
│                          │                                  │
│                          └──→ Infrastructure                │
│                                                             │
│   Rule: Inner layers MUST NOT depend on outer layers        │
│         Domain services are pure business logic             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 10.3 This Feature's Layer Assignment

| Component | Layer | Location |
|-----------|-------|----------|
| PermissionGateWidget | Presentation | `lib/core/widgets/permission_gate_widget.dart` |
| SecuritySettingsScreen | Presentation | `lib/features/settings/presentation/screens/security_settings_screen.dart` |
| RolesPermissionsScreen | Presentation | `lib/features/settings/presentation/screens/roles_permissions_screen.dart` |
| PermissionProvider | Application | `lib/features/auth/providers/permission_provider.dart` |
| PermissionService | Domain | `lib/features/auth/domain/services/permission_service.dart` |
| RolePermissionService | Domain | `lib/features/auth/domain/services/role_permission_service.dart` |
| AuditLogService | Domain | `lib/features/auth/domain/services/audit_log_service.dart` |
| EmployeeRole enum | Domain | `lib/features/auth/domain/employee_role.dart` |
| StoreScope enum | Domain | `lib/features/auth/domain/store_scope.dart` |
| PermissionModules | Domain | `lib/features/auth/domain/permission_modules.dart` |
| PermissionsDao | Infrastructure | `lib/database/daos/permissions_dao.dart` |
| RolePermissionsDao | Infrastructure | `lib/database/daos/role_permissions_dao.dart` |
| UserRolesDao | Infrastructure | `lib/database/daos/user_roles_dao.dart` |
| StoreAssignmentsDao | Infrastructure | `lib/database/daos/store_assignments_dao.dart` |
| AuditLogsDao | Infrastructure | `lib/database/daos/audit_logs_dao.dart` |

---

## 11. Coding Conventions

### 11.1 Naming Conventions

| Target | Rule | Example |
|--------|------|---------|
| Services | PascalCase + "Service" | `PermissionService`, `RolePermissionService` |
| DAOs | PascalCase + "Dao" | `PermissionsDao`, `RolePermissionsDao` |
| Enums | UPPER_SNAKE_CASE | `EmployeeRole.AREA_MANAGER` |
| Tables | PascalCase (plural) | `Permissions`, `RolePermissions` |
| Providers | camelCase + "Provider" | `permissionServiceProvider` |
| Constants | UPPER_SNAKE_CASE | `REVENUE_DAILY_VIEW` |

### 11.2 Permission Naming Convention

**Format**: `module.action` or `module.submodule.action`

**Rules**:
- Module: lowercase, singular (e.g., `pos`, `revenue`, `inventory`)
- Action: lowercase, verb or noun (e.g., `view`, `edit`, `create`)
- Separator: period (`.`)

**Examples**:
```dart
✅ Good:
  pos.open
  revenue.daily.view
  inventory.adjust
  settings.tax.edit

❌ Bad:
  POS_OPEN              // Wrong case
  revenue_daily_view    // Wrong separator
  dailyRevenueView      // Not module.action format
  view-revenue          // Wrong order
```

### 11.3 Database Conventions

**Table Names**: PascalCase, plural
```dart
✅ Permissions, RolePermissions, UserRoles
❌ permission, role_permission, user_role
```

**Column Names**: camelCase
```dart
✅ isEnabled, permissionId, updatedAt
❌ is_enabled, permission_id, updated_at
```

### 11.4 This Feature's Applied Conventions

| Item | Convention Applied |
|------|-------------------|
| Service naming | `PermissionService`, `RolePermissionService`, `AuditLogService` |
| DAO naming | `PermissionsDao`, `RolePermissionsDao`, `UserRolesDao` |
| Enum naming | `EmployeeRole.OWNER`, `StoreScope.ALL_STORES` |
| Permission naming | `module.action` format (e.g., `revenue.daily.view`) |
| State management | Riverpod providers with `Provider`, `FutureProvider` |
| Error handling | Custom `PermissionError` exception class |

---

## 12. Implementation Guide

### 12.1 File Structure

```
lib/
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── employee_role.dart (NEW - enum)
│   │   │   ├── store_scope.dart (NEW - enum)
│   │   │   ├── permission_modules.dart (NEW - constants)
│   │   │   ├── permission_error.dart (NEW - exception)
│   │   │   └── services/
│   │   │       ├── permission_service.dart (NEW)
│   │   │       ├── role_permission_service.dart (NEW)
│   │   │       └── audit_log_service.dart (NEW)
│   │   ├── data/
│   │   │   └── (existing DAOs remain)
│   │   ├── providers/
│   │   │   ├── permission_provider.dart (UPDATE)
│   │   │   ├── rbac_setting_provider.dart (NEW)
│   │   │   └── role_permissions_provider.dart (NEW)
│   │   └── presentation/
│   │       └── widgets/
│   │           └── permission_gate_widget.dart (UPDATE or NEW)
│   └── settings/
│       └── presentation/
│           └── screens/
│               ├── security_settings_screen.dart (NEW)
│               └── roles_permissions_screen.dart (NEW)
├── database/
│   ├── tables/
│   │   ├── permissions.dart (NEW)
│   │   ├── role_permissions.dart (NEW)
│   │   ├── user_roles.dart (NEW)
│   │   ├── store_assignments.dart (NEW)
│   │   ├── audit_logs.dart (UPDATE - already exists)
│   │   ├── employees.dart (UPDATE - add RBAC fields)
│   │   └── system_settings.dart (UPDATE - add rbac_enabled)
│   ├── daos/
│   │   ├── permissions_dao.dart (NEW)
│   │   ├── role_permissions_dao.dart (NEW)
│   │   ├── user_roles_dao.dart (NEW)
│   │   ├── store_assignments_dao.dart (NEW)
│   │   └── audit_logs_dao.dart (UPDATE)
│   └── app_database.dart (UPDATE - add new tables/DAOs)
└── core/
    └── widgets/
        └── permission_gate_widget.dart (NEW)
```

### 12.2 Implementation Order

#### **Phase 1: Database Schema (Week 1)**
1. [ ] Create Drift table definitions
   - [ ] `permissions.dart`
   - [ ] `role_permissions.dart`
   - [ ] `user_roles.dart`
   - [ ] `store_assignments.dart`
   - [ ] Update `employees.dart` (add `defaultRole`, `storeScope`, `primaryStoreId`)
   - [ ] Update `system_settings.dart` (add `rbac_enabled` seed data)
2. [ ] Create DAOs
   - [ ] `permissions_dao.dart`
   - [ ] `role_permissions_dao.dart`
   - [ ] `user_roles_dao.dart`
   - [ ] `store_assignments_dao.dart`
3. [ ] Update `app_database.dart`
   - [ ] Add new tables to `@DriftDatabase`
   - [ ] Add new DAOs
   - [ ] Increment `schemaVersion`
   - [ ] Write migration script (`onUpgrade`)
4. [ ] Run `dart run build_runner build --delete-conflicting-outputs`
5. [ ] Create seed data script
   - [ ] Seed all permissions (POS, Orders, Inventory, Revenue, Staff, Settings)
   - [ ] Seed default role templates (OWNER, AREA_MANAGER, STORE_MANAGER, STAFF)
   - [ ] Insert `rbac_enabled = false` into `system_settings`

#### **Phase 2: Domain Layer (Week 1)**
6. [ ] Create enums and constants
   - [ ] `employee_role.dart` (OWNER, AREA_MANAGER, STORE_MANAGER, STAFF)
   - [ ] `store_scope.dart` (ALL_STORES, ASSIGNED_STORES, OWN_STORE)
   - [ ] `permission_modules.dart` (all permission constants)
   - [ ] `permission_error.dart` (custom exception)
7. [ ] Implement services
   - [ ] `permission_service.dart` (core permission logic)
   - [ ] `role_permission_service.dart` (permission management for Owner)
   - [ ] `audit_log_service.dart` (audit logging)
8. [ ] Write unit tests for services

#### **Phase 3: Application Layer (Week 2)**
9. [ ] Create Riverpod providers
   - [ ] `permission_provider.dart` (permission checks)
   - [ ] `rbac_setting_provider.dart` (RBAC toggle state)
   - [ ] `role_permissions_provider.dart` (role permission management)
10. [ ] Write unit tests for providers

#### **Phase 4: UI Components (Week 2)**
11. [ ] Create `PermissionGateWidget`
12. [ ] Create Settings screens
   - [ ] `security_settings_screen.dart` (RBAC toggle)
   - [ ] `roles_permissions_screen.dart` (permission management UI)
13. [ ] Write widget tests

#### **Phase 5: Feature Integration (Week 3)**
14. [ ] Update existing features to check permissions
   - [ ] Dashboard → `revenue.dashboard.view`
   - [ ] Sales Reports → `revenue.daily.view`, `revenue.weekly.view`, `revenue.monthly.view`
   - [ ] Daily Closing → `revenue.daily.view` + scope validation
   - [ ] Inventory → `inventory.edit`, `inventory.adjust`
   - [ ] Employee Management → `staff.manage`
   - [ ] Settings screens → `settings.*` permissions
15. [ ] Add navigation guards (hide menu items based on permissions)
16. [ ] Add action button guards (disable/hide buttons based on permissions)

#### **Phase 6: Testing & Migration (Week 3)**
17. [ ] Write integration tests
   - [ ] Permission + Scope validation
   - [ ] RBAC toggle behavior
   - [ ] Role permission updates
18. [ ] Manual testing
   - [ ] Test RBAC on/off toggle
   - [ ] Test each role's access
   - [ ] Test store scope validation
   - [ ] Test permission customization
   - [ ] Test audit logging
19. [ ] Create production migration script
   - [ ] Backup existing data
   - [ ] Map old roles to new roles
   - [ ] Assign default permissions
   - [ ] Set default store scopes
20. [ ] Deploy and monitor

---

## 13. Migration Strategy

### 13.1 Existing Data Migration

**Current State**:
- `employees.role`: `'MANAGER' | 'CASHIER' | 'KITCHEN'`

**Migration Mapping**:
```dart
Map<String, String> roleMigrationMap = {
  'MANAGER': 'OWNER',        // Promote all managers to owners
  'CASHIER': 'STAFF',        // Map cashiers to staff
  'KITCHEN': 'STAFF',        // Map kitchen to staff
};

Map<String, String> scopeMigrationMap = {
  'MANAGER': 'ALL_STORES',
  'CASHIER': 'OWN_STORE',
  'KITCHEN': 'OWN_STORE',
};
```

**Migration SQL**:
```sql
-- 1. Add new columns to employees table
ALTER TABLE employees ADD COLUMN default_role TEXT DEFAULT 'STAFF';
ALTER TABLE employees ADD COLUMN store_scope TEXT DEFAULT 'OWN_STORE';
ALTER TABLE employees ADD COLUMN primary_store_id TEXT;

-- 2. Migrate existing roles
UPDATE employees SET default_role = 'OWNER', store_scope = 'ALL_STORES' WHERE role = 'MANAGER';
UPDATE employees SET default_role = 'STAFF', store_scope = 'OWN_STORE' WHERE role = 'CASHIER';
UPDATE employees SET default_role = 'STAFF', store_scope = 'OWN_STORE' WHERE role = 'KITCHEN';

-- 3. Insert RBAC setting (disabled by default for backward compatibility)
INSERT INTO system_settings (key, value) VALUES ('rbac_enabled', 'false');

-- 4. Create user_roles entries for all employees
INSERT INTO user_roles (id, user_id, role, scope, assigned_at, assigned_by)
SELECT
  lower(hex(randomblob(16))) as id,
  id as user_id,
  default_role as role,
  store_scope as scope,
  CURRENT_TIMESTAMP as assigned_at,
  1 as assigned_by  -- Assume first user is admin
FROM employees;
```

### 13.2 Rollback Plan

If RBAC causes issues:
1. **Immediate**: Set `rbac_enabled` to `false` in Settings
2. **Database Rollback**: Restore from backup before migration
3. **Code Rollback**: Revert to previous version

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-02-12 | Initial design draft | Claude AI & JINLee |

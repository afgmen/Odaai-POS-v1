# Role-Based Access Control (RBAC) Planning Document

> **Summary**: Implement hierarchical role-based permissions to control access to sensitive features (revenue data, settings, etc.) based on user role level
>
> **Project**: Oda POS
> **Version**: 1.0.0
> **Author**: Claude AI & JINLee
> **Date**: 2026-02-11
> **Status**: Draft

---

## 1. Overview

### 1.1 Purpose

To implement a **granular, permission-based RBAC system** with fixed roles and customizable permissions, allowing the Owner to:
- **Enable/disable RBAC system** via Settings screen
- **Customize permissions per role** using permission toggles (when RBAC enabled)
- Control access to sensitive data (revenue, reports, settings) using explicit permissions
- Support multi-store operations with scope validation (OWN_STORE, ASSIGNED_STORES, ALL_STORES)
- Maintain audit logs for all permission changes
- Use default role templates that can be customized

**Core Design Principle**: Fixed Roles + Permission Toggles + Scope Validation + Audit Logging

### 1.2 Background

**Current Situation:**
- Single role system exists (Admin, Manager, Cashier, Kitchen)
- No hierarchical role structure
- All roles can potentially see revenue data
- No multi-store support for area managers

**Problem:**
- Staff members can see daily/weekly/monthly revenue
- No clear separation between store-level and area-level management
- No granular permission control (all-or-nothing access)
- Security risk with sensitive financial information
- Cannot support franchise/multi-store operations
- No audit trail for permission changes
- Inflexible role system cannot adapt to different business needs

### 1.3 Related Documents

- Current Employee System: `lib/features/employees/`
- Current Auth System: `lib/features/auth/`
- Database Schema: `lib/database/app_database.dart`

---

## 2. Scope

### 2.1 In Scope

- [ ] **RBAC Toggle Setting**: Owner can enable/disable RBAC system via Settings screen
- [ ] **Four fixed roles**: OWNER, AREA_MANAGER, STORE_MANAGER, STAFF (cannot be deleted)
- [ ] **Granular permission system**: `module.action` format (e.g., `revenue.daily.view`, `inventory.adjust`)
- [ ] **Permission modules**: POS, Orders, Inventory, Revenue, Staff, Settings
- [ ] **Default role templates**: Pre-configured permission sets for each role (customizable by Owner)
- [ ] **Owner permission customization**: Toggle permissions for AREA_MANAGER, STORE_MANAGER, STAFF
- [ ] **Store scope model**: OWN_STORE, ASSIGNED_STORES, ALL_STORES
- [ ] **Permission + Scope validation**: Check both permission AND scope for access control
- [ ] **Audit logging**: Record all permission changes with actor, timestamp, and details
- [ ] **Settings UI**: Roles & Permissions screen with module-grouped toggles
- [ ] **Database schema**: `roles`, `permissions`, `role_permissions`, `user_roles`, `store_assignments`, `audit_logs`
- [ ] **Migration script**: Convert existing employee roles to new system
- [ ] **Backward compatibility**: When RBAC disabled, all roles work as before

### 2.2 Out of Scope

- Custom role creation (fixed 4 roles only)
- Fine-grained permission customization per user
- Time-based access control (shift-based permissions)
- Audit logging for permission changes (future enhancement)
- Two-factor authentication (separate feature)
- External authentication providers (OAuth, SAML)

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | **Owner can enable/disable RBAC via Settings screen** | High | Pending |
| FR-02 | When RBAC disabled, all roles have full access (backward compatible) | High | Pending |
| FR-03 | When RBAC enabled, apply role-based restrictions | High | Pending |
| FR-04 | Define 4-tier role hierarchy (Owner, Area Manager, Store Manager, Staff) | High | Pending |
| FR-05 | Owner role has full system access regardless of RBAC setting | High | Pending |
| FR-06 | Area Manager can view/manage multiple stores but cannot modify system settings (when RBAC enabled) | High | Pending |
| FR-07 | Store Manager can view/manage single store including revenue data (when RBAC enabled) | High | Pending |
| FR-08 | Staff role cannot view revenue, reports, or financial dashboards (when RBAC enabled) | High | Pending |
| FR-09 | Hide navigation items based on role permissions (when RBAC enabled) | High | Pending |
| FR-10 | Disable/hide action buttons based on role permissions (when RBAC enabled) | Medium | Pending |
| FR-11 | Show permission denied message when accessing restricted features | Medium | Pending |
| FR-12 | Settings screen shows clear RBAC toggle with description | High | Pending |
| FR-13 | RBAC setting persists in database (system_settings table) | High | Pending |
| FR-14 | Migration script to convert existing employees to new role system | High | Pending |
| FR-15 | Support role-based filtering in Daily Closing screen | High | Pending |
| FR-16 | Support role-based filtering in Sales Reports screen | High | Pending |
| FR-17 | Support role-based filtering in Dashboard analytics | High | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Performance | Permission checks < 10ms | Benchmark tests |
| Security | Sensitive data hidden at API/DB level, not just UI | Code review + penetration testing |
| Usability | Clear visual indication when features are restricted | User testing |
| Maintainability | Permission rules centralized in single config file | Code review |

---

## 4. RBAC Toggle System

### 4.1 Configuration Setting

**Location**: Settings Screen → Security/Access Control Section

**Setting Details:**
- **Name**: "Enable Role-Based Access Control"
- **Type**: Boolean toggle (ON/OFF)
- **Default**: OFF (disabled for backward compatibility)
- **Who can change**: Owner only
- **Storage**: `system_settings` table with key `rbac_enabled`

### 4.2 Behavior

**When RBAC is DISABLED (Default):**
```
┌─────────────────────────────────────────────────────┐
│ All employees have full access                      │
│ - All navigation items visible                      │
│ - All features accessible                           │
│ - No permission checks performed                    │
│ - Backward compatible with existing setup           │
└─────────────────────────────────────────────────────┘
```

**When RBAC is ENABLED:**
```
┌─────────────────────────────────────────────────────┐
│ Role-based restrictions applied                     │
│ - Navigation filtered by role                       │
│ - Sensitive data hidden from Staff                  │
│ - Permission checks on every screen                 │
│ - Owner can still access everything                 │
└─────────────────────────────────────────────────────┘
```

### 4.3 Settings UI Design

**Settings Screen Section:**
```
┌──────────────────────────────────────────────────┐
│ Security & Access Control                        │
├──────────────────────────────────────────────────┤
│                                                  │
│  Role-Based Access Control              [ OFF ] │
│                                                  │
│  When enabled, employees will only see          │
│  features they have permission to access.       │
│                                                  │
│  - Staff cannot view financial reports          │
│  - Only managers can access settings            │
│  - Area managers can manage multiple stores     │
│                                                  │
│  ⚠️  Changes take effect immediately             │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## 5. Permission-Based RBAC Design

### 5.1 Fixed Roles

**Four roles that cannot be deleted:**

```dart
enum EmployeeRole {
  OWNER,         // All permissions, ALL_STORES scope
  AREA_MANAGER,  // Customizable permissions, ASSIGNED_STORES scope
  STORE_MANAGER, // Customizable permissions, OWN_STORE scope
  STAFF          // Customizable permissions, OWN_STORE scope
}
```

**Key Principle**: Roles are templates, not permission containers. Permissions are stored separately and mapped to roles.

### 5.2 Permission Naming Convention

**Format**: `module.action`

**Examples**:
```
pos.open
order.create
order.cancel
inventory.view
inventory.adjust
revenue.daily.view
revenue.monthly.view
staff.manage
settings.edit
```

### 5.3 Core Permission Modules

#### **POS Module**
```
pos.open              - Open POS terminal
pos.refund            - Process refunds
pos.discount          - Apply discounts
pos.price.override    - Override prices
pos.cash.drawer.open  - Open cash drawer manually
```

#### **Orders Module**
```
order.create   - Create orders
order.cancel   - Cancel orders
order.view     - View order history
```

#### **Inventory Module**
```
inventory.view      - View inventory levels
inventory.edit      - Edit product information
inventory.adjust    - Adjust stock levels
inventory.writeoff  - Write off damaged/lost items
```

#### **Revenue Module** (Sensitive)
```
revenue.dashboard.view   - View revenue dashboard
revenue.daily.view       - View daily revenue
revenue.weekly.view      - View weekly revenue
revenue.monthly.view     - View monthly revenue
revenue.multistore.view  - View multi-store revenue
revenue.export           - Export revenue reports
revenue.pnl.view         - View P&L statements
```

#### **Staff Module**
```
staff.view     - View staff list
staff.manage   - Add/edit/delete staff
staff.role.assign  - Assign roles to staff
```

#### **Settings Module**
```
settings.store.edit       - Edit store settings
settings.tax.edit         - Edit tax settings
settings.payment.edit     - Edit payment settings
settings.integration.edit - Edit integration settings
```

### 5.4 Default Role Permission Templates

**Applied only during initialization. Owner may customize later.**

#### **OWNER** (Scope: ALL_STORES)
- ✅ All permissions enabled
- ❌ Cannot be modified

#### **AREA_MANAGER** (Scope: ASSIGNED_STORES)
```
✅ revenue.dashboard.view
✅ revenue.daily.view
✅ revenue.weekly.view
✅ revenue.monthly.view
✅ revenue.multistore.view  // Only for assigned stores
✅ inventory.view
✅ inventory.edit
✅ staff.view
✅ staff.manage
✅ pos.refund
✅ pos.discount
❌ settings.* (all settings disabled)
```

#### **STORE_MANAGER** (Scope: OWN_STORE)
```
✅ pos.open
✅ pos.refund
✅ pos.discount
✅ order.create
✅ order.cancel
✅ inventory.view
✅ inventory.edit
✅ revenue.dashboard.view
✅ revenue.daily.view
❌ revenue.weekly.view
❌ revenue.monthly.view
❌ settings.*
```

#### **STAFF** (Scope: OWN_STORE)
```
✅ pos.open
✅ order.create
❌ All revenue.* permissions
❌ All settings.* permissions
❌ inventory.edit
❌ staff.manage
```

### 5.5 Store Scope Model

Each user must have a store scope that works **in conjunction with permissions**:

```dart
enum StoreScope {
  ALL_STORES,       // OWNER only
  ASSIGNED_STORES,  // AREA_MANAGER
  OWN_STORE         // STORE_MANAGER, STAFF
}
```

**Permission validation requires both**:
1. Does user have the permission? (e.g., `revenue.daily.view`)
2. Is the data within user's scope? (e.g., OWN_STORE)

**Example**:
- STORE_MANAGER with `revenue.daily.view` can only see their own store's revenue
- AREA_MANAGER with `revenue.daily.view` can see assigned stores' revenue
- OWNER with `revenue.daily.view` can see all stores' revenue

### 5.6 Owner Permission Customization

**Owner can toggle permissions for**:
- AREA_MANAGER
- STORE_MANAGER
- STAFF

**Owner permissions cannot be modified** (always all permissions).

**UI Location**: Settings → Roles & Permissions

**Grouped by module**:
```
┌─────────────────────────────────────────────────┐
│ POS Permissions                                 │
├─────────────────────────────────────────────────┤
│ [ ] pos.refund           Process Refunds        │
│ [ ] pos.discount         Apply Discounts        │
│ [ ] pos.price.override   Override Prices        │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ Revenue Permissions (Sensitive)                 │
├─────────────────────────────────────────────────┤
│ [ ] revenue.daily.view    View Daily Revenue    │
│ [ ] revenue.weekly.view   View Weekly Revenue   │
│ [ ] revenue.monthly.view  View Monthly Revenue  │
└─────────────────────────────────────────────────┘
```

### 5.7 Security Rules

**The system must enforce**:
1. STAFF cannot access revenue data (explicit permission required)
2. STAFF cannot manage roles
3. STAFF cannot modify inventory (default)
4. Revenue permissions must be explicit (no implicit grants)
5. OWNER permission changes must be audited
6. Scope must be validated alongside permissions

### 5.8 Audit Logging Requirement

**Every permission change must be recorded** in the `audit_logs` table.

**Log Entry Format**:
```dart
{
  event_type: "ROLE_PERMISSION_UPDATED",
  actor_id: "owner-user-id",
  actor_name: "John Doe (OWNER)",
  target_role: "STORE_MANAGER",
  permission: "revenue.monthly.view",
  old_value: false,
  new_value: true,
  timestamp: "2026-02-11T15:30:00Z",
  ip_address: "192.168.1.100"  // Optional
}
```

**Audit Events to Log**:
- `ROLE_PERMISSION_UPDATED` - Permission toggled on/off
- `USER_ROLE_ASSIGNED` - Role assigned to user
- `USER_ROLE_CHANGED` - User's role changed
- `STORE_ASSIGNMENT_ADDED` - Store assigned to AREA_MANAGER
- `STORE_ASSIGNMENT_REMOVED` - Store removed from AREA_MANAGER
- `RBAC_SYSTEM_ENABLED` - RBAC system turned on
- `RBAC_SYSTEM_DISABLED` - RBAC system turned off

**Audit Log UI**: Settings → Audit Logs (Owner only)

---

## 6. Success Criteria

### 6.1 Definition of Done

- [ ] RBAC toggle setting added to Settings screen (Owner only)
- [ ] RBAC setting stored in `system_settings` table
- [ ] When RBAC disabled, all employees have full access (backward compatible)
- [ ] When RBAC enabled, role-based restrictions apply
- [ ] Database schema updated with role hierarchy and permissions
- [ ] Permission provider implemented in Riverpod (checks RBAC toggle)
- [ ] All navigation items respect role permissions (when RBAC enabled)
- [ ] All screens check permissions before displaying sensitive data (when RBAC enabled)
- [ ] Migration script successfully converts existing employees
- [ ] Unit tests for permission checks passing
- [ ] Manual testing confirms toggle works correctly
- [ ] Manual testing confirms Staff cannot see revenue when RBAC enabled
- [ ] Documentation updated with role descriptions and RBAC toggle

### 5.2 Quality Criteria

- [ ] Zero security vulnerabilities (staff bypassing restrictions)
- [ ] Permission checks are centralized (no hardcoded role checks)
- [ ] UI clearly indicates when features are restricted
- [ ] No performance degradation from permission checks
- [ ] Build succeeds with zero errors

---

## 7. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Breaking existing employee system | High | Medium | Create migration script, test thoroughly before deployment |
| Staff finding ways to bypass restrictions | High | Low | Implement checks at multiple layers (UI, Provider, DB) |
| Performance impact from permission checks | Medium | Low | Cache permissions in memory, use efficient checks |
| Confusion about which features are restricted | Medium | Medium | Show clear "Permission Denied" messages with explanations |
| Migration data loss | High | Low | Backup database before migration, test on copy first |

---

## 8. Architecture Considerations

### 9.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| **Starter** | Simple structure (`components/`, `lib/`, `types/`) | Static sites, portfolios, landing pages | ☐ |
| **Dynamic** | Feature-based modules, services layer | Web apps with backend, SaaS MVPs | ☑ |
| **Enterprise** | Strict layer separation, DI, microservices | High-traffic systems, complex architectures | ☐ |

**Selected: Dynamic** - Current Oda POS architecture uses feature-based organization with services layer.

### 9.2 Key Architectural Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| Framework | Flutter Desktop | Flutter | Already using Flutter |
| State Management | Riverpod / Provider / Bloc | Riverpod | Already using Riverpod throughout app |
| Database | Drift (SQLite) | Drift | Already using Drift for local DB |
| Permission Storage | In-memory / Database | Database | Persistent, secure, supports multi-store |
| Permission Check Pattern | Guard Functions / Provider | Provider | Consistent with existing architecture |

### 9.3 Clean Architecture Approach

```
Selected Level: Dynamic

Folder Structure:
src/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   │   └── services/
│   │   │       └── permission_service.dart (NEW)
│   │   └── providers/
│   │       └── permission_provider.dart (NEW)
│   ├── employees/
│   │   ├── data/
│   │   │   └── employee_dao.dart (UPDATE: role hierarchy)
│   │   └── domain/
│   │       └── enums/
│   │           └── employee_role.dart (UPDATE: new roles)
│   └── ... (other features check permissions)
├── database/
│   ├── app_database.dart (UPDATE: permissions table)
│   └── tables/
│       ├── permissions.dart (NEW)
│       └── employee_stores.dart (NEW: junction table)
└── core/
    └── widgets/
        └── permission_guard.dart (NEW: UI guard widget)
```

---

## 9. Convention Prerequisites

### 9.1 Existing Project Conventions

Check which conventions already exist in the project:

- [x] `CLAUDE.md` has coding conventions section
- [ ] `docs/01-plan/conventions.md` exists
- [ ] `CONVENTIONS.md` exists at project root
- [x] Dart analysis configuration (`analysis_options.yaml`)
- [ ] Project-specific linting rules

### 9.2 Conventions to Define/Verify

| Category | Current State | To Define | Priority |
|----------|---------------|-----------|:--------:|
| **Naming** | Exists (Dart conventions) | Permission naming pattern | High |
| **Folder structure** | Exists (feature-based) | Permission files location | High |
| **Enum naming** | Exists | Role enum values | High |
| **Error handling** | Exists | Permission denied errors | Medium |
| **Database naming** | Exists | Permission tables/columns | High |

### 9.3 Database Schema Design

**New Tables**:

#### **`permissions`** - Master permission list
```dart
{
  id: UUID (PK),
  name: String,            // e.g., "revenue.daily.view"
  module: String,          // e.g., "revenue"
  description: String,     // e.g., "View daily revenue reports"
  is_sensitive: Boolean,   // true for revenue/settings
  created_at: DateTime
}
```

#### **`role_permissions`** - Role-to-permission mapping
```dart
{
  id: UUID (PK),
  role: String,           // OWNER, AREA_MANAGER, STORE_MANAGER, STAFF
  permission_id: UUID (FK → permissions.id),
  is_enabled: Boolean,    // true/false
  updated_at: DateTime,
  updated_by: UUID (FK → employees.id)
}
```

#### **`user_roles`** - User-to-role assignment
```dart
{
  id: UUID (PK),
  user_id: UUID (FK → employees.id),
  role: String,           // OWNER, AREA_MANAGER, STORE_MANAGER, STAFF
  scope: String,          // ALL_STORES, ASSIGNED_STORES, OWN_STORE
  assigned_at: DateTime,
  assigned_by: UUID (FK → employees.id)
}
```

#### **`store_assignments`** - Area Manager store assignments
```dart
{
  id: UUID (PK),
  user_id: UUID (FK → employees.id),
  store_id: UUID (FK → stores.id),
  assigned_at: DateTime,
  assigned_by: UUID (FK → employees.id)
}
```

#### **`audit_logs`** - Permission change audit trail
```dart
{
  id: UUID (PK),
  event_type: String,     // ROLE_PERMISSION_UPDATED, USER_ROLE_ASSIGNED, etc.
  actor_id: UUID (FK → employees.id),
  actor_name: String,     // Denormalized for history
  target_role: String,    // Role being modified
  permission: String,     // Permission being changed
  old_value: String/JSON, // Previous value
  new_value: String/JSON, // New value
  timestamp: DateTime,
  ip_address: String (nullable)
}
```

**Updated Tables**:

#### **`employees`** (existing)
```dart
// Add new columns:
default_role: String,     // OWNER, AREA_MANAGER, STORE_MANAGER, STAFF
store_scope: String,      // ALL_STORES, ASSIGNED_STORES, OWN_STORE
primary_store_id: UUID (FK → stores.id, nullable)
```

#### **`system_settings`** (existing)
```dart
// Add new setting:
key: "rbac_enabled"
value: "false"  // Boolean string
```

---

## 10. Implementation Plan

### 10.1 Phase 1: Database Schema & Seed Data

1. Add RBAC toggle to `system_settings` table (key: `rbac_enabled`, default: `false`)
2. Create `permissions` table with master permission list
3. Create `role_permissions` table (role-to-permission mapping)
4. Create `user_roles` table (user-to-role assignment)
5. Create `store_assignments` table (AREA_MANAGER store assignments)
6. Create `audit_logs` table (permission change tracking)
7. Update `employees` table (add `default_role`, `store_scope`, `primary_store_id`)
8. **Seed default permissions** (all POS, Orders, Inventory, Revenue, Staff, Settings permissions)
9. **Seed default role templates** (Owner, Area Manager, Store Manager, Staff)
10. Create migration script

### 10.2 Phase 2: Permission Service

1. Create `PermissionService` class with methods:
   - `hasPermission(userId, permission, storeId?)` - Check permission + scope
   - `getUserPermissions(userId)` - Get all user permissions
   - `getRolePermissions(role)` - Get all role permissions
   - `isRBACEnabled()` - Check if RBAC is enabled
   - `validateScope(userId, storeId)` - Validate store scope
2. Create `RolePermissionService` class (for Owner to manage role permissions)
3. Create `AuditLogService` class (record permission changes)
4. Create Riverpod providers:
   - `permissionServiceProvider`
   - `rolePermissionServiceProvider`
   - `auditLogServiceProvider`
   - `rbacSettingProvider` (reactive RBAC toggle state)
5. Add in-memory permission caching for performance

### 10.3 Phase 3: UI Guards

1. Create `PermissionGuard` widget
2. Update navigation to respect permissions
3. Hide/disable buttons based on permissions
4. Add "Permission Denied" dialogs

### 10.4 Phase 4: Settings UI - Roles & Permissions Screen

1. **Add RBAC System Toggle**
   - Settings → Security → RBAC toggle (Owner only)
   - Clear description of RBAC behavior
   - Immediate effect when toggled

2. **Build Roles & Permissions Management Screen** (Owner only)
   - Tab for each role (AREA_MANAGER, STORE_MANAGER, STAFF)
   - Permission toggles grouped by module:
     * POS Permissions
     * Order Permissions
     * Inventory Permissions
     * Revenue Permissions (clearly marked as sensitive)
     * Staff Permissions
     * Settings Permissions
   - Save button → updates `role_permissions` table → creates audit log

3. **Build Audit Log Viewer** (Owner only)
   - Settings → Audit Logs
   - Filterable by event type, date range, actor
   - Export to CSV

### 10.5 Phase 5: Feature Integration

1. Update Dashboard to check `revenue.dashboard.view` permission
2. Update Sales Reports to check `revenue.daily.view`, `revenue.weekly.view`, etc.
3. Update Daily Closing to check `revenue.daily.view` + scope
4. Update Inventory screens to check `inventory.edit`, `inventory.adjust`
5. Update Employee Management to check `staff.manage`
6. Update Settings screens to check `settings.*` permissions
7. Add scope validation for multi-store data access

### 10.6 Phase 6: Testing & Migration

1. **Write unit tests**:
   - Permission check logic (with/without RBAC enabled)
   - Scope validation
   - Permission + scope combination tests
   - Audit logging
2. **Manual testing per role**:
   - Test each permission toggle
   - Test scope restrictions
   - Test RBAC on/off behavior
3. **Create production migration script**:
   - Backup existing employee data
   - Map old roles to new roles
   - Assign default permissions based on role
   - Set default store scope
4. Deploy and monitor audit logs

---

## 11. Next Steps

1. [ ] Review and approve this plan
2. [ ] Write design document (`role-based-access-control.design.md`)
3. [ ] Create database migration plan
4. [ ] Start implementation (Phase 1: Database Schema)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-02-11 | Initial draft with 4-tier role hierarchy | Claude AI & JINLee |

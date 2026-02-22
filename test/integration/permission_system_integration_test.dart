import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';
import 'package:oda_pos/features/auth/domain/services/permission_service.dart';

// ---------------------------------------------------------------------------
// Section D: Permission system integration tests.
//
// Uses an in-memory DB that goes through full onCreate (seeding RBAC data).
//
// Tests cover:
//   D-12  STAFF cannot access revenue (report) menu
//   D-13  STAFF cannot apply discounts
//   D-14  OWNER has full access to all permissions
//
// Additional edge-case tests:
//   D-15  RBAC disabled → everyone has all access
//   D-16  STORE_MANAGER has revenue.daily.view but not revenue.multistore.view
//   D-17  Unknown user returns false when RBAC is enabled
//   D-18  isOwner() helper returns correct result
// ---------------------------------------------------------------------------

AppDatabase _openDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Enable RBAC in the in-memory database.
Future<void> _enableRbac(AppDatabase db) async {
  await db.customStatement(
    "INSERT OR REPLACE INTO system_settings (key, value, updated_at) "
    "VALUES ('rbac_enabled', 'true', CAST(strftime('%s', 'now') AS INTEGER))",
  );
}

/// Insert an employee and assign a role. Returns the employee ID.
Future<int> _insertEmployeeWithRole(
  AppDatabase db, {
  required String name,
  required String role,
  String scope = 'OWN_STORE',
}) async {
  final now = DateTime.now().millisecondsSinceEpoch;

  final username = '${name.toLowerCase().replaceAll(' ', '_')}_$now';
  final empId = await db.customInsert(
    "INSERT INTO employees "
    "(username, name, password_hash, role, pin_hash, is_active, created_at, updated_at) "
    "VALUES (?, ?, 'unused', ?, 'hash', 1, ?, ?)",
    variables: [
      Variable.withString(username),
      Variable.withString(name),
      Variable.withString(role),
      Variable.withInt(now),
      Variable.withInt(now),
    ],
  );

  final urId = 'ur_${name.toLowerCase()}_$empId';
  await db.customStatement(
    "INSERT OR IGNORE INTO user_roles (id, user_id, role, scope, assigned_at, assigned_by) "
    "VALUES (?, ?, ?, ?, ?, ?)",
    [urId, empId, role, scope, now, empId],
  );

  return empId;
}

void main() {
  group('D — Permission system', () {
    // ── D-15  RBAC disabled (default) → everyone has all access ──────────
    test('D-15: when RBAC is disabled all users have full access', () async {
      final db = _openDb();
      addTearDown(db.close);
      final service = PermissionService(db);

      // Default state: rbac_enabled = false
      expect(await service.isRBACEnabled(), isFalse);

      final staffId = await _insertEmployeeWithRole(db, name: 'Staff1', role: 'STAFF');
      // Even with STAFF role, all permissions granted when RBAC is disabled
      expect(await service.hasPermission(staffId, 'revenue.dashboard.view'), isTrue);
      expect(await service.hasPermission(staffId, 'pos.discount'), isTrue);
      expect(await service.hasPermission(staffId, 'settings.store.edit'), isTrue);
    });

    // ── D-12  STAFF cannot access revenue reports ──────────────────────
    test('D-12: STAFF is denied revenue.dashboard.view when RBAC is enabled', () async {
      final db = _openDb();
      addTearDown(db.close);
      await _enableRbac(db);
      final service = PermissionService(db);

      final staffId = await _insertEmployeeWithRole(db, name: 'Staff2', role: 'STAFF');

      expect(await service.hasPermission(staffId, 'revenue.dashboard.view'), isFalse);
      expect(await service.hasPermission(staffId, 'revenue.daily.view'), isFalse);
      expect(await service.hasPermission(staffId, 'revenue.monthly.view'), isFalse);
      expect(await service.hasPermission(staffId, 'revenue.export'), isFalse);
    });

    test('D-12b: STAFF has access to allowed POS and order permissions', () async {
      final db = _openDb();
      addTearDown(db.close);
      await _enableRbac(db);
      final service = PermissionService(db);

      final staffId = await _insertEmployeeWithRole(db, name: 'Staff3', role: 'STAFF');

      expect(await service.hasPermission(staffId, 'pos.open'), isTrue);
      expect(await service.hasPermission(staffId, 'order.create'), isTrue);
      expect(await service.hasPermission(staffId, 'order.view'), isTrue);
      expect(await service.hasPermission(staffId, 'inventory.view'), isTrue);
    });

    // ── D-13  STAFF cannot apply discounts ────────────────────────────
    test('D-13: STAFF is denied pos.discount when RBAC is enabled', () async {
      final db = _openDb();
      addTearDown(db.close);
      await _enableRbac(db);
      final service = PermissionService(db);

      final staffId = await _insertEmployeeWithRole(db, name: 'Staff4', role: 'STAFF');

      expect(await service.hasPermission(staffId, 'pos.discount'), isFalse);
      expect(await service.hasPermission(staffId, 'pos.price.override'), isFalse);
      expect(await service.hasPermission(staffId, 'pos.refund'), isFalse);
    });

    // ── D-14  OWNER has full access ───────────────────────────────────
    test('D-14: OWNER has access to all permissions when RBAC is enabled', () async {
      final db = _openDb();
      addTearDown(db.close);
      await _enableRbac(db);
      final service = PermissionService(db);

      final ownerId = await _insertEmployeeWithRole(
        db, name: 'Owner1', role: 'OWNER', scope: 'ALL_STORES',
      );

      // Revenue (sensitive) — all allowed
      expect(await service.hasPermission(ownerId, 'revenue.dashboard.view'), isTrue);
      expect(await service.hasPermission(ownerId, 'revenue.daily.view'), isTrue);
      expect(await service.hasPermission(ownerId, 'revenue.monthly.view'), isTrue);
      expect(await service.hasPermission(ownerId, 'revenue.export'), isTrue);
      expect(await service.hasPermission(ownerId, 'revenue.pnl.view'), isTrue);

      // POS — all allowed
      expect(await service.hasPermission(ownerId, 'pos.open'), isTrue);
      expect(await service.hasPermission(ownerId, 'pos.discount'), isTrue);
      expect(await service.hasPermission(ownerId, 'pos.refund'), isTrue);
      expect(await service.hasPermission(ownerId, 'pos.price.override'), isTrue);

      // Settings — all allowed
      expect(await service.hasPermission(ownerId, 'settings.store.edit'), isTrue);
      expect(await service.hasPermission(ownerId, 'settings.tax.edit'), isTrue);

      // Staff management — all allowed
      expect(await service.hasPermission(ownerId, 'staff.manage'), isTrue);
      expect(await service.hasPermission(ownerId, 'staff.role.assign'), isTrue);
    });

    // ── D-16  STORE_MANAGER partial permissions ────────────────────────
    test('D-16: STORE_MANAGER has revenue.daily.view but not revenue.multistore.view', () async {
      final db = _openDb();
      addTearDown(db.close);
      await _enableRbac(db);
      final service = PermissionService(db);

      final mgrid = await _insertEmployeeWithRole(
        db, name: 'Mgr1', role: 'STORE_MANAGER', scope: 'OWN_STORE',
      );

      expect(await service.hasPermission(mgrid, 'revenue.daily.view'), isTrue);
      expect(await service.hasPermission(mgrid, 'revenue.weekly.view'), isTrue);
      expect(await service.hasPermission(mgrid, 'revenue.multistore.view'), isFalse);
      expect(await service.hasPermission(mgrid, 'revenue.export'), isFalse);
      expect(await service.hasPermission(mgrid, 'settings.store.edit'), isFalse);
    });

    test('D-16b: STORE_MANAGER can discount and refund but not assign roles', () async {
      final db = _openDb();
      addTearDown(db.close);
      await _enableRbac(db);
      final service = PermissionService(db);

      final mgrid = await _insertEmployeeWithRole(
        db, name: 'Mgr2', role: 'STORE_MANAGER', scope: 'OWN_STORE',
      );

      expect(await service.hasPermission(mgrid, 'pos.discount'), isTrue);
      expect(await service.hasPermission(mgrid, 'pos.refund'), isTrue);
      expect(await service.hasPermission(mgrid, 'staff.role.assign'), isFalse);
    });

    // ── D-17  Unknown user ─────────────────────────────────────────────
    test('D-17: user with no role record is denied all permissions when RBAC enabled', () async {
      final db = _openDb();
      addTearDown(db.close);
      await _enableRbac(db);
      final service = PermissionService(db);

      const unknownUserId = 99999;
      expect(await service.hasPermission(unknownUserId, 'pos.open'), isFalse);
      expect(await service.hasPermission(unknownUserId, 'revenue.dashboard.view'), isFalse);
    });

    // ── D-18  isOwner() helper ─────────────────────────────────────────
    test('D-18a: isOwner() returns true for OWNER role', () async {
      final db = _openDb();
      addTearDown(db.close);
      final service = PermissionService(db);

      final ownerId = await _insertEmployeeWithRole(
        db, name: 'Owner2', role: 'OWNER', scope: 'ALL_STORES',
      );
      expect(await service.isOwner(ownerId), isTrue);
    });

    test('D-18b: isOwner() returns false for STAFF role', () async {
      final db = _openDb();
      addTearDown(db.close);
      final service = PermissionService(db);

      final staffId = await _insertEmployeeWithRole(db, name: 'Staff5', role: 'STAFF');
      expect(await service.isOwner(staffId), isFalse);
    });

    // ── D-19  getUserRoleEnum() helper ────────────────────────────────
    test('D-19: getUserRoleEnum() returns correct EmployeeRole enum', () async {
      final db = _openDb();
      addTearDown(db.close);
      final service = PermissionService(db);

      final staffId = await _insertEmployeeWithRole(db, name: 'Staff6', role: 'STAFF');
      final ownerId = await _insertEmployeeWithRole(db, name: 'Owner3', role: 'OWNER');

      final staffRole = await service.getUserRoleEnum(staffId);
      final ownerRole = await service.getUserRoleEnum(ownerId);

      expect(staffRole?.name, 'STAFF');
      expect(ownerRole?.name, 'OWNER');
    });

    // ── D-20  canManageUsers / canViewRevenue helpers ─────────────────
    test('D-20: canManageUsers returns false for STAFF, true for OWNER (RBAC enabled)', () async {
      final db = _openDb();
      addTearDown(db.close);
      await _enableRbac(db);
      final service = PermissionService(db);

      final staffId = await _insertEmployeeWithRole(db, name: 'Staff7', role: 'STAFF');
      final ownerId = await _insertEmployeeWithRole(db, name: 'Owner4', role: 'OWNER', scope: 'ALL_STORES');

      expect(await service.canManageUsers(staffId), isFalse);
      expect(await service.canManageUsers(ownerId), isTrue);
    });

    test('D-20b: canViewRevenue returns false for STAFF, true for OWNER (RBAC enabled)', () async {
      final db = _openDb();
      addTearDown(db.close);
      await _enableRbac(db);
      final service = PermissionService(db);

      final staffId = await _insertEmployeeWithRole(db, name: 'Staff8', role: 'STAFF');
      final ownerId = await _insertEmployeeWithRole(db, name: 'Owner5', role: 'OWNER', scope: 'ALL_STORES');

      expect(await service.canViewRevenue(staffId), isFalse);
      expect(await service.canViewRevenue(ownerId), isTrue);
    });

    // ── D-21  Permission cache invalidation ───────────────────────────
    test('D-21: clearCache does not break subsequent permission checks', () async {
      final db = _openDb();
      addTearDown(db.close);
      await _enableRbac(db);
      final service = PermissionService(db);

      final ownerId = await _insertEmployeeWithRole(db, name: 'Owner6', role: 'OWNER', scope: 'ALL_STORES');

      // Warm up cache
      await service.hasPermission(ownerId, 'pos.open');
      await service.hasPermission(ownerId, 'revenue.dashboard.view');

      // Clear and re-check — should still work correctly
      service.clearCache();
      expect(await service.hasPermission(ownerId, 'pos.open'), isTrue);
      expect(await service.hasPermission(ownerId, 'revenue.dashboard.view'), isTrue);
    });
  });
}

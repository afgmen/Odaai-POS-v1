import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/features/auth/domain/employee_role.dart';
import 'package:oda_pos/features/auth/domain/permission.dart';

// ---------------------------------------------------------------------------
// Tests for the permission / RBAC domain layer.
//
// PermissionService itself requires a DB connection.  We test here:
//   • EmployeeRole enum properties (scope, canModify, fromString)
//   • StoreScope enum properties
//   • Permission enum descriptions / categories
//   • Role-based access control rules (expressed as pure conditions)
//
// No DB required — pure unit tests.
// ---------------------------------------------------------------------------

void main() {
  // ── EmployeeRole properties ────────────────────────────────────────────
  group('EmployeeRole — defaultScope', () {
    test('OWNER scope is ALL_STORES', () {
      expect(EmployeeRole.OWNER.defaultScope, StoreScope.ALL_STORES);
    });

    test('AREA_MANAGER scope is ASSIGNED_STORES', () {
      expect(EmployeeRole.AREA_MANAGER.defaultScope, StoreScope.ASSIGNED_STORES);
    });

    test('STORE_MANAGER scope is OWN_STORE', () {
      expect(EmployeeRole.STORE_MANAGER.defaultScope, StoreScope.OWN_STORE);
    });

    test('STAFF scope is OWN_STORE', () {
      expect(EmployeeRole.STAFF.defaultScope, StoreScope.OWN_STORE);
    });
  });

  group('EmployeeRole — canModifyPermissions', () {
    test('OWNER cannot have permissions modified', () {
      expect(EmployeeRole.OWNER.canModifyPermissions, isFalse);
    });

    test('AREA_MANAGER permissions can be modified', () {
      expect(EmployeeRole.AREA_MANAGER.canModifyPermissions, isTrue);
    });

    test('STORE_MANAGER permissions can be modified', () {
      expect(EmployeeRole.STORE_MANAGER.canModifyPermissions, isTrue);
    });

    test('STAFF permissions can be modified', () {
      expect(EmployeeRole.STAFF.canModifyPermissions, isTrue);
    });
  });

  group('EmployeeRole — fromString()', () {
    test('parses OWNER', () {
      expect(EmployeeRole.fromString('OWNER'), EmployeeRole.OWNER);
    });

    test('parses AREA_MANAGER', () {
      expect(EmployeeRole.fromString('AREA_MANAGER'), EmployeeRole.AREA_MANAGER);
    });

    test('parses STORE_MANAGER', () {
      expect(EmployeeRole.fromString('STORE_MANAGER'), EmployeeRole.STORE_MANAGER);
    });

    test('parses STAFF', () {
      expect(EmployeeRole.fromString('STAFF'), EmployeeRole.STAFF);
    });

    test('case-insensitive parsing', () {
      expect(EmployeeRole.fromString('owner'), EmployeeRole.OWNER);
      expect(EmployeeRole.fromString('staff'), EmployeeRole.STAFF);
    });

    test('unknown value defaults to STAFF', () {
      expect(EmployeeRole.fromString('UNKNOWN_ROLE'), EmployeeRole.STAFF);
    });
  });

  group('EmployeeRole — toDbString()', () {
    test('all roles round-trip through toDbString and fromString', () {
      for (final role in EmployeeRole.values) {
        final dbStr = role.toDbString();
        final parsed = EmployeeRole.fromString(dbStr);
        expect(parsed, role, reason: 'Round-trip failed for $role');
      }
    });
  });

  // ── StoreScope properties ─────────────────────────────────────────────
  group('StoreScope — fromString()', () {
    test('parses ALL_STORES', () {
      expect(StoreScope.fromString('ALL_STORES'), StoreScope.ALL_STORES);
    });

    test('parses ASSIGNED_STORES', () {
      expect(StoreScope.fromString('ASSIGNED_STORES'), StoreScope.ASSIGNED_STORES);
    });

    test('parses OWN_STORE', () {
      expect(StoreScope.fromString('OWN_STORE'), StoreScope.OWN_STORE);
    });

    test('unknown value defaults to OWN_STORE', () {
      expect(StoreScope.fromString('INVALID'), StoreScope.OWN_STORE);
    });
  });

  // ── Permission enum ────────────────────────────────────────────────────
  group('Permission — descriptions', () {
    test('REPORT_VIEW has non-empty description', () {
      expect(Permission.REPORT_VIEW.description, isNotEmpty);
    });

    test('SALES_CREATE description is non-empty', () {
      expect(Permission.SALES_CREATE.description, isNotEmpty);
    });

    test('all permissions have non-empty descriptions', () {
      for (final p in Permission.values) {
        expect(p.description, isNotEmpty, reason: '${p.name} has empty description');
      }
    });
  });

  group('Permission — categories', () {
    test('REPORT_VIEW is in Reports category', () {
      expect(Permission.REPORT_VIEW.category, 'Reports');
    });

    test('SALES_CREATE is in Sales category', () {
      expect(Permission.SALES_CREATE.category, 'Sales');
    });

    test('REFUND_SMALL is in Refunds category', () {
      expect(Permission.REFUND_SMALL.category, 'Refunds');
    });

    test('INVENTORY_MODIFY is in Inventory category', () {
      expect(Permission.INVENTORY_MODIFY.category, 'Inventory');
    });

    test('KDS_ACCESS is in Kitchen category', () {
      expect(Permission.KDS_ACCESS.category, 'Kitchen');
    });
  });

  // ── RBAC rules (domain logic, no DB) ──────────────────────────────────
  group('RBAC rules — OWNER has all permissions', () {
    test('OWNER role is not modifiable', () {
      // The PermissionService grants OWNER all permissions unconditionally.
      // Verify the guard flag is false (cannot modify).
      expect(EmployeeRole.OWNER.canModifyPermissions, isFalse);
    });

    test('OWNER scope covers ALL_STORES', () {
      expect(EmployeeRole.OWNER.defaultScope, StoreScope.ALL_STORES);
    });
  });

  group('RBAC rules — STAFF restrictions', () {
    test('STAFF default scope is OWN_STORE (cannot access cross-store)', () {
      expect(EmployeeRole.STAFF.defaultScope, StoreScope.OWN_STORE);
    });

    test('STAFF permissions can be modified (restricted by default)', () {
      // STAFF starts with no admin permissions; canModify = true so manager
      // can grant/revoke specific permissions.
      expect(EmployeeRole.STAFF.canModifyPermissions, isTrue);
    });

    // Permission string name validation (mirrors the DB permission registry)
    test('REPORT_VIEW permission name is REPORT_VIEW', () {
      expect(Permission.REPORT_VIEW.name, 'REPORT_VIEW');
    });
  });

  group('RBAC rules — permission check logic', () {
    // Simulates PermissionService.hasPermission() without a real DB.
    // Mirrors the core logic: OWNER → always true, others → check DB.

    bool _simulateHasPermission({
      required String role,
      required bool rbacEnabled,
      required bool roleHasPermission,
    }) {
      if (!rbacEnabled) return true; // RBAC disabled → full access
      if (role == 'OWNER') return true; // Owner always has all
      return roleHasPermission;
    }

    test('RBAC disabled → any role has all permissions', () {
      expect(
        _simulateHasPermission(
          role: 'STAFF',
          rbacEnabled: false,
          roleHasPermission: false,
        ),
        isTrue,
      );
    });

    test('RBAC enabled + OWNER → always true', () {
      expect(
        _simulateHasPermission(
          role: 'OWNER',
          rbacEnabled: true,
          roleHasPermission: false, // irrelevant for OWNER
        ),
        isTrue,
      );
    });

    test('RBAC enabled + STAFF + permission granted → true', () {
      expect(
        _simulateHasPermission(
          role: 'STAFF',
          rbacEnabled: true,
          roleHasPermission: true,
        ),
        isTrue,
      );
    });

    test('RBAC enabled + STAFF + permission NOT granted → false', () {
      expect(
        _simulateHasPermission(
          role: 'STAFF',
          rbacEnabled: true,
          roleHasPermission: false,
        ),
        isFalse,
      );
    });

    test('RBAC enabled + STORE_MANAGER without REPORT_VIEW → false', () {
      expect(
        _simulateHasPermission(
          role: 'STORE_MANAGER',
          rbacEnabled: true,
          roleHasPermission: false, // REPORT_VIEW not granted
        ),
        isFalse,
      );
    });
  });
}

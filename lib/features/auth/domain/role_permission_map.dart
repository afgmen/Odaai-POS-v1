import 'permission.dart';
import 'user_role.dart';

/// 역할별 권한 매핑 (Static Configuration)
class RolePermissionMap {
  /// 역할별 권한 맵 (캐시용)
  static final Map<UserRole, Set<Permission>> _rolePermissions = {
    // 관리자: 모든 권한
    UserRole.MANAGER: {
      Permission.SALES_CREATE,
      Permission.SALES_VIEW_OWN,
      Permission.SALES_VIEW_ALL,
      Permission.REFUND_SMALL,
      Permission.REFUND_UNLIMITED,
      Permission.DISCOUNT_APPLY,
      Permission.INVENTORY_VIEW,
      Permission.INVENTORY_MODIFY,
      Permission.EMPLOYEE_VIEW,
      Permission.EMPLOYEE_MANAGE,
      Permission.REPORT_VIEW,
      Permission.TABLE_MANAGE,
      Permission.KDS_ACCESS,
    },

    // 직원: 제한된 권한
    UserRole.CASHIER: {
      Permission.SALES_CREATE,
      Permission.SALES_VIEW_OWN,
      Permission.REFUND_SMALL, // 50,000원 이하만
      Permission.INVENTORY_VIEW,
      Permission.TABLE_MANAGE,
      // DISCOUNT_APPLY는 없음 (관리자 승인 필요)
      // REFUND_UNLIMITED는 없음
    },

    // 주방: KDS만
    UserRole.KITCHEN: {
      Permission.KDS_ACCESS,
    },
  };

  /// 역할이 특정 권한을 가지고 있는지 확인 (O(1) 조회)
  static bool hasPermission(UserRole role, Permission permission) {
    final permissions = _rolePermissions[role];
    return permissions?.contains(permission) ?? false;
  }

  /// 역할의 모든 권한 반환
  static Set<Permission> getPermissions(UserRole role) {
    return _rolePermissions[role] ?? {};
  }

  /// 특정 권한을 가진 모든 역할 반환
  static List<UserRole> getRolesWithPermission(Permission permission) {
    return _rolePermissions.entries
        .where((entry) => entry.value.contains(permission))
        .map((entry) => entry.key)
        .toList();
  }

  /// 역할이 관리자인지 확인
  static bool isManager(UserRole role) {
    return role == UserRole.MANAGER;
  }

  /// 역할이 주방 직원인지 확인
  static bool isKitchen(UserRole role) {
    return role == UserRole.KITCHEN;
  }
}

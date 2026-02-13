import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_role.dart';
import '../domain/permission.dart';
import '../domain/role_permission_map.dart';
import '../domain/session.dart';
import '../domain/auth_error.dart';
import 'auth_provider.dart';
import 'audit_logging_provider.dart';

/// 권한 체크 Provider
class PermissionChecker {
  final Ref _ref;

  PermissionChecker(this._ref);

  /// 현재 사용자가 특정 권한을 가지고 있는지 확인
  ///
  /// [permission] 확인할 권한
  /// Returns: 권한 보유 여부
  bool hasPermission(Permission permission) {
    final session = _ref.read(currentSessionProvider);
    if (session == null) return false;

    return RolePermissionMap.hasPermission(session.role, permission);
  }

  /// 현재 사용자가 특정 역할인지 확인
  ///
  /// [role] 확인할 역할
  /// Returns: 역할 일치 여부
  bool hasRole(UserRole role) {
    final session = _ref.read(currentSessionProvider);
    if (session == null) return false;

    return session.role == role;
  }

  /// 관리자 여부 확인
  bool get isManager {
    return hasRole(UserRole.MANAGER);
  }

  /// 직원 여부 확인
  bool get isCashier {
    return hasRole(UserRole.CASHIER);
  }

  /// 주방 여부 확인
  bool get isKitchen {
    return hasRole(UserRole.KITCHEN);
  }

  /// 권한 체크 및 예외 발생
  ///
  /// [permission] 필요한 권한
  /// Throws: AuthError if permission denied
  void requirePermission(Permission permission) {
    if (!hasPermission(permission)) {
      throw AuthErrors.permissionDenied(permission.description);
    }
  }

  /// 역할 체크 및 예외 발생
  ///
  /// [role] 필요한 역할
  /// Throws: AuthError if role does not match
  void requireRole(UserRole role) {
    if (!hasRole(role)) {
      throw AuthErrors.permissionDenied('${role.displayName} 역할이 필요합니다');
    }
  }

  /// 권한 요청 (관리자 승인 포함)
  ///
  /// [permission] 필요한 권한
  /// [action] 작업 설명
  /// Returns: 권한 허용 여부
  Future<bool> requestPermission(
    Permission permission,
    String action,
  ) async {
    // 1. 이미 권한이 있으면 즉시 허용
    if (hasPermission(permission)) {
      return true;
    }

    // 2. 권한 거부 로그 기록
    final session = _ref.read(currentSessionProvider);
    if (session != null) {
      await _ref.read(auditLoggingProvider).logPermissionDenied(
            session.employeeId,
            action,
            permission.description,
          );
    }

    return false;
  }

  /// 관리자 승인 요청 (Manager Override)
  ///
  /// [permission] 필요한 권한
  /// [action] 작업 설명
  /// [managerPin] 관리자 PIN
  /// Returns: 승인 여부
  Future<bool> requestManagerOverride(
    Permission permission,
    String action,
    String managerPin,
  ) async {
    final session = _ref.read(currentSessionProvider);
    if (session == null) return false;

    // 1. 관리자 PIN 검증
    final authNotifier = _ref.read(authProvider.notifier);
    final isValid = await authNotifier.validateManagerPIN(managerPin);

    if (!isValid) {
      // 승인 실패 로그 기록
      await _ref.read(auditLoggingProvider).logOverrideAttempt(
            session.employeeId,
            action,
            success: false,
          );
      return false;
    }

    // 2. 승인한 관리자 ID 조회
    final managerId = await authNotifier.getManagerIdByPIN(managerPin);

    // 3. 승인 성공 로그 기록
    await _ref.read(auditLoggingProvider).logOverrideGranted(
          session.employeeId,
          action,
          permission.description,
          managerId,
        );

    return true;
  }

  /// 현재 사용자의 모든 권한 조회
  ///
  /// Returns: 권한 목록
  Set<Permission> getAllPermissions() {
    final session = _ref.read(currentSessionProvider);
    if (session == null) return {};

    return RolePermissionMap.getPermissions(session.role);
  }

  /// 특정 권한이 필요한 역할 목록 조회
  ///
  /// [permission] 권한
  /// Returns: 역할 목록
  List<UserRole> getRolesWithPermission(Permission permission) {
    return RolePermissionMap.getRolesWithPermission(permission);
  }
}

// ============================================================
// Providers
// ============================================================

/// Permission Checker Provider
final permissionProvider = Provider<PermissionChecker>((ref) {
  return PermissionChecker(ref);
});

/// 특정 권한 보유 여부 Provider (UI용)
///
/// 사용 예: ref.watch(hasPermissionProvider(Permission.REFUND_UNLIMITED))
final hasPermissionProvider = Provider.family<bool, Permission>((ref, permission) {
  return ref.watch(permissionProvider).hasPermission(permission);
});

/// 관리자 여부 Provider (UI용)
final isManagerProvider = Provider<bool>((ref) {
  return ref.watch(permissionProvider).isManager;
});

/// 직원 여부 Provider (UI용)
final isCashierProvider = Provider<bool>((ref) {
  return ref.watch(permissionProvider).isCashier;
});

/// 주방 여부 Provider (UI용)
final isKitchenProvider = Provider<bool>((ref) {
  return ref.watch(permissionProvider).isKitchen;
});

/// 현재 사용자 권한 목록 Provider
final currentPermissionsProvider = Provider<Set<Permission>>((ref) {
  return ref.watch(permissionProvider).getAllPermissions();
});

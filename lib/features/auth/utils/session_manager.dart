import 'package:uuid/uuid.dart';

/// 세션 관리 유틸리티
class SessionManager {
  /// 세션 유효 시간 (8시간)
  static const Duration sessionDuration = Duration(hours: 8);

  /// 비활성 타임아웃 (5분)
  static const Duration inactivityTimeout = Duration(minutes: 5);

  /// UUID 생성기
  static const Uuid _uuid = Uuid();

  /// 세션 토큰 생성 (UUID v4)
  ///
  /// Returns: 고유한 세션 토큰
  static String generateToken() {
    return _uuid.v4();
  }

  /// 세션 만료 시간 계산
  ///
  /// Returns: 현재 시간 + 8시간
  static DateTime calculateExpiry() {
    return DateTime.now().add(sessionDuration);
  }

  /// 세션 유효성 검사
  ///
  /// [expiresAt] 만료 시간
  /// [lastActivity] 마지막 활동 시간 (nullable)
  /// Returns: 유효성 여부
  static bool isSessionValid(DateTime? expiresAt, DateTime? lastActivity) {
    if (expiresAt == null) return false;

    final now = DateTime.now();

    // 1. 세션 만료 확인 (8시간)
    if (now.isAfter(expiresAt)) {
      return false;
    }

    // 2. 비활성 타임아웃 확인 (5분)
    if (lastActivity != null) {
      final inactiveTime = now.difference(lastActivity);
      if (inactiveTime > inactivityTimeout) {
        return false;
      }
    }

    return true;
  }

  /// 세션이 곧 만료될지 확인 (1시간 이내)
  ///
  /// [expiresAt] 만료 시간
  /// Returns: 곧 만료 여부
  static bool isSessionExpiringSoon(DateTime expiresAt) {
    final now = DateTime.now();
    final timeLeft = expiresAt.difference(now);
    return timeLeft.inHours < 1 && timeLeft.inMinutes > 0;
  }

  /// 남은 세션 시간 계산 (분 단위)
  ///
  /// [expiresAt] 만료 시간
  /// Returns: 남은 시간 (분)
  static int getRemainingMinutes(DateTime expiresAt) {
    final now = DateTime.now();
    final timeLeft = expiresAt.difference(now);
    return timeLeft.inMinutes.clamp(0, 60 * 24); // 최대 24시간
  }

  /// 비활성 시간 계산 (분 단위)
  ///
  /// [lastActivity] 마지막 활동 시간
  /// Returns: 비활성 시간 (분)
  static int getInactiveMinutes(DateTime lastActivity) {
    final now = DateTime.now();
    final inactiveTime = now.difference(lastActivity);
    return inactiveTime.inMinutes;
  }

  /// 세션 연장이 필요한지 확인 (4시간 경과 시)
  ///
  /// [expiresAt] 만료 시간
  /// Returns: 연장 필요 여부
  static bool needsExtension(DateTime expiresAt) {
    final now = DateTime.now();
    final timeLeft = expiresAt.difference(now);
    // 남은 시간이 4시간 이하면 연장 권장
    return timeLeft.inHours <= 4;
  }
}

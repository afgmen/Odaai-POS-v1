/// 인증 관련 에러
class AuthError implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  AuthError({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => '[$code] $message';

  /// 사용자 친화적 메시지
  String get userMessage => message;
}

/// 인증 에러 코드 상수
class AuthErrorCode {
  // 인증 에러
  static const String invalidPin = 'AUTH_001'; // 잘못된 PIN
  static const String accountLocked = 'AUTH_002'; // 계정 잠김
  static const String sessionExpired = 'AUTH_003'; // 세션 만료
  static const String sessionInactive = 'AUTH_004'; // 세션 비활성

  // 권한 에러
  static const String permissionDenied = 'PERM_001'; // 권한 없음
  static const String managerOverrideFailed = 'PERM_002'; // 관리자 승인 실패
  static const String noManagerAvailable = 'PERM_003'; // 관리자 없음

  // 시스템 에러
  static const String employeeNotFound = 'SYS_001'; // 직원 없음
  static const String pinNotSet = 'SYS_002'; // PIN 미설정
  static const String invalidPinFormat = 'SYS_003'; // 잘못된 PIN 형식
}

/// 미리 정의된 에러 팩토리
class AuthErrors {
  static AuthError invalidPin({int? attemptsLeft}) {
    return AuthError(
      code: AuthErrorCode.invalidPin,
      message: '잘못된 PIN입니다.',
      details: attemptsLeft != null ? {'attemptsLeft': attemptsLeft} : null,
    );
  }

  static AuthError accountLocked({Duration? duration}) {
    return AuthError(
      code: AuthErrorCode.accountLocked,
      message: '계정이 잠겼습니다. ${duration?.inMinutes ?? 1}분 후 다시 시도해주세요.',
      details: duration != null ? {'lockDuration': duration.inMinutes} : null,
    );
  }

  static AuthError sessionExpired() {
    return AuthError(
      code: AuthErrorCode.sessionExpired,
      message: '세션이 만료되었습니다. 다시 로그인해주세요.',
    );
  }

  static AuthError sessionInactive() {
    return AuthError(
      code: AuthErrorCode.sessionInactive,
      message: '5분간 활동이 없어 자동 로그아웃 되었습니다.',
    );
  }

  static AuthError permissionDenied(String action) {
    return AuthError(
      code: AuthErrorCode.permissionDenied,
      message: '$action 권한이 없습니다. 관리자에게 문의하세요.',
      details: {'action': action},
    );
  }

  static AuthError managerOverrideFailed() {
    return AuthError(
      code: AuthErrorCode.managerOverrideFailed,
      message: '관리자 PIN이 일치하지 않습니다.',
    );
  }

  static AuthError employeeNotFound() {
    return AuthError(
      code: AuthErrorCode.employeeNotFound,
      message: '직원 정보를 찾을 수 없습니다.',
    );
  }

  static AuthError pinNotSet() {
    return AuthError(
      code: AuthErrorCode.pinNotSet,
      message: 'PIN이 설정되지 않았습니다. 관리자에게 문의하세요.',
    );
  }

  static AuthError invalidPinFormat() {
    return AuthError(
      code: AuthErrorCode.invalidPinFormat,
      message: 'PIN은 4-6자리 숫자여야 합니다.',
    );
  }
}

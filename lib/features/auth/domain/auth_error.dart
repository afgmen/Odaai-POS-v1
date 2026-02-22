/// Authentication error
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

  /// User-friendly message
  String get userMessage => message;
}

/// Auth error code constants
class AuthErrorCode {
  // Auth errors
  static const String invalidPin = 'AUTH_001';       // Invalid PIN
  static const String accountLocked = 'AUTH_002';    // Account locked
  static const String sessionExpired = 'AUTH_003';   // Session expired
  static const String sessionInactive = 'AUTH_004';  // Session inactive

  // Permission errors
  static const String permissionDenied = 'PERM_001';       // Permission denied
  static const String managerOverrideFailed = 'PERM_002';  // Manager override failed
  static const String noManagerAvailable = 'PERM_003';     // No manager available

  // System errors
  static const String employeeNotFound = 'SYS_001'; // Employee not found
  static const String pinNotSet = 'SYS_002';        // PIN not set
  static const String invalidPinFormat = 'SYS_003'; // Invalid PIN format
}

/// Predefined error factories
class AuthErrors {
  static AuthError invalidPin({int? attemptsLeft}) {
    return AuthError(
      code: AuthErrorCode.invalidPin,
      message: 'Incorrect PIN.',
      details: attemptsLeft != null ? {'attemptsLeft': attemptsLeft} : null,
    );
  }

  static AuthError accountLocked({Duration? duration}) {
    return AuthError(
      code: AuthErrorCode.accountLocked,
      message: 'Account locked. Try again in ${duration?.inMinutes ?? 1} minute(s).',
      details: duration != null ? {'lockDuration': duration.inMinutes} : null,
    );
  }

  static AuthError sessionExpired() {
    return AuthError(
      code: AuthErrorCode.sessionExpired,
      message: 'Session expired. Please log in again.',
    );
  }

  static AuthError sessionInactive() {
    return AuthError(
      code: AuthErrorCode.sessionInactive,
      message: 'Auto-logged out due to 5 minutes of inactivity.',
    );
  }

  static AuthError permissionDenied(String action) {
    return AuthError(
      code: AuthErrorCode.permissionDenied,
      message: 'You do not have permission to $action. Contact your administrator.',
      details: {'action': action},
    );
  }

  static AuthError managerOverrideFailed() {
    return AuthError(
      code: AuthErrorCode.managerOverrideFailed,
      message: 'Manager PIN does not match.',
    );
  }

  static AuthError employeeNotFound() {
    return AuthError(
      code: AuthErrorCode.employeeNotFound,
      message: 'Employee not found.',
    );
  }

  static AuthError pinNotSet() {
    return AuthError(
      code: AuthErrorCode.pinNotSet,
      message: 'PIN not set. Please contact your administrator.',
    );
  }

  static AuthError invalidPinFormat() {
    return AuthError(
      code: AuthErrorCode.invalidPinFormat,
      message: 'PIN must be 4–6 digits.',
    );
  }
}

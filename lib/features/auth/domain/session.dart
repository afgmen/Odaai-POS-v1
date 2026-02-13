import 'user_role.dart';

/// 사용자 세션 모델
class Session {
  final int employeeId;
  final String employeeName;
  final UserRole role;
  final String token;
  final DateTime expiresAt;
  final DateTime lastActivityAt;

  Session({
    required this.employeeId,
    required this.employeeName,
    required this.role,
    required this.token,
    required this.expiresAt,
    required this.lastActivityAt,
  });

  /// 세션이 만료되었는지 확인 (8시간)
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// 세션이 비활성 상태인지 확인 (5분)
  bool get isInactive =>
      DateTime.now().difference(lastActivityAt).inMinutes > 5;

  /// 세션이 유효한지 확인
  bool get isValid => !isExpired && !isInactive;

  /// 활동 시간을 업데이트한 새 세션 반환
  Session copyWithActivity() {
    return Session(
      employeeId: employeeId,
      employeeName: employeeName,
      role: role,
      token: token,
      expiresAt: expiresAt,
      lastActivityAt: DateTime.now(),
    );
  }

  /// 세션 복사 (특정 필드 변경)
  Session copyWith({
    int? employeeId,
    String? employeeName,
    UserRole? role,
    String? token,
    DateTime? expiresAt,
    DateTime? lastActivityAt,
  }) {
    return Session(
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      role: role ?? this.role,
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }

  /// 세션을 Map으로 변환
  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'employeeName': employeeName,
      'role': role.value,
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
      'lastActivityAt': lastActivityAt.toIso8601String(),
    };
  }

  /// Map으로부터 세션 생성
  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      employeeId: json['employeeId'] as int,
      employeeName: json['employeeName'] as String,
      role: UserRoleExtension.fromString(json['role'] as String),
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
    );
  }

  @override
  String toString() {
    return 'Session(employeeId: $employeeId, employeeName: $employeeName, '
        'role: ${role.displayName}, valid: $isValid)';
  }
}

/// 사용자 역할 정의
enum UserRole {
  /// 관리자 (전체 권한)
  MANAGER,

  /// 직원 (제한된 권한)
  CASHIER,

  /// 주방 (KDS 전용)
  KITCHEN,
}

/// UserRole Extension - 문자열 변환 및 유틸리티
extension UserRoleExtension on UserRole {
  /// 역할을 문자열로 변환
  String get value {
    switch (this) {
      case UserRole.MANAGER:
        return 'MANAGER';
      case UserRole.CASHIER:
        return 'CASHIER';
      case UserRole.KITCHEN:
        return 'KITCHEN';
    }
  }

  /// 역할의 한글 이름
  String get displayName {
    switch (this) {
      case UserRole.MANAGER:
        return '관리자';
      case UserRole.CASHIER:
        return '직원';
      case UserRole.KITCHEN:
        return '주방';
    }
  }

  /// 문자열로부터 UserRole 생성
  static UserRole fromString(String value) {
    switch (value.toUpperCase()) {
      case 'MANAGER':
        return UserRole.MANAGER;
      case 'CASHIER':
        return UserRole.CASHIER;
      case 'KITCHEN':
        return UserRole.KITCHEN;
      default:
        return UserRole.CASHIER; // 기본값
    }
  }
}

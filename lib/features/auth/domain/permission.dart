/// 시스템 권한 정의
enum Permission {
  // 판매 관련
  SALES_CREATE, // 판매 생성
  SALES_VIEW_OWN, // 본인 판매 조회
  SALES_VIEW_ALL, // 전체 판매 조회

  // 환불 관련
  REFUND_SMALL, // 소액 환불 (50,000원 이하)
  REFUND_UNLIMITED, // 무제한 환불

  // 할인 관련
  DISCOUNT_APPLY, // 할인 적용

  // 재고 관련
  INVENTORY_VIEW, // 재고 조회
  INVENTORY_MODIFY, // 재고 수정

  // 직원 관리
  EMPLOYEE_VIEW, // 직원 조회
  EMPLOYEE_MANAGE, // 직원 관리 (생성, 수정, 삭제)

  // 매출 리포트
  REPORT_VIEW, // 리포트 조회

  // 테이블 관리
  TABLE_MANAGE, // 테이블 관리

  // 주방 디스플레이
  KDS_ACCESS, // KDS 접근
}

/// Permission Extension - 설명 및 유틸리티
extension PermissionExtension on Permission {
  /// 권한 설명
  String get description {
    switch (this) {
      case Permission.SALES_CREATE:
        return '판매 생성';
      case Permission.SALES_VIEW_OWN:
        return '본인 판매 조회';
      case Permission.SALES_VIEW_ALL:
        return '전체 판매 조회';
      case Permission.REFUND_SMALL:
        return '소액 환불 (50,000원 이하)';
      case Permission.REFUND_UNLIMITED:
        return '무제한 환불';
      case Permission.DISCOUNT_APPLY:
        return '할인 적용';
      case Permission.INVENTORY_VIEW:
        return '재고 조회';
      case Permission.INVENTORY_MODIFY:
        return '재고 수정';
      case Permission.EMPLOYEE_VIEW:
        return '직원 조회';
      case Permission.EMPLOYEE_MANAGE:
        return '직원 관리';
      case Permission.REPORT_VIEW:
        return '매출 리포트 조회';
      case Permission.TABLE_MANAGE:
        return '테이블 관리';
      case Permission.KDS_ACCESS:
        return '주방 디스플레이 접근';
    }
  }

  /// 권한 카테고리
  String get category {
    if ([Permission.SALES_CREATE, Permission.SALES_VIEW_OWN, Permission.SALES_VIEW_ALL]
        .contains(this)) {
      return '판매';
    } else if ([Permission.REFUND_SMALL, Permission.REFUND_UNLIMITED].contains(this)) {
      return '환불';
    } else if ([Permission.DISCOUNT_APPLY].contains(this)) {
      return '할인';
    } else if ([Permission.INVENTORY_VIEW, Permission.INVENTORY_MODIFY].contains(this)) {
      return '재고';
    } else if ([Permission.EMPLOYEE_VIEW, Permission.EMPLOYEE_MANAGE].contains(this)) {
      return '직원';
    } else if ([Permission.REPORT_VIEW].contains(this)) {
      return '리포트';
    } else if ([Permission.TABLE_MANAGE].contains(this)) {
      return '테이블';
    } else if ([Permission.KDS_ACCESS].contains(this)) {
      return '주방';
    }
    return '기타';
  }
}

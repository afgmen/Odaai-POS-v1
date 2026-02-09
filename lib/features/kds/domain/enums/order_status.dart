/// 주방 주문 상태
enum OrderStatus {
  /// 대기 중 (신규 주문)
  pending('PENDING', '대기'),

  /// 조리 중
  preparing('PREPARING', '조리중'),

  /// 조리 완료 (픽업 대기)
  ready('READY', '완료'),

  /// 서빙 완료
  served('SERVED', '서빙완료'),

  /// 취소됨
  cancelled('CANCELLED', '취소');

  final String value;
  final String displayName;

  const OrderStatus(this.value, this.displayName);

  /// 문자열 값으로 Enum 찾기
  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.pending,
    );
  }

  /// 활성 상태인지 확인 (PENDING, PREPARING, READY)
  bool get isActive {
    return this == OrderStatus.pending ||
        this == OrderStatus.preparing ||
        this == OrderStatus.ready;
  }

  /// 완료된 상태인지 확인 (SERVED, CANCELLED)
  bool get isCompleted {
    return this == OrderStatus.served || this == OrderStatus.cancelled;
  }

  /// 상태 색상 (Material Design)
  String get colorHex {
    switch (this) {
      case OrderStatus.pending:
        return '#FF9800'; // Orange
      case OrderStatus.preparing:
        return '#2196F3'; // Blue
      case OrderStatus.ready:
        return '#4CAF50'; // Green
      case OrderStatus.served:
        return '#9E9E9E'; // Grey
      case OrderStatus.cancelled:
        return '#F44336'; // Red
    }
  }

  /// 다음 상태로 전환 가능 여부
  bool canTransitionTo(OrderStatus nextStatus) {
    switch (this) {
      case OrderStatus.pending:
        return nextStatus == OrderStatus.preparing ||
            nextStatus == OrderStatus.cancelled;
      case OrderStatus.preparing:
        return nextStatus == OrderStatus.ready ||
            nextStatus == OrderStatus.cancelled;
      case OrderStatus.ready:
        return nextStatus == OrderStatus.served;
      case OrderStatus.served:
      case OrderStatus.cancelled:
        return false; // 완료 상태는 변경 불가
    }
  }
}

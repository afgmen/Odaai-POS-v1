/// 주문 우선순위
enum OrderPriority {
  /// 일반 주문
  normal('NORMAL', 'Normal'),

  /// Urgent order (VIP, rush, etc.)
  urgent('URGENT', 'Urgent');

  final String value;
  final String displayName;

  const OrderPriority(this.value, this.displayName);

  /// 문자열 값으로 Enum 찾기
  static OrderPriority fromString(String value) {
    return OrderPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => OrderPriority.normal,
    );
  }

  /// 우선순위 색상
  String get colorHex {
    switch (this) {
      case OrderPriority.normal:
        return '#757575'; // Grey
      case OrderPriority.urgent:
        return '#F44336'; // Red
    }
  }

  /// 긴급 여부
  bool get isUrgent => this == OrderPriority.urgent;
}

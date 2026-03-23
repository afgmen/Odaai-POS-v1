import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';

/// B-UAT: KDS 취소 알림 Provider
/// KDS에서 주문이 취소될 때 Floor Plan에 알림을 전달하기 위한 상태 공유

/// 최근 취소된 주방 주문 정보
class KitchenCancellationNotification {
  final int orderId;
  final int? saleId;
  final String? tableNumber;
  final String? reason;
  final DateTime cancelledAt;

  KitchenCancellationNotification({
    required this.orderId,
    this.saleId,
    this.tableNumber,
    this.reason,
    required this.cancelledAt,
  });
}

/// 취소 알림 알림 목록 (새 알림이 오면 앞에 추가, 최대 10개 유지)
class KitchenCancellationNotifier extends Notifier<List<KitchenCancellationNotification>> {
  @override
  List<KitchenCancellationNotification> build() => [];

  /// 새 취소 알림 추가
  void addCancellation({
    required int orderId,
    int? saleId,
    String? tableNumber,
    String? reason,
  }) {
    final notification = KitchenCancellationNotification(
      orderId: orderId,
      saleId: saleId,
      tableNumber: tableNumber,
      reason: reason,
      cancelledAt: DateTime.now(),
    );
    // 앞에 추가, 최대 10개 유지
    final updated = [notification, ...state].take(10).toList();
    state = updated;
  }

  /// 특정 알림 제거 (Floor Plan에서 확인 후 호출)
  void dismiss(int orderId) {
    state = state.where((n) => n.orderId != orderId).toList();
  }

  /// 모두 제거
  void dismissAll() {
    state = [];
  }

  /// 읽지 않은 알림 수
  int get unreadCount => state.length;
}

final kitchenCancellationProvider =
    NotifierProvider<KitchenCancellationNotifier, List<KitchenCancellationNotification>>(
  KitchenCancellationNotifier.new,
);

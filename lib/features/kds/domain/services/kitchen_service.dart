import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../../data/kitchen_orders_repository.dart';
import '../../../../database/app_database.dart';
import '../enums/order_status.dart';

/// KDS 비즈니스 로직 서비스
class KitchenService {
  final KitchenOrdersRepository _repository;
  final AudioPlayer _audioPlayer = AudioPlayer();

  KitchenService(this._repository);

  // ============================================================
  // 주문 생성
  // ============================================================

  /// POS 결제 완료 후 주방 주문 자동 생성
  Future<int> createOrderFromSale({
    required int saleId,
    String? tableNumber,
    String? specialInstructions,
    bool isUrgent = false,
  }) async {
    final orderId = await _repository.createOrderFromSale(
      saleId: saleId,
      tableNumber: tableNumber,
      specialInstructions: specialInstructions,
      isUrgent: isUrgent,
    );

    // 신규 주문 알림음 재생
    await _playNewOrderSound();

    return orderId;
  }

  // ============================================================
  // 상태 전환
  // ============================================================

  /// 조리 시작
  Future<bool> startPreparing(int orderId) async {
    final order = await _repository.getOrder(orderId);
    if (order == null) return false;

    final currentStatus = OrderStatus.fromString(order.status);
    if (!currentStatus.canTransitionTo(OrderStatus.preparing)) {
      debugPrint('Invalid state transition: ${order.status} → PREPARING');
      return false;
    }

    return await _repository.startPreparing(orderId);
  }

  /// 조리 완료
  Future<bool> markAsReady(int orderId) async {
    final order = await _repository.getOrder(orderId);
    if (order == null) return false;

    final currentStatus = OrderStatus.fromString(order.status);
    if (!currentStatus.canTransitionTo(OrderStatus.ready)) {
      debugPrint('Invalid state transition: ${order.status} → READY');
      return false;
    }

    final success = await _repository.markAsReady(orderId);
    if (success) {
      await _playReadySound();
    }
    return success;
  }

  /// 서빙 완료
  Future<bool> markAsServed(int orderId) async {
    final order = await _repository.getOrder(orderId);
    if (order == null) return false;

    final currentStatus = OrderStatus.fromString(order.status);
    if (!currentStatus.canTransitionTo(OrderStatus.served)) {
      debugPrint('Invalid state transition: ${order.status} → SERVED');
      return false;
    }

    return await _repository.markAsServed(orderId);
  }

  /// 주문 취소
  Future<bool> cancelOrder(int orderId) async {
    final order = await _repository.getOrder(orderId);
    if (order == null) return false;

    // SERVED는 취소 불가
    if (order.status == 'SERVED') {
      debugPrint('Cannot cancel already served order');
      return false;
    }

    return await _repository.cancelOrder(orderId);
  }

  // ============================================================
  // 우선순위 관리
  // ============================================================

  /// 긴급 주문으로 변경
  Future<bool> markAsUrgent(int orderId) async {
    final success = await _repository.markAsUrgent(orderId);
    if (success) {
      await _playUrgentSound();
    }
    return success;
  }

  /// 일반 주문으로 변경
  Future<bool> markAsNormal(int orderId) {
    return _repository.markAsNormal(orderId);
  }

  // ============================================================
  // 오디오 알림
  // ============================================================

  /// 신규 주문 알림음
  Future<void> _playNewOrderSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/new_order.mp3'));
    } catch (e) {
      debugPrint('Failed to play new order sound: $e');
    }
  }

  /// 조리 완료 알림음
  Future<void> _playReadySound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/order_ready.mp3'));
    } catch (e) {
      debugPrint('Failed to play ready sound: $e');
    }
  }

  /// 긴급 주문 알림음
  Future<void> _playUrgentSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/urgent_order.mp3'));
    } catch (e) {
      debugPrint('Failed to play urgent sound: $e');
    }
  }

  /// 오디오 리소스 해제
  void dispose() {
    _audioPlayer.dispose();
  }

  // ============================================================
  // 통계 및 분석
  // ============================================================

  /// 주방 성과 요약
  Future<KitchenPerformance> getPerformance() async {
    final todayServed = await _repository.getTodayServedCount();
    final avgPrepTime = await _repository.getAveragePrepTimeInMinutes();
    final statusCounts = await _repository.getOrderCountByStatus();

    return KitchenPerformance(
      todayServedCount: todayServed,
      averagePrepTimeMinutes: avgPrepTime,
      pendingCount: statusCounts['pending'] ?? 0,
      preparingCount: statusCounts['preparing'] ?? 0,
      readyCount: statusCounts['ready'] ?? 0,
    );
  }
}

/// 주방 성과 데이터 모델
class KitchenPerformance {
  final int todayServedCount;
  final double averagePrepTimeMinutes;
  final int pendingCount;
  final int preparingCount;
  final int readyCount;

  KitchenPerformance({
    required this.todayServedCount,
    required this.averagePrepTimeMinutes,
    required this.pendingCount,
    required this.preparingCount,
    required this.readyCount,
  });

  /// 총 활성 주문 수
  int get totalActiveOrders => pendingCount + preparingCount + readyCount;

  /// 평균 조리 시간 (포맷팅)
  String get averagePrepTimeFormatted {
    final minutes = averagePrepTimeMinutes.floor();
    final seconds = ((averagePrepTimeMinutes - minutes) * 60).round();
    return '${minutes}분 ${seconds}초';
  }
}

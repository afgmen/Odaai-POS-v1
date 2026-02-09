import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import 'kitchen_orders_dao.dart';

/// KDS Repository - 비즈니스 로직과 데이터 접근 분리
class KitchenOrdersRepository {
  final KitchenOrdersDao _dao;

  KitchenOrdersRepository(this._dao);

  // ============================================================
  // CREATE
  // ============================================================

  /// POS 결제 완료 후 주방 주문 생성
  Future<int> createOrderFromSale({
    required int saleId,
    String? tableNumber,
    String? specialInstructions,
    bool isUrgent = false,
  }) {
    return _dao.createOrderFromSale(
      saleId: saleId,
      tableNumber: tableNumber,
      specialInstructions: specialInstructions,
      priority: isUrgent ? 'URGENT' : 'NORMAL',
    );
  }

  // ============================================================
  // READ
  // ============================================================

  /// 특정 주문 조회
  Future<KitchenOrder?> getOrder(int id) {
    return _dao.getOrderById(id);
  }

  /// Sale ID로 주문 조회
  Future<KitchenOrder?> getOrderBySaleId(int saleId) {
    return _dao.getOrderBySaleId(saleId);
  }

  /// 모든 활성 주문 조회
  Future<List<KitchenOrder>> getActiveOrders() {
    return _dao.getActiveOrders();
  }

  /// 상태별 주문 목록
  Future<List<KitchenOrder>> getOrdersByStatus(String status) {
    return _dao.getOrdersByStatus(status);
  }

  // ============================================================
  // STREAM (실시간 업데이트)
  // ============================================================

  /// 활성 주문 실시간 스트림 (KDS 메인 화면)
  Stream<List<KitchenOrder>> watchActiveOrders() {
    return _dao.watchActiveOrders();
  }

  /// PENDING 주문 스트림
  Stream<List<KitchenOrder>> watchPendingOrders() {
    return _dao.watchOrdersByStatus('PENDING');
  }

  /// PREPARING 주문 스트림
  Stream<List<KitchenOrder>> watchPreparingOrders() {
    return _dao.watchOrdersByStatus('PREPARING');
  }

  /// READY 주문 스트림
  Stream<List<KitchenOrder>> watchReadyOrders() {
    return _dao.watchOrdersByStatus('READY');
  }

  // ============================================================
  // UPDATE - 상태 전환
  // ============================================================

  /// 조리 시작 (PENDING → PREPARING)
  Future<bool> startPreparing(int orderId) {
    return _dao.startPreparing(orderId);
  }

  /// 조리 완료 (PREPARING → READY)
  Future<bool> markAsReady(int orderId) {
    return _dao.markAsReady(orderId);
  }

  /// 서빙 완료 (READY → SERVED)
  Future<bool> markAsServed(int orderId) {
    return _dao.markAsServed(orderId);
  }

  /// 주문 취소
  Future<bool> cancelOrder(int orderId) {
    return _dao.cancelOrder(orderId);
  }

  /// 긴급 주문으로 변경
  Future<bool> markAsUrgent(int orderId) {
    return _dao.updatePriority(orderId, 'URGENT');
  }

  /// 일반 주문으로 변경
  Future<bool> markAsNormal(int orderId) {
    return _dao.updatePriority(orderId, 'NORMAL');
  }

  /// 특별 지시사항 수정
  Future<bool> updateSpecialInstructions(int orderId, String? instructions) {
    return _dao.updateSpecialInstructions(orderId, instructions);
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// 각 상태별 주문 개수
  Future<Map<String, int>> getOrderCountByStatus() async {
    final pending = await _dao.countOrdersByStatus('PENDING');
    final preparing = await _dao.countOrdersByStatus('PREPARING');
    final ready = await _dao.countOrdersByStatus('READY');
    final served = await _dao.countOrdersByStatus('SERVED');

    return {
      'pending': pending,
      'preparing': preparing,
      'ready': ready,
      'served': served,
    };
  }

  /// 오늘 처리된 주문 개수
  Future<int> getTodayServedCount() {
    return _dao.countTodayServedOrders();
  }

  /// 평균 조리 시간 (분 단위)
  Future<double> getAveragePrepTimeInMinutes() async {
    final seconds = await _dao.calculateAveragePrepTime();
    return seconds / 60.0;
  }

  // ============================================================
  // MAINTENANCE
  // ============================================================

  /// 오래된 완료 주문 정리
  Future<int> cleanupOldOrders({int daysOld = 7}) {
    return _dao.cleanupOldServedOrders(daysOld: daysOld);
  }
}

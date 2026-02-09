import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';
import 'kitchen_orders_dao.dart';
import 'kitchen_orders_repository.dart';
import 'models/kitchen_order_with_items.dart';

// ============================================================
// DAO Provider
// ============================================================

/// KitchenOrders DAO Provider
final kitchenOrdersDaoProvider = Provider<KitchenOrdersDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.kitchenOrdersDao;
});

// ============================================================
// Repository Provider
// ============================================================

/// KitchenOrders Repository Provider
final kitchenOrdersRepositoryProvider =
    Provider<KitchenOrdersRepository>((ref) {
  final dao = ref.watch(kitchenOrdersDaoProvider);
  return KitchenOrdersRepository(dao);
});

// ============================================================
// Stream Providers (실시간 데이터)
// ============================================================

/// 활성 주문 스트림 (PENDING, PREPARING, READY)
final activeOrdersStreamProvider =
    StreamProvider<List<KitchenOrder>>((ref) {
  final dao = ref.watch(kitchenOrdersDaoProvider);
  return dao.watchActiveOrders();
});

/// 활성 주문 + 메뉴 아이템 스트림 (KDS 메인 화면용)
final activeOrdersWithItemsStreamProvider =
    StreamProvider<List<KitchenOrderWithItems>>((ref) {
  final dao = ref.watch(kitchenOrdersDaoProvider);
  return dao.watchActiveOrdersWithItems();
});

/// PENDING 주문 스트림
final pendingOrdersStreamProvider =
    StreamProvider<List<KitchenOrder>>((ref) {
  final dao = ref.watch(kitchenOrdersDaoProvider);
  return dao.watchOrdersByStatus('PENDING');
});

/// PREPARING 주문 스트림
final preparingOrdersStreamProvider =
    StreamProvider<List<KitchenOrder>>((ref) {
  final dao = ref.watch(kitchenOrdersDaoProvider);
  return dao.watchOrdersByStatus('PREPARING');
});

/// READY 주문 스트림
final readyOrdersStreamProvider =
    StreamProvider<List<KitchenOrder>>((ref) {
  final dao = ref.watch(kitchenOrdersDaoProvider);
  return dao.watchOrdersByStatus('READY');
});

// ============================================================
// Statistics Providers
// ============================================================

/// 오늘 처리된 주문 개수
final todayServedCountProvider = FutureProvider<int>((ref) {
  final repository = ref.watch(kitchenOrdersRepositoryProvider);
  return repository.getTodayServedCount();
});

/// 평균 조리 시간 (분)
final averagePrepTimeProvider = FutureProvider<double>((ref) {
  final repository = ref.watch(kitchenOrdersRepositoryProvider);
  return repository.getAveragePrepTimeInMinutes();
});

/// 상태별 주문 개수
final orderCountByStatusProvider =
    FutureProvider<Map<String, int>>((ref) {
  final repository = ref.watch(kitchenOrdersRepositoryProvider);
  return repository.getOrderCountByStatus();
});

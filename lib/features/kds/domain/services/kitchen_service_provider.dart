import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/app_database.dart';
import '../../data/kitchen_orders_providers.dart';
import 'kitchen_service.dart';

/// Kitchen Service Provider
final kitchenServiceProvider = Provider<KitchenService>((ref) {
  final repository = ref.watch(kitchenOrdersRepositoryProvider);
  return KitchenService(repository);
});

/// Kitchen Performance Provider (실시간 통계)
/// Fix race condition: async* { await for ... } 패턴에서 POS 백그라운드 시
/// 스트림 이벤트 miss 문제 해결 → watchAllOrders().asyncMap 단일 스트림 패턴
final kitchenPerformanceProvider =
    StreamProvider<KitchenPerformance>((ref) {
  final dao = ref.watch(kitchenOrdersDaoProvider);
  final repository = ref.watch(kitchenOrdersRepositoryProvider);

  return dao.watchAllOrders().asyncMap((allOrders) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    // 오늘 SERVED된 주문 수 (Dart 레벨 날짜 필터링 — Web sql.js 호환)
    final todayServed = allOrders
        .where((KitchenOrder o) =>
            o.status == 'SERVED' &&
            o.servedAt != null &&
            !o.servedAt!.isBefore(startOfDay))
        .length;

    // 기존 activeOrders, avgPrepTime 계산 로직 유지
    final pendingCount =
        allOrders.where((KitchenOrder o) => o.status == 'PENDING').length;
    final preparingCount =
        allOrders.where((KitchenOrder o) => o.status == 'PREPARING').length;
    final readyCount =
        allOrders.where((KitchenOrder o) => o.status == 'READY').length;

    final avgPrepTime = await repository.getAveragePrepTimeInMinutes();

    return KitchenPerformance(
      todayServedCount: todayServed,
      averagePrepTimeMinutes: avgPrepTime,
      pendingCount: pendingCount,
      preparingCount: preparingCount,
      readyCount: readyCount,
    );
  });
});

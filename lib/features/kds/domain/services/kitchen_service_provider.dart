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
/// Fix #3: watchAllOrders (SERVED 포함) 감시 → Completed 카운트 실시간 반영
final kitchenPerformanceProvider =
    StreamProvider<KitchenPerformance>((ref) async* {
  final dao = ref.watch(kitchenOrdersDaoProvider);
  final repository = ref.watch(kitchenOrdersRepositoryProvider);

  // watchActiveOrders()는 SERVED로 바뀔 때 이벤트 발생하지만,
  // POS 직접결제(kitchen order 없음)나 동일 세션 내 변화 미감지 케이스 보완을 위해
  // watchTodayServedCount()도 함께 구독 → served 변화 시 즉시 반영
  await for (final _ in dao.watchTodayServedCount()) {
    final activeOrders = await repository.getActiveOrders();
    final pendingCount =
        activeOrders.where((KitchenOrder o) => o.status == 'PENDING').length;
    final preparingCount =
        activeOrders.where((KitchenOrder o) => o.status == 'PREPARING').length;
    final readyCount =
        activeOrders.where((KitchenOrder o) => o.status == 'READY').length;

    final todayServed = await repository.getTodayServedCount();
    final avgPrepTime = await repository.getAveragePrepTimeInMinutes();

    yield KitchenPerformance(
      todayServedCount: todayServed,
      averagePrepTimeMinutes: avgPrepTime,
      pendingCount: pendingCount,
      preparingCount: preparingCount,
      readyCount: readyCount,
    );
  }
});

import 'package:flutter/foundation.dart' show debugPrint;
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
/// Fix #3: watchTodayServedCount() 스트림을 trigger로 사용
/// → SERVED 상태 변경 시 즉시 반영 (POS 오른쪽 상단 completed 카운트 갱신)
final kitchenPerformanceProvider =
    StreamProvider<KitchenPerformance>((ref) async* {
  final dao = ref.watch(kitchenOrdersDaoProvider);
  final repository = ref.watch(kitchenOrdersRepositoryProvider);

  // watchTodayServedCount()를 trigger로 사용:
  // SERVED 상태 변경 시 즉시 발동 → POS badge 실시간 반영
  await for (final todayServed in dao.watchTodayServedCount()) {
    try {
      final activeOrders = await repository.getActiveOrders();
      final pendingCount =
          activeOrders.where((KitchenOrder o) => o.status == 'PENDING').length;
      final preparingCount =
          activeOrders.where((KitchenOrder o) => o.status == 'PREPARING').length;
      final readyCount =
          activeOrders.where((KitchenOrder o) => o.status == 'READY').length;

      final avgPrepTime = await repository.getAveragePrepTimeInMinutes();

      debugPrint('[KDS] stream fired: todayServed=$todayServed pending=$pendingCount preparing=$preparingCount ready=$readyCount');

      yield KitchenPerformance(
        todayServedCount: todayServed,
        averagePrepTimeMinutes: avgPrepTime,
        pendingCount: pendingCount,
        preparingCount: preparingCount,
        readyCount: readyCount,
      );
    } catch (e) {
      debugPrint('[KitchenPerformance] stream error (skipped): $e');
    }
  }
});

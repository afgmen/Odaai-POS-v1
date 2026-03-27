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
/// StreamProvider: active orders 변경 시 자동 갱신
final kitchenPerformanceProvider =
    StreamProvider<KitchenPerformance>((ref) async* {
  final dao = ref.watch(kitchenOrdersDaoProvider);
  final repository = ref.watch(kitchenOrdersRepositoryProvider);

  await for (final orders in dao.watchActiveOrders()) {
    final pendingCount =
        orders.where((KitchenOrder o) => o.status == 'PENDING').length;
    final preparingCount =
        orders.where((KitchenOrder o) => o.status == 'PREPARING').length;
    final readyCount =
        orders.where((KitchenOrder o) => o.status == 'READY').length;

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

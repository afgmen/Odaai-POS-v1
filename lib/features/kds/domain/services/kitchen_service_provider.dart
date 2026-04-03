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
/// Fix #3 v3: async* generator 대신 watchAllOrders().asyncMap() 직접 변환
/// - async* + await for 패턴이 Riverpod StreamProvider에서 초기 emit 실패 가능
/// - watchAllOrders() table-level watcher → 모든 상태 변경에 반응
/// - Dart 레벨 필터링 → SQL datetime 비교 문제 회피
final kitchenPerformanceProvider =
    StreamProvider<KitchenPerformance>((ref) {
  final dao = ref.watch(kitchenOrdersDaoProvider);
  final repository = ref.watch(kitchenOrdersRepositoryProvider);

  return dao.watchAllOrders().asyncMap((allOrders) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final todayServedCount = allOrders
        .where((KitchenOrder o) =>
            o.status == 'SERVED' &&
            o.servedAt != null &&
            !o.servedAt!.isBefore(startOfDay))
        .length;

    final pendingCount =
        allOrders.where((KitchenOrder o) => o.status == 'PENDING').length;
    final preparingCount =
        allOrders.where((KitchenOrder o) => o.status == 'PREPARING').length;
    final readyCount =
        allOrders.where((KitchenOrder o) => o.status == 'READY').length;

    final avgPrepTime = await repository.getAveragePrepTimeInMinutes();

    debugPrint('[KDS] performance updated: todayServed=$todayServedCount pending=$pendingCount preparing=$preparingCount ready=$readyCount');

    return KitchenPerformance(
      todayServedCount: todayServedCount,
      averagePrepTimeMinutes: avgPrepTime,
      pendingCount: pendingCount,
      preparingCount: preparingCount,
      readyCount: readyCount,
    );
  });
});

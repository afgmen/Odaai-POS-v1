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
/// Fix #3 v5: watchActiveOrders() 기반으로 전환 + todayServedCount는 watchTodayServedCount()
/// - watchAllOrders()가 TEXT 타임스탬프를 가진 SERVED 행 역직렬화 시 stream-level 에러 발생
/// - watchActiveOrders()는 PENDING/PREPARING/READY 행만 읽음 → TEXT 타임스탬프 위험 없음
/// - todayServedCount는 DAO의 watchTodayServedCount()를 Future로 호출 (Dart 레벨 필터)
/// - asyncMap 전체 try-catch로 에러 발생 시 안전 기본값 반환 (stream 죽지 않음)
final kitchenPerformanceProvider =
    StreamProvider<KitchenPerformance>((ref) {
  final dao = ref.watch(kitchenOrdersDaoProvider);
  final repository = ref.watch(kitchenOrdersRepositoryProvider);

  return dao.watchActiveOrders().asyncMap((activeOrders) async {
    try {
      final pendingCount =
          activeOrders.where((KitchenOrder o) => o.status == 'PENDING').length;
      final preparingCount =
          activeOrders.where((KitchenOrder o) => o.status == 'PREPARING').length;
      final readyCount =
          activeOrders.where((KitchenOrder o) => o.status == 'READY').length;

      // todayServedCount: SERVED 행 직접 역직렬화 피하기 위해 servedAt 기준으로 조회
      int todayServedCount = 0;
      try {
        todayServedCount = await dao.countTodayServedSafe();
      } catch (e) {
        debugPrint('[KDS] countTodayServedSafe error: $e');
      }

      double avgPrepTime = 0.0;
      try {
        avgPrepTime = await repository.getAveragePrepTimeInMinutes();
      } catch (e) {
        debugPrint('[KDS] getAveragePrepTimeInMinutes error: $e');
      }

      debugPrint('[KDS] performance updated: todayServed=$todayServedCount pending=$pendingCount preparing=$preparingCount ready=$readyCount');

      return KitchenPerformance(
        todayServedCount: todayServedCount,
        averagePrepTimeMinutes: avgPrepTime,
        pendingCount: pendingCount,
        preparingCount: preparingCount,
        readyCount: readyCount,
      );
    } catch (e, st) {
      debugPrint('[KDS] performance asyncMap ERROR: $e\n$st');
      return KitchenPerformance(
        todayServedCount: 0,
        averagePrepTimeMinutes: 0.0,
        pendingCount: 0,
        preparingCount: 0,
        readyCount: 0,
      );
    }
  });
});

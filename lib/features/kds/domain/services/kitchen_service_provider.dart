import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/kitchen_orders_providers.dart';
import 'kitchen_service.dart';

/// Kitchen Service Provider
final kitchenServiceProvider = Provider<KitchenService>((ref) {
  final repository = ref.watch(kitchenOrdersRepositoryProvider);
  return KitchenService(repository);
});

/// Kitchen Performance Provider (통계)
final kitchenPerformanceProvider =
    FutureProvider<KitchenPerformance>((ref) {
  final service = ref.watch(kitchenServiceProvider);
  return service.getPerformance();
});

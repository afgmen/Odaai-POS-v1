import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/app_database.dart';
import '../../../kds/data/kitchen_orders_providers.dart';
import 'delivery_service_provider.dart';

/// Watches active KDS orders and forwards status changes to the delivery
/// middleware server whenever a KDS order is linked to a delivery order.
///
/// This provider must be kept alive (watched) from the app root so the
/// listener remains active while the app is running.
///
/// Mount in app_root_screen.dart:
/// ```dart
/// ref.watch(kdsDeliveryBridgeProvider);
/// ```
final kdsDeliveryBridgeProvider = Provider<void>((ref) {
  // Track the last-seen status for each KDS order id.
  // This lets us detect transitions rather than re-firing on every rebuild.
  final Map<int, String> lastStatus = {};

  ref.listen<AsyncValue<List<KitchenOrder>>>(
    activeOrdersStreamProvider,
    (previous, next) {
      next.whenData((orders) {
        final deliveryService = ref.read(deliveryServiceProvider);

        for (final order in orders) {
          final prev = lastStatus[order.id];
          final curr = order.status;

          if (prev != null && prev != curr) {
            // Status changed — notify delivery service.
            deliveryService.notifyKdsStatusChanged(order.id, curr);
          }

          lastStatus[order.id] = curr;
        }

        // Clean up ids that are no longer in active orders
        // (completed/cancelled orders drop out of activeOrdersStreamProvider).
        final activeIds = orders.map((o) => o.id).toSet();
        lastStatus.removeWhere((id, _) => !activeIds.contains(id));
      });
    },
    fireImmediately: true,
  );
});

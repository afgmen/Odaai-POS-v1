import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/delivery_orders_providers.dart';
import '../../data/models/delivery_order.dart';
import '../../domain/enums/delivery_platform.dart';
import '../../domain/enums/delivery_status.dart';

// ──────────────────────────────────────────────
// Filter state
// ──────────────────────────────────────────────

/// Currently selected platform filter (null = All).
final selectedPlatformFilterProvider =
    StateProvider<DeliveryPlatform?>((ref) => null);

/// Currently selected status filter (null = All active statuses).
final selectedStatusFilterProvider =
    StateProvider<DeliveryStatus?>((ref) => null);

/// Currently selected order (for detail modal).
final selectedDeliveryOrderProvider =
    StateProvider<DeliveryOrder?>((ref) => null);

// ──────────────────────────────────────────────
// Filtered orders
// ──────────────────────────────────────────────

/// All orders after applying platform + status filters.
final filteredDeliveryOrdersProvider =
    Provider<AsyncValue<List<DeliveryOrder>>>((ref) {
  final platformFilter = ref.watch(selectedPlatformFilterProvider);
  final statusFilter = ref.watch(selectedStatusFilterProvider);
  final allOrders = ref.watch(activeDeliveryOrdersProvider);

  return allOrders.whenData((orders) {
    var filtered = orders;

    if (platformFilter != null) {
      filtered =
          filtered.where((o) => o.platform == platformFilter).toList();
    }

    if (statusFilter != null) {
      filtered =
          filtered.where((o) => o.status == statusFilter).toList();
    }

    return filtered;
  });
});

// ──────────────────────────────────────────────
// Per-platform counts (for filter tabs)
// ──────────────────────────────────────────────

final _activeOrdersListProvider = Provider<List<DeliveryOrder>>((ref) {
  final orders = ref.watch(activeDeliveryOrdersProvider);
  return orders.valueOrNull ?? [];
});

final grabOrderCountProvider = Provider<int>((ref) {
  final orders = ref.watch(_activeOrdersListProvider);
  return orders.where((o) => o.platform == DeliveryPlatform.grab).length;
});

final shopeefoodOrderCountProvider = Provider<int>((ref) {
  final orders = ref.watch(_activeOrdersListProvider);
  return orders
      .where((o) => o.platform == DeliveryPlatform.shopeefood)
      .length;
});

final manualOrderCountProvider = Provider<int>((ref) {
  final orders = ref.watch(_activeOrdersListProvider);
  return orders.where((o) => o.platform == DeliveryPlatform.manual).length;
});

/// Count of NEW orders (for AppBar badge + nav badge).
final newOrderCountProvider = Provider<int>((ref) {
  final orders = ref.watch(_activeOrdersListProvider);
  return orders.where((o) => o.status == DeliveryStatus.newOrder).length;
});

/// Count of in-progress orders (ACCEPTED / PREPARING / READY_FOR_PICKUP).
final activeOrderCountProvider = Provider<int>((ref) {
  final orders = ref.watch(_activeOrdersListProvider);
  return orders.where((o) {
    return o.status == DeliveryStatus.accepted ||
        o.status == DeliveryStatus.preparing ||
        o.status == DeliveryStatus.readyForPickup;
  }).length;
});

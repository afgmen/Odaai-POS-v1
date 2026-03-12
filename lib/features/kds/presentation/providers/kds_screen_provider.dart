import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/order_status.dart';
import '../../data/kitchen_orders_providers.dart';
import '../../data/models/kitchen_order_with_items.dart';
import '../../data/models/menu_item_summary.dart';

/// 현재 선택된 필터 상태
final selectedFilterProvider =
    StateProvider<OrderStatus?>((ref) => null);

/// B-095: 필터링된 주문 목록 Provider (메뉴 아이템 포함)
/// - 필터 없음 / PENDING / PREPARING / READY → 활성 주문 스트림
/// - SERVED / CANCELLED → 전체 주문 스트림 (SERVED/CANCELLED 포함)
final filteredOrdersProvider =
    StreamProvider<List<KitchenOrderWithItems>>((ref) {
  final selectedFilter = ref.watch(selectedFilterProvider);

  // SERVED / CANCELLED 필터는 전체 주문 스트림에서 가져와야 함
  final isHistoryFilter = selectedFilter == OrderStatus.served ||
      selectedFilter == OrderStatus.cancelled;

  // 올바른 스트림을 직접 watch (async*+await future 대신 DAO stream 직접 반환)
  final dao = ref.watch(kitchenOrdersDaoProvider);

  if (selectedFilter == null) {
    // 필터 없음 = 활성 주문 전체 (PENDING/PREPARING/READY)
    return dao.watchActiveOrdersWithItems();
  } else if (isHistoryFilter) {
    // SERVED/CANCELLED: 전체 주문에서 해당 상태만 필터
    return dao.watchAllOrdersWithItems().map((orders) => orders
        .where((item) => item.order.status == selectedFilter.value)
        .toList());
  } else {
    // PENDING/PREPARING/READY: 활성 주문에서 해당 상태만 필터
    return dao.watchActiveOrdersWithItems().map((orders) => orders
        .where((item) => item.order.status == selectedFilter.value)
        .toList());
  }
});

/// 선택된 주문 ID
final selectedOrderIdProvider = StateProvider<int?>((ref) => null);

/// 주문 상세 모달 표시 상태
final showOrderDetailProvider = StateProvider<bool>((ref) => false);

/// Toggle for showing the menu item summary panel
final showMenuSummaryPanelProvider = StateProvider<bool>((ref) => false);

/// Aggregated menu item summaries from all active orders.
///
/// Groups all active order items by product name and calculates
/// quantity breakdowns by status (pending, preparing, ready).
final menuItemSummaryProvider =
    StreamProvider<List<MenuItemSummary>>((ref) async* {
  final ordersWithItems =
      await ref.watch(activeOrdersWithItemsStreamProvider.future);

  // Aggregate items by product name
  final Map<String, _MenuItemAccumulator> accumulator = {};

  for (final orderWithItems in ordersWithItems) {
    final status =
        OrderStatus.fromString(orderWithItems.order.status);

    for (final item in orderWithItems.items) {
      final name = item.productName;
      accumulator.putIfAbsent(name, () => _MenuItemAccumulator(name));

      final acc = accumulator[name]!;
      acc.totalQuantity += item.quantity;
      acc.orderIds.add(orderWithItems.order.id);

      switch (status) {
        case OrderStatus.pending:
          acc.pendingQuantity += item.quantity;
          break;
        case OrderStatus.preparing:
          acc.preparingQuantity += item.quantity;
          break;
        case OrderStatus.ready:
          acc.readyQuantity += item.quantity;
          break;
        default:
          break;
      }
    }
  }

  // Convert to sorted list (highest total quantity first)
  final summaries = accumulator.values
      .map((acc) => MenuItemSummary(
            productName: acc.productName,
            totalQuantity: acc.totalQuantity,
            pendingQuantity: acc.pendingQuantity,
            preparingQuantity: acc.preparingQuantity,
            readyQuantity: acc.readyQuantity,
            orderCount: acc.orderIds.length,
          ))
      .toList()
    ..sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));

  yield summaries;
});

/// Internal accumulator for building menu item summaries.
class _MenuItemAccumulator {
  final String productName;
  int totalQuantity = 0;
  int pendingQuantity = 0;
  int preparingQuantity = 0;
  int readyQuantity = 0;
  final Set<int> orderIds = {};

  _MenuItemAccumulator(this.productName);
}

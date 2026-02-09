import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/order_status.dart';
import '../../../../database/app_database.dart';
import '../../data/kitchen_orders_providers.dart';
import '../../data/models/kitchen_order_with_items.dart';

/// 현재 선택된 필터 상태
final selectedFilterProvider =
    StateProvider<OrderStatus?>((ref) => null);

/// 필터링된 주문 목록 Provider (메뉴 아이템 포함)
final filteredOrdersProvider =
    StreamProvider<List<KitchenOrderWithItems>>((ref) async* {
  final selectedFilter = ref.watch(selectedFilterProvider);
  final ordersWithItems = await ref.watch(activeOrdersWithItemsStreamProvider.future);

  if (selectedFilter == null) {
    // 필터 없음 = 활성 주문 전체
    yield ordersWithItems;
  } else {
    // 특정 상태 필터
    final filtered = ordersWithItems
        .where((item) => item.order.status == selectedFilter.value)
        .toList();
    yield filtered;
  }
});

/// 선택된 주문 ID
final selectedOrderIdProvider = StateProvider<int?>((ref) => null);

/// 주문 상세 모달 표시 상태
final showOrderDetailProvider = StateProvider<bool>((ref) => false);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/services/kitchen_service_provider.dart';
import '../providers/kds_screen_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/filter_tabs.dart';
import '../widgets/order_detail_modal.dart';
import '../widgets/performance_header.dart';

/// KDS (Kitchen Display System) 메인 화면
class KdsScreen extends ConsumerWidget {
  const KdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredOrders = ref.watch(filteredOrdersProvider);
    final selectedOrderId = ref.watch(selectedOrderIdProvider);
    final showDetail = ref.watch(showOrderDetailProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('주방 디스플레이 시스템'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // 성능 통계 표시
          const PerformanceHeader(),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // 상태 필터 탭
          const FilterTabs(),

          // 주문 목록
          Expanded(
            child: filteredOrders.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '주문이 없습니다',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3열 그리드
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final orderWithItems = orders[index];
                    return OrderCard(
                      orderWithItems: orderWithItems,
                      onTap: () {
                        ref.read(selectedOrderIdProvider.notifier).state =
                            orderWithItems.order.id;
                        ref.read(showOrderDetailProvider.notifier).state = true;
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('오류 발생: $error'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // 주문 상세 모달
      bottomSheet: showDetail && selectedOrderId != null
          ? OrderDetailModal(orderId: selectedOrderId)
          : null,
    );
  }
}

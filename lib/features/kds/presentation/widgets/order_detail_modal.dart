import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/enums/order_priority.dart';
import '../../domain/services/kitchen_service_provider.dart';
import '../../data/kitchen_orders_providers.dart';
import '../../data/kitchen_cancellation_provider.dart';
import '../../data/models/kitchen_order_with_items.dart';
import '../providers/kds_screen_provider.dart';
import '../../../../database/app_database.dart';
import '../../../pos/presentation/modals/cancel_reason_modal.dart';

/// 주문 상세 모달
class OrderDetailModal extends ConsumerWidget {
  final int orderId;

  const OrderDetailModal({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(kitchenOrdersDaoProvider);
    final service = ref.watch(kitchenServiceProvider);

    return FutureBuilder<KitchenOrderWithItems?>(
      // B-097: getOrderWithItems로 아이템 목록도 함께 로드
      future: dao.getOrderWithItems(orderId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final order = snapshot.data!.order;
        final orderItems = snapshot.data!.items;
        final status = OrderStatus.fromString(order.status);
        final priority = OrderPriority.fromString(order.priority);

        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.tableNumber ?? 'Takeaway #${order.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        ref.read(showOrderDetailProvider.notifier).state =
                            false;
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 주문 정보
                      _buildInfoRow(
                        'Order Time',
                        DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt),
                      ),
                      _buildInfoRow('Status', status.displayName),
                      _buildInfoRow('Priority', priority.displayName),
                      if (order.specialInstructions != null &&
                          order.specialInstructions!.isNotEmpty)
                        _buildInfoRow('Special Request', order.specialInstructions!),

                      const Divider(height: 32),

                      // B-097: 주문 아이템 목록 (10개 이상도 스크롤 가능)
                      Row(
                        children: [
                          const Icon(Icons.restaurant_menu, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            'Order Items (${orderItems.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (orderItems.isEmpty)
                        const Text(
                          'No items',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        Container(
                          constraints: const BoxConstraints(maxHeight: 400),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: orderItems.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (context, index) {
                              final item = orderItems[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.productName,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'x${item.quantity}',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                      const Divider(height: 32),

                      // 타임라인
                      const Text(
                        'Timeline',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTimeline(order),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // 액션 버튼
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 취소 버튼 (완료 상태가 아닐 때만)
                    if (status != OrderStatus.served &&
                        status != OrderStatus.cancelled)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final reason = await _promptCancelReason(context);
                            if (reason == null) return;

                            final cancelled = await service.cancelOrder(
                              orderId,
                              reason: reason,
                            );
                            if (cancelled && context.mounted) {
                              // B-UAT: 취소 알림을 Floor Plan에 전달
                              ref.read(kitchenCancellationProvider.notifier).addCancellation(
                                orderId: orderId,
                                saleId: order.saleId,
                                tableNumber: order.tableNumber,
                                reason: reason,
                              );
                              ref
                                  .read(showOrderDetailProvider.notifier)
                                  .state = false;
                            }
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancel Order'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),

                    if (status != OrderStatus.served &&
                        status != OrderStatus.cancelled)
                      const SizedBox(width: 12),

                    // 상태 전환 버튼
                    Expanded(
                      flex: 2,
                      child: _buildStatusButton(
                        context,
                        ref,
                        service,
                        order,
                        status,
                        isDelivery: order.orderType == 'phoneDelivery' || order.orderType == 'platformDelivery',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(KitchenOrder order) {
    return Column(
      children: [
        _buildTimelineItem(
          'Order Received',
          order.createdAt,
          true,
          Colors.orange,
        ),
        if (order.startedAt != null)
          _buildTimelineItem(
            'Preparing Started',
            order.startedAt!,
            true,
            Colors.blue,
          ),
        if (order.readyAt != null)
          _buildTimelineItem(
            'Ready',
            order.readyAt!,
            true,
            Colors.green,
          ),
        if (order.servedAt != null)
          _buildTimelineItem(
            'Served',
            order.servedAt!,
            true,
            Colors.grey,
          ),
        if (order.cancelledAt != null)
          _buildTimelineItem(
            'Cancelled',
            order.cancelledAt!,
            true,
            Colors.red,
          ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String label,
    DateTime time,
    bool isCompleted,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? color : Colors.grey.shade300,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
                color: isCompleted ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
          Text(
            DateFormat('HH:mm:ss').format(time),
            style: TextStyle(
              fontSize: 12,
              color: isCompleted ? Colors.black54 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    WidgetRef ref,
    dynamic service,
    KitchenOrder order,
    OrderStatus status, {
    bool isDelivery = false,
  }) {
    switch (status) {
      case OrderStatus.pending:
        return ElevatedButton.icon(
          onPressed: () async {
            await service.startPreparing(order.id);
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Preparing'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
        );

      case OrderStatus.preparing:
        return ElevatedButton.icon(
          onPressed: () async {
            await service.markAsReady(order.id);
          },
          icon: const Icon(Icons.check),
          label: const Text('Mark Ready'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
        );

      case OrderStatus.ready:
        return ElevatedButton.icon(
          onPressed: () async {
            await service.markAsServed(order.id);
            if (context.mounted) {
              ref.read(showOrderDetailProvider.notifier).state = false;
            }
          },
          icon: const Icon(Icons.done_all),
          label: Text(isDelivery ? 'Mark Delivered' : 'Mark Served'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
        );

      case OrderStatus.served:
      case OrderStatus.cancelled:
        return ElevatedButton(
          onPressed: () {
            ref.read(showOrderDetailProvider.notifier).state = false;
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
          child: const Text('Close'),
        );
    }
  }

  Future<String?> _promptCancelReason(BuildContext context) async {
    String? selectedReason;
    await showDialog<void>(
      context: context,
      builder: (ctx) => CancelReasonModal(
        onConfirm: (reason) async {
          selectedReason = reason;
        },
      ),
    );
    return selectedReason;
  }
}

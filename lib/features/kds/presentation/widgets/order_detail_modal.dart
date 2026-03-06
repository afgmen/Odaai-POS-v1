import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/enums/order_priority.dart';
import '../../domain/services/kitchen_service_provider.dart';
import '../../data/kitchen_orders_providers.dart';
import '../providers/kds_screen_provider.dart';
import '../../../../database/app_database.dart';

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

    return FutureBuilder<KitchenOrder?>(
      future: dao.getOrderById(orderId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final order = snapshot.data!;
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
                            // Show cancel reason dialog first
                            final reason = await _showCancelReasonDialog(context);
                            if (reason != null && reason.isNotEmpty) {
                              await service.cancelOrder(orderId);
                              debugPrint('[KDS Cancel] Order $orderId: $reason');
                              if (context.mounted) {
                                ref
                                    .read(showOrderDetailProvider.notifier)
                                    .state = false;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Order cancelled: $reason')),
                                );
                              }
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
    OrderStatus status,
  ) {
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
          label: const Text('Mark Served'),
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

  Future<bool?> _showConfirmDialog(BuildContext context, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }


  /// Show dialog to input cancel reason
  static Future<String?> _showCancelReasonDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Reason'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              reasonController.dispose();
              Navigator.pop(ctx, null);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              reasonController.dispose();
              Navigator.pop(ctx, reason);
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }


  /// Show dialog to input cancel reason
  static Future<String?> _showCancelReasonDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Reason'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              reasonController.dispose();
              Navigator.pop(ctx, null);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              reasonController.dispose();
              Navigator.pop(ctx, reason);
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }
}

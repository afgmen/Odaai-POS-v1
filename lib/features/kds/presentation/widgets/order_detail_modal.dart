import 'package:flutter/material.dart';
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
                      order.tableNumber ?? '포장 #${order.id}',
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
                        '주문 시간',
                        DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt),
                      ),
                      _buildInfoRow('상태', status.displayName),
                      _buildInfoRow('우선순위', priority.displayName),
                      if (order.specialInstructions != null &&
                          order.specialInstructions!.isNotEmpty)
                        _buildInfoRow('특별 요청', order.specialInstructions!),

                      const Divider(height: 32),

                      // 타임라인
                      const Text(
                        '처리 내역',
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
                            final confirm = await _showConfirmDialog(
                              context,
                              '주문을 취소하시겠습니까?',
                            );
                            if (confirm == true) {
                              await service.cancelOrder(orderId);
                              if (context.mounted) {
                                ref
                                    .read(showOrderDetailProvider.notifier)
                                    .state = false;
                              }
                            }
                          },
                          icon: const Icon(Icons.cancel),
                          label: const Text('취소'),
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
          '주문 접수',
          order.createdAt,
          true,
          Colors.orange,
        ),
        if (order.startedAt != null)
          _buildTimelineItem(
            '조리 시작',
            order.startedAt!,
            true,
            Colors.blue,
          ),
        if (order.readyAt != null)
          _buildTimelineItem(
            '조리 완료',
            order.readyAt!,
            true,
            Colors.green,
          ),
        if (order.servedAt != null)
          _buildTimelineItem(
            '서빙 완료',
            order.servedAt!,
            true,
            Colors.grey,
          ),
        if (order.cancelledAt != null)
          _buildTimelineItem(
            '취소됨',
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
          label: const Text('조리 시작'),
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
          label: const Text('조리 완료'),
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
          label: const Text('서빙 완료'),
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
          child: const Text('닫기'),
        );
    }
  }

  Future<bool?> _showConfirmDialog(BuildContext context, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('확인'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('예'),
          ),
        ],
      ),
    );
  }
}

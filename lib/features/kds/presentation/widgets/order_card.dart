import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../database/app_database.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/enums/order_priority.dart';
import '../../data/models/kitchen_order_with_items.dart';

/// 주문 카드 위젯
class OrderCard extends StatelessWidget {
  final KitchenOrderWithItems orderWithItems;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.orderWithItems,
    required this.onTap,
  });

  KitchenOrder get order => orderWithItems.order;

  @override
  Widget build(BuildContext context) {
    final status = OrderStatus.fromString(order.status);
    final priority = OrderPriority.fromString(order.priority);
    final statusColor = Color(int.parse(status.colorHex.replaceFirst('#', '0xFF')));
    final elapsedTime = _calculateElapsedTime();

    return Card(
      elevation: priority.isUrgent ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: priority.isUrgent
            ? BorderSide(color: Colors.red, width: 3)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: priority.isUrgent
                ? Colors.red.withOpacity(0.05)
                : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 테이블 번호 + 우선순위
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 테이블 번호
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.tableNumber ?? '포장 #${order.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  // 긴급 아이콘
                  if (priority.isUrgent)
                    const Icon(
                      Icons.priority_high,
                      color: Colors.red,
                      size: 32,
                    ),
                ],
              ),

              const Spacer(),

              // 주문 시간
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm').format(order.createdAt),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 경과 시간 (경고 표시)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getElapsedTimeColor(elapsedTime),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$elapsedTime 분 경과',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 메뉴 목록
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.restaurant, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '주문 메뉴 (${orderWithItems.totalQuantity}개)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...orderWithItems.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'x${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 상태 표시
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      color: statusColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // 특별 지시사항 (있을 경우)
              if (order.specialInstructions != null &&
                  order.specialInstructions!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sticky_note_2,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order.specialInstructions!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 경과 시간 계산 (분 단위)
  int _calculateElapsedTime() {
    final now = DateTime.now();
    final duration = now.difference(order.createdAt);
    return duration.inMinutes;
  }

  /// 경과 시간별 색상
  Color _getElapsedTimeColor(int minutes) {
    if (minutes >= 30) return Colors.red; // 30분 이상 = 빨강
    if (minutes >= 20) return Colors.orange; // 20분 이상 = 주황
    if (minutes >= 10) return Colors.amber; // 10분 이상 = 노랑
    return Colors.green; // 10분 미만 = 초록
  }

  /// 상태별 아이콘
  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_empty;
      case OrderStatus.preparing:
        return Icons.soup_kitchen;
      case OrderStatus.ready:
        return Icons.check_circle;
      case OrderStatus.served:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }
}

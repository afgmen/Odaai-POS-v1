import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pos/data/models/order_type.dart';
import '../../../pos/presentation/screens/pos_main_screen.dart';

/// NewOrderModal — 빈 테이블 탭 시 주문 유형 선택
/// Phase 2: 매장식사 / 포장 / 전화배달 / 플랫폼배달
class NewOrderModal extends ConsumerWidget {
  final RestaurantTable table;

  const NewOrderModal({super.key, required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(Icons.table_restaurant, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Text(
                '${l10n.newOrder} — Table ${table.tableNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select order type',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          // 주문 유형 선택 그리드
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.0,
            children: OrderType.values.map((type) {
              return _OrderTypeCard(
                orderType: type,
                onTap: () {
                  Navigator.pop(context);
                  // Phase 3: PosMainScreen으로 이동 (tableId, orderType 전달)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PosMainScreen(
                        tableId: table.id,
                        tableNumber: table.tableNumber,
                        orderType: type,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // 취소 버튼
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ),
        ],
      ),
    );
  }
}

/// 주문 유형 카드
class _OrderTypeCard extends StatelessWidget {
  final OrderType orderType;
  final VoidCallback onTap;

  const _OrderTypeCard({required this.orderType, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: orderType.color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: orderType.color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(orderType.icon, color: orderType.color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  orderType.displayNameEn,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: orderType.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../providers/loyalty_provider.dart';

/// 고객 로열티 포인트 카드 위젯
class PointCardWidget extends ConsumerWidget {
  final Customer customer;
  final VoidCallback? onViewHistory;
  final VoidCallback? onAdjustPoints;

  const PointCardWidget({
    super.key,
    required this.customer,
    this.onViewHistory,
    this.onAdjustPoints,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierAsync = ref.watch(customerTierProvider(customer.id));
    final amountToNextAsync = ref.watch(amountToNextTierProvider(customer.id));
    final currencyFormat = NumberFormat('#,###');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary,
              AppTheme.primary.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 고객 이름 & 등급
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    customer.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                tierAsync.when(
                  data: (tier) => _buildTierBadge(tier),
                  loading: () => const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                  error: (_, _) => const Icon(Icons.error, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(color: Colors.white70, thickness: 1),
            const SizedBox(height: 16),

            // 보유 포인트
            Row(
              children: [
                const Icon(Icons.stars, color: Colors.amberAccent, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Points Balance',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${currencyFormat.format(customer.points)}P',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 16),

            // 누적 구매액 & 구매 횟수
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Total Spent',
                    value: currencyFormat.format(customer.totalSpent),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.receipt_long,
                    label: 'Purchases',
                    value: '${customer.purchaseCount}x',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 다음 등급까지
            amountToNextAsync.when(
              data: (amountToNext) {
                if (amountToNext == null) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.amberAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Top tier reached! 🎉',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.trending_up, color: Colors.greenAccent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Until next tier',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(amountToNext),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // 액션 버튼
            Row(
              children: [
                if (onViewHistory != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onViewHistory,
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('Point History'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                if (onViewHistory != null && onAdjustPoints != null)
                  const SizedBox(width: 12),
                if (onAdjustPoints != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onAdjustPoints,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Adjust Points'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierBadge(MembershipTier tier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(int.parse('0xFF${tier.colorHex.substring(1)}')),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getTierIcon(tier.tierCode),
          const SizedBox(width: 6),
          Text(
            _getTierName(tier.tierCode),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getTierIcon(String tierCode) {
    IconData icon;
    switch (tierCode) {
      case 'bronze':
        icon = Icons.military_tech;
        break;
      case 'silver':
        icon = Icons.shield;
        break;
      case 'gold':
        icon = Icons.workspace_premium;
        break;
      case 'platinum':
        icon = Icons.diamond;
        break;
      default:
        icon = Icons.star;
    }
    return Icon(icon, color: Colors.white, size: 16);
  }

  String _getTierName(String tierCode) {
    switch (tierCode) {
      case 'bronze':
        return 'Bronze';
      case 'silver':
        return 'Silver';
      case 'gold':
        return 'Gold';
      case 'platinum':
        return 'Platinum';
      default:
        return tierCode.toUpperCase();
    }
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

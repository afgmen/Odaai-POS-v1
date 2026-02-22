import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/delivery_screen_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Stats bar: New orders count + Active (in-progress) count.
class DeliveryStatsHeader extends ConsumerWidget {
  const DeliveryStatsHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final newCount = ref.watch(newOrderCountProvider);
    final activeCount = ref.watch(activeOrderCountProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          _StatChip(
            label: l10n.deliveryNewOrders,
            count: newCount,
            color: const Color(0xFF2196F3),
            icon: Icons.notifications_active,
          ),
          const SizedBox(width: 12),
          _StatChip(
            label: l10n.deliveryActiveOrders,
            count: activeCount,
            color: const Color(0xFFFF9800),
            icon: Icons.soup_kitchen,
          ),
          const Spacer(),
          // WebSocket connection status dot is shown in the AppBar
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

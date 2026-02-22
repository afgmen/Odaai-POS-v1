import 'package:flutter/material.dart';
import '../../data/models/menu_item_summary.dart';

/// A compact card displaying the aggregated status of a single menu item
/// across all active kitchen orders.
///
/// Shows the item name, total quantity, order count, and a visual breakdown
/// of quantities by status (pending / preparing / ready).
class MenuItemSummaryCard extends StatelessWidget {
  final MenuItemSummary summary;

  const MenuItemSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name + total quantity badge
          Row(
            children: [
              Expanded(
                child: Text(
                  summary.productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'x${summary.totalQuantity}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Order count
          Text(
            '${summary.orderCount} order${summary.orderCount == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 8),

          // Status progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (summary.pendingQuantity > 0)
                    Expanded(
                      flex: summary.pendingQuantity,
                      child: Container(color: const Color(0xFFFF9800)), // Orange
                    ),
                  if (summary.preparingQuantity > 0)
                    Expanded(
                      flex: summary.preparingQuantity,
                      child: Container(color: const Color(0xFF2196F3)), // Blue
                    ),
                  if (summary.readyQuantity > 0)
                    Expanded(
                      flex: summary.readyQuantity,
                      child: Container(color: const Color(0xFF4CAF50)), // Green
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Status quantity chips
          Row(
            children: [
              if (summary.hasPending)
                _StatusChip(
                  label: '${summary.pendingQuantity}',
                  color: const Color(0xFFFF9800),
                  icon: Icons.hourglass_empty,
                ),
              if (summary.hasPreparing)
                _StatusChip(
                  label: '${summary.preparingQuantity}',
                  color: const Color(0xFF2196F3),
                  icon: Icons.soup_kitchen,
                ),
              if (summary.hasReady)
                _StatusChip(
                  label: '${summary.readyQuantity}',
                  color: const Color(0xFF4CAF50),
                  icon: Icons.check_circle,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small chip showing a status icon and quantity count.
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

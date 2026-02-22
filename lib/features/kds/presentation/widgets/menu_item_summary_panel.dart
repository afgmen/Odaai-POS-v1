import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/menu_item_summary.dart';
import '../providers/kds_screen_provider.dart';
import 'menu_item_summary_card.dart';

/// A side panel that displays an aggregated view of all active menu items
/// across current kitchen orders.
///
/// Shows each menu item with its total quantity, order count, and a visual
/// breakdown of quantities by status (pending / preparing / ready).
/// This gives the kitchen staff a bird's-eye view of what needs to be
/// prepared without having to scan individual order cards.
class MenuItemSummaryPanel extends ConsumerWidget {
  const MenuItemSummaryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaries = ref.watch(menuItemSummaryProvider);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Panel header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade700,
            ),
            child: Row(
              children: [
                const Icon(Icons.menu_book, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.kdsMenuSummaryTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Close button
                InkWell(
                  onTap: () {
                    ref.read(showMenuSummaryPanelProvider.notifier).state =
                        false;
                  },
                  child: const Icon(Icons.close, color: Colors.white70, size: 20),
                ),
              ],
            ),
          ),

          // Legend row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _LegendDot(
                  color: const Color(0xFFFF9800),
                  label: l10n.kdsStatusPending,
                ),
                const SizedBox(width: 12),
                _LegendDot(
                  color: const Color(0xFF2196F3),
                  label: l10n.kdsStatusPreparing,
                ),
                const SizedBox(width: 12),
                _LegendDot(
                  color: const Color(0xFF4CAF50),
                  label: l10n.kdsStatusReady,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Summary list
          Expanded(
            child: summaries.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.kdsMenuSummaryEmpty,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length + 1, // +1 for totals header
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _TotalsHeader(items: items, l10n: l10n);
                    }
                    return MenuItemSummaryCard(
                      summary: items[index - 1],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  l10n.kdsErrorOccurred(error),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Totals summary card at the top of the panel.
class _TotalsHeader extends StatelessWidget {
  final List<MenuItemSummary> items;
  final AppLocalizations l10n;

  const _TotalsHeader({required this.items, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final totalItems = items.fold<int>(0, (sum, i) => sum + i.totalQuantity);
    final totalPending = items.fold<int>(0, (sum, i) => sum + i.pendingQuantity);
    final totalPreparing =
        items.fold<int>(0, (sum, i) => sum + i.preparingQuantity);
    final totalReady = items.fold<int>(0, (sum, i) => sum + i.readyQuantity);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade600, Colors.blueGrey.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.kdsMenuSummaryTotalItems,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                '$totalItems',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${items.length} ${l10n.kdsMenuSummaryUniqueItems}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Mini status breakdown
          Row(
            children: [
              _MiniStat(
                count: totalPending,
                color: const Color(0xFFFF9800),
              ),
              const SizedBox(width: 8),
              _MiniStat(
                count: totalPreparing,
                color: const Color(0xFF2196F3),
              ),
              const SizedBox(width: 8),
              _MiniStat(
                count: totalReady,
                color: const Color(0xFF4CAF50),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small stat indicator showing a count with a colored background.
class _MiniStat extends StatelessWidget {
  final int count;
  final Color color;

  const _MiniStat({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            '$count',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small colored dot with a label for the status legend.
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

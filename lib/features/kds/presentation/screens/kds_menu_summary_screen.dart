import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/menu_item_summary.dart';
import '../providers/kds_screen_provider.dart';

/// Full-screen KDS Menu Summary view designed for a dedicated second tablet
/// in the kitchen.
///
/// Shows an aggregated, menu-item-level summary of all active orders in a
/// large, easy-to-read grid. Reuses [menuItemSummaryProvider] for real-time
/// updates without duplicating aggregation logic.
class KdsMenuSummaryScreen extends ConsumerWidget {
  const KdsMenuSummaryScreen({super.key});

  static const Color _pendingColor = Color(0xFFFF9800);
  static const Color _preparingColor = Color(0xFF2196F3);
  static const Color _readyColor = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summaryAsync = ref.watch(menuItemSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: summaryAsync.when(
          data: (summaries) => _AppBarTitle(
            l10n: l10n,
            summaries: summaries,
          ),
          loading: () => Text(l10n.kdsMenuSummaryScreenTitle),
          error: (e, st) => Text(l10n.kdsMenuSummaryScreenTitle),
        ),
      ),
      body: summaryAsync.when(
        data: (summaries) {
          if (summaries.isEmpty) {
            return _EmptyState(l10n: l10n);
          }
          return Column(
            children: [
              _SummaryBar(summaries: summaries, l10n: l10n),
              Expanded(
                child: _MenuSummaryGrid(summaries: summaries, l10n: l10n),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(l10n.kdsErrorOccurred(error.toString())),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppBar title with item/menu count badges
// ---------------------------------------------------------------------------

class _AppBarTitle extends StatelessWidget {
  final AppLocalizations l10n;
  final List<MenuItemSummary> summaries;

  const _AppBarTitle({required this.l10n, required this.summaries});

  @override
  Widget build(BuildContext context) {
    final totalItems =
        summaries.fold<int>(0, (sum, s) => sum + s.totalQuantity);
    final uniqueMenus = summaries.length;

    return Row(
      children: [
        Text(l10n.kdsMenuSummaryScreenTitle),
        const SizedBox(width: 12),
        _AppBarBadge(
          label: l10n.kdsTotalItems,
          value: '$totalItems',
          color: Colors.white24,
        ),
        const SizedBox(width: 8),
        _AppBarBadge(
          label: '',
          value: l10n.kdsUniqueMenus(uniqueMenus),
          color: Colors.white24,
        ),
      ],
    );
  }
}

class _AppBarBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AppBarBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.isEmpty ? value : '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Horizontal summary bar showing total quantities by status
// ---------------------------------------------------------------------------

class _SummaryBar extends StatelessWidget {
  final List<MenuItemSummary> summaries;
  final AppLocalizations l10n;

  const _SummaryBar({required this.summaries, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final totalPending =
        summaries.fold<int>(0, (sum, s) => sum + s.pendingQuantity);
    final totalPreparing =
        summaries.fold<int>(0, (sum, s) => sum + s.preparingQuantity);
    final totalReady =
        summaries.fold<int>(0, (sum, s) => sum + s.readyQuantity);

    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _SummaryBarItem(
            icon: Icons.hourglass_empty,
            label: l10n.kdsStatusPending,
            count: totalPending,
            color: KdsMenuSummaryScreen._pendingColor,
          ),
          const SizedBox(width: 24),
          _SummaryBarItem(
            icon: Icons.soup_kitchen,
            label: l10n.kdsStatusPreparing,
            count: totalPreparing,
            color: KdsMenuSummaryScreen._preparingColor,
          ),
          const SizedBox(width: 24),
          _SummaryBarItem(
            icon: Icons.check_circle,
            label: l10n.kdsStatusReady,
            count: totalReady,
            color: KdsMenuSummaryScreen._readyColor,
          ),
        ],
      ),
    );
  }
}

class _SummaryBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _SummaryBarItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: $count',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Adaptive grid of large menu item cards
// ---------------------------------------------------------------------------

class _MenuSummaryGrid extends StatelessWidget {
  final List<MenuItemSummary> summaries;
  final AppLocalizations l10n;

  const _MenuSummaryGrid({required this.summaries, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: summaries.length,
      itemBuilder: (context, index) {
        return _LargeMenuItemCard(
          summary: summaries[index],
          l10n: l10n,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Large, kitchen-readable menu item card
// ---------------------------------------------------------------------------

class _LargeMenuItemCard extends StatelessWidget {
  final MenuItemSummary summary;
  final AppLocalizations l10n;

  const _LargeMenuItemCard({required this.summary, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name + total quantity badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  summary.productName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade700,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'x${summary.totalQuantity}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Order count
          Text(
            l10n.kdsOrders(summary.orderCount),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 12),

          // Stacked progress bar
          _ProgressBar(summary: summary),

          const SizedBox(height: 12),

          // Status breakdown rows
          if (summary.hasPending)
            _StatusRow(
              icon: Icons.hourglass_empty,
              label: l10n.kdsStatusPending,
              count: summary.pendingQuantity,
              color: KdsMenuSummaryScreen._pendingColor,
            ),
          if (summary.hasPreparing)
            _StatusRow(
              icon: Icons.soup_kitchen,
              label: l10n.kdsStatusPreparing,
              count: summary.preparingQuantity,
              color: KdsMenuSummaryScreen._preparingColor,
            ),
          if (summary.hasReady)
            _StatusRow(
              icon: Icons.check_circle,
              label: l10n.kdsStatusReady,
              count: summary.readyQuantity,
              color: KdsMenuSummaryScreen._readyColor,
            ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final MenuItemSummary summary;

  const _ProgressBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            if (summary.pendingQuantity > 0)
              Expanded(
                flex: summary.pendingQuantity,
                child: Container(
                  color: KdsMenuSummaryScreen._pendingColor,
                ),
              ),
            if (summary.preparingQuantity > 0)
              Expanded(
                flex: summary.preparingQuantity,
                child: Container(
                  color: KdsMenuSummaryScreen._preparingColor,
                ),
              ),
            if (summary.readyQuantity > 0)
              Expanded(
                flex: summary.readyQuantity,
                child: Container(
                  color: KdsMenuSummaryScreen._readyColor,
                ),
              ),
            // Fallback when all quantities are 0 (shouldn't happen in practice)
            if (summary.totalQuantity == 0)
              Expanded(
                child: Container(color: Colors.grey.shade300),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.kdsMenuSummaryEmpty,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

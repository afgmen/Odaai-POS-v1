import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/currency_provider.dart';
import '../../data/daily_closing_dao.dart';

class ClosingSummaryCard extends ConsumerWidget {
  final SalesAggregation aggregation;
  final GlobalKey? tutorialKey;

  const ClosingSummaryCard({
    super.key,
    required this.aggregation,
    this.tutorialKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final priceFormatter = ref.watch(priceFormatterProvider);

    return Card(
      key: tutorialKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assessment, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.closingSummary,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildSummaryRow(
              context,
              l10n.totalTransactions,
              l10n.transactionsCount(aggregation.totalTransactions),
              icon: Icons.receipt_long,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              context,
              l10n.totalSales,
              priceFormatter.format(aggregation.totalSales),
              icon: Icons.attach_money,
              isHighlighted: true,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              context,
              l10n.averageTransaction,
              priceFormatter.format(aggregation.averageTransaction),
              icon: Icons.trending_up,
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildSummaryRow(
              context,
              l10n.taxTotal,
              priceFormatter.format(aggregation.totalTax),
              icon: Icons.account_balance,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              context,
              l10n.discountTotal,
              priceFormatter.format(aggregation.totalDiscount),
              icon: Icons.discount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 20 : 16,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
            color: isHighlighted ? Theme.of(context).primaryColor : null,
          ),
        ),
      ],
    );
  }
}

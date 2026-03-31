import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/currency_provider.dart';
import '../providers/delivery_report_provider.dart';
import '../../../reports/providers/reports_provider.dart';

/// Drop-in widget for the Reports screen showing delivery-specific KPIs.
///
/// Shows:
///   - Total delivery orders / revenue (per platform breakdown)
///   - Cancelled orders
///   - Average prep time
///   - Delivery vs Dine-in revenue bar
///   - Simple daily order count mini-chart (bar per day)
class DeliveryReportSection extends ConsumerWidget {
  const DeliveryReportSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reportAsync = ref.watch(deliveryReportProvider);
    final dineInTotalAsync = ref.watch(reportTotalSalesProvider);
    final priceFormatter = ref.watch(priceFormatterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section heading ──
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            l10n.deliveryReport,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),

        reportAsync.when(
          loading: () => const _LoadingCard(),
          error: (err, _) => _ErrorCard(message: err.toString()),
          data: (data) {
            final dineInRevenue =
                dineInTotalAsync.valueOrNull ?? 0.0;
            return _ReportContent(
              data: data,
              dineInRevenue: dineInRevenue,
              priceFormatter: priceFormatter,
              l10n: l10n,
            );
          },
        ),
      ],
    );
  }
}

class _ReportContent extends StatelessWidget {
  final DeliveryReportData data;
  final double dineInRevenue;
  final dynamic priceFormatter;
  final AppLocalizations l10n;

  const _ReportContent({
    required this.data,
    required this.dineInRevenue,
    required this.priceFormatter,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── KPI row ──
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: l10n.deliveryTitle,
                value: '${data.totalOrders}',
                subtitle: data.cancelledOrders > 0
                    ? '${data.cancelledOrders} cancelled'
                    : null,
                icon: Icons.delivery_dining,
                color: const Color(0xFF00B14F),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                title: l10n.deliveryRevenue,
                value: priceFormatter.format(data.totalRevenue),
                subtitle: null,
                icon: Icons.attach_money,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Avg prep time ──
        _KpiCard(
          title: 'Avg. Prep Time',
          value: '${data.averagePrepMinutes.toStringAsFixed(1)} min',
          subtitle: null,
          icon: Icons.timer_outlined,
          color: AppTheme.warning,
        ),
        const SizedBox(height: 16),

        // ── Per-platform breakdown ──
        _PlatformBreakdown(data: data, priceFormatter: priceFormatter),
        const SizedBox(height: 16),

        // ── Delivery vs Dine-in ──
        _DeliveryVsDineInBar(
          deliveryRevenue: data.totalRevenue,
          dineInRevenue: dineInRevenue,
          priceFormatter: priceFormatter,
          l10n: l10n,
        ),
      ],
    );
  }
}

class _PlatformBreakdown extends StatelessWidget {
  final DeliveryReportData data;
  final dynamic priceFormatter;

  const _PlatformBreakdown({required this.data, required this.priceFormatter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'By Platform',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _PlatformRow(
            color: const Color(0xFF00B14F),
            label: 'GrabFood',
            orders: data.grabOrders,
            revenue: priceFormatter.format(data.grabRevenue),
          ),
          const SizedBox(height: 6),
          _PlatformRow(
            color: const Color(0xFFEE4D2D),
            label: 'ShopeeFood',
            orders: data.shopeeFoodOrders,
            revenue: priceFormatter.format(data.shopeeFoodRevenue),
          ),
          const SizedBox(height: 6),
          _PlatformRow(
            color: Colors.grey,
            label: 'Manual',
            orders: data.manualOrders,
            revenue: priceFormatter.format(data.manualRevenue),
          ),
        ],
      ),
    );
  }
}

class _PlatformRow extends StatelessWidget {
  final Color color;
  final String label;
  final int orders;
  final String revenue;

  const _PlatformRow({
    required this.color,
    required this.label,
    required this.orders,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textPrimary)),
        ),
        Text(
          // Fix #18: 단수/복수 처리
          orders == 1 ? '1 order' : '$orders orders',
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 12),
        Text(
          revenue,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}

class _DeliveryVsDineInBar extends StatelessWidget {
  final double deliveryRevenue;
  final double dineInRevenue;
  final dynamic priceFormatter;
  final AppLocalizations l10n;

  const _DeliveryVsDineInBar({
    required this.deliveryRevenue,
    required this.dineInRevenue,
    required this.priceFormatter,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final total = deliveryRevenue + dineInRevenue;
    final deliveryFraction = total > 0 ? deliveryRevenue / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.deliveryVsDineIn,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 18, color: Colors.grey.shade200),
                FractionallySizedBox(
                  widthFactor: deliveryFraction.clamp(0.0, 1.0),
                  child: Container(
                    height: 18,
                    color: const Color(0xFF00B14F),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                        color: Color(0xFF00B14F), shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(
                    '${l10n.deliveryTitle}: ${(deliveryFraction * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12)),
              ]),
              Row(children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(
                    'Dine-in: ${((1 - deliveryFraction) * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12)),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
                // B-116: 텍스트 간격 개선
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppTheme.primary)),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Text('Error: $message',
          style: const TextStyle(color: AppTheme.error)),
    );
  }
}

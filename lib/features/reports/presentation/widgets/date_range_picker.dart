import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/reports_provider.dart';

/// Date range picker widget (chips + custom date range)
class DateRangePicker extends ConsumerWidget {
  const DateRangePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final period = ref.watch(reportPeriodProvider);
    final customRange = ref.watch(customDateRangeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 기간 칩
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ReportPeriod.values.map((p) {
            final isSelected = period == p;
            return InkWell(
              onTap: () {
                ref.read(reportPeriodProvider.notifier).state = p;
                if (p == ReportPeriod.custom) {
                  _showDateRangePicker(context, ref);
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primary : AppTheme.divider,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  _getLocalizedPeriodLabel(l10n, p),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // 커스텀 날짜 범위 표시
        if (period == ReportPeriod.custom) ...[
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _showDateRangePicker(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormat('yyyy.MM.dd').format(customRange.from)} ~ ${DateFormat('yyyy.MM.dd').format(customRange.to)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showDateRangePicker(BuildContext context, WidgetRef ref) async {
    final currentRange = ref.read(customDateRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: currentRange.from,
        end: currentRange.to,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(customDateRangeProvider.notifier).state = (
        from: picked.start,
        to: picked.end.add(const Duration(days: 1)),
      );
    }
  }

  String _getLocalizedPeriodLabel(AppLocalizations l10n, ReportPeriod period) {
    switch (period) {
      case ReportPeriod.today:
        return l10n.today;
      case ReportPeriod.week:
        return l10n.week;
      case ReportPeriod.month:
        return l10n.month;
      case ReportPeriod.custom:
        return l10n.customPeriod;
    }
  }
}

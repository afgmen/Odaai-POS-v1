import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/sales_provider.dart';
import 'sale_detail_screen.dart';

/// 주문 내역 목록 화면
class SalesHistoryScreen extends ConsumerWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(selectedDateFilterProvider);
    final salesAsync = ref.watch(salesListProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        titleSpacing: 16,
        title: Text(
          l10n.salesHistory,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),
      body: Column(
        children: [
          // ── 날짜 필터 Chip 행 ──────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: DateFilter.values.map((f) {
                final isSelected = filter == f;
                return Padding(
                  padding: EdgeInsets.only(right: f == DateFilter.values.last ? 0 : 8),
                  child: InkWell(
                    onTap: () => ref.read(selectedDateFilterProvider.notifier).state = f,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : AppTheme.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        f.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── 주문 리스트 ──────────────────────────────
          Expanded(
            child: salesAsync.when(
              data: (sales) {
                if (sales.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 56, color: AppTheme.textDisabled),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noSalesHistory,
                          style: const TextStyle(fontSize: 16, color: AppTheme.textDisabled),
                        ),
                      ],
                    ),
                  );
                }

                // 날짜별 그룹화 → 섹션 헤더
                final grouped = _groupByDate(sales);
                final dateKeys = grouped.keys.toList();

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: dateKeys.length,
                  itemBuilder: (context, i) {
                    final dateKey = dateKeys[i];
                    final daySales = grouped[dateKey]!;
                    final dayTotal = daySales.fold(0.0, (sum, s) => sum + s.total);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 날짜 섹션 헤더 ──────────────
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(l10n, dateKey),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                              ),
                              Text(
                                '${l10n.total} ₩${_fmt(dayTotal)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary),
                              ),
                            ],
                          ),
                        ),

                        // ── 해당 날짜의 주문 목록 ──────
                        ...daySales.map((sale) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: _SaleCard(sale: sale),
                        )),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: AppTheme.error),
                    const SizedBox(height: 8),
                    Text(l10n.msgError(err.toString()), style: const TextStyle(color: AppTheme.error)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 단일 주문 카드 ────────────────────────────────
class _SaleCard extends StatelessWidget {
  final Sale sale;
  const _SaleCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRefunded = sale.status == 'refunded';

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SaleDetailScreen(saleId: sale.id)),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            // 결제 방법 아이콘
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isRefunded ? const Color(0xFFFDEBEB) : const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _paymentIcon(sale.paymentMethod),
                size: 20,
                color: isRefunded ? AppTheme.error : AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),

            // 중앙: 주문번호 + 시간
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        sale.saleNumber,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                      if (isRefunded) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDEBEB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(l10n.refunded, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.error)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_fmtTime(sale.saleDate)} · ${_paymentLabel(l10n, sale.paymentMethod)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),

            // 우측: 금액
            Text(
              '₩${_fmt(sale.total)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isRefunded ? AppTheme.error : AppTheme.textPrimary,
                decoration: isRefunded ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 유틸리티 ──────────────────────────────────────

/// Sale 목록을 날짜별로 그룹화 (최근 날짜 먼저)
Map<DateTime, List<Sale>> _groupByDate(List<Sale> sales) {
  final map = <DateTime, List<Sale>>{};
  for (final sale in sales) {
    final day = DateTime(sale.saleDate.year, sale.saleDate.month, sale.saleDate.day);
    map.putIfAbsent(day, () => []).add(sale);
  }
  // 최근 날짜 먼저 정렬
  final sorted = map.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
  return Map.fromEntries(sorted);
}

String _fmt(double price) {
  return price.toInt().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

/// 날짜 포맷: 오늘이면 "오늘", 어제면 "어제", 아니면 MM/DD
String _formatDate(AppLocalizations l10n, DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  if (date == today) return l10n.today;
  if (date == yesterday) return l10n.yesterday;
  return l10n.dateMonth(date.month, date.day);
}

/// 시간 포맷 HH:MM
String _fmtTime(DateTime dt) => '${_p(dt.hour)}:${_p(dt.minute)}';
String _p(int v) => v.toString().padLeft(2, '0');

/// 결제 방법 → 아이콘
IconData _paymentIcon(String method) => switch (method) {
      'cash' => Icons.attach_money,
      'card' => Icons.credit_card,
      'qr' => Icons.qr_code,
      _ => Icons.payment,
    };

/// 결제 방법 → 라벨
String _paymentLabel(AppLocalizations l10n, String method) => switch (method) {
      'cash' => l10n.cash,
      'card' => l10n.card,
      'qr' => l10n.qr,
      _ => method,
    };

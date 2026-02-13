import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/responsive/responsive_helper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/permission_gate_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/currency_provider.dart';
import '../../../auth/domain/permission_modules.dart';
import '../../providers/dashboard_provider.dart';

/// 매출 대시보드 화면
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return PermissionGateWidget(
      permission: PermissionModules.REVENUE_DASHBOARD_VIEW,
      fallback: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.cardWhite,
          elevation: 0,
          titleSpacing: 16,
          title: Text(
            l10n.salesDashboard,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
        ),
        body: const Center(
          child: AccessDeniedCard(
            message: '매출 대시보드를 볼 권한이 없습니다',
          ),
        ),
      ),
      child: _DashboardScreenContent(),
    );
  }
}

class _DashboardScreenContent extends ConsumerWidget {
  const _DashboardScreenContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(dashboardFilterProvider);
    final priceFormatter = ref.watch(priceFormatterProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        titleSpacing: 16,
        title: Text(
          l10n.salesDashboard,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final deviceType = ResponsiveHelper.getDeviceType(constraints.maxWidth);
          final isWide = deviceType != DeviceType.mobile;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isWide ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 날짜 필터 ──────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: DashboardFilter.values.map((f) {
                      final isSelected = filter == f;
                      return Padding(
                        padding: EdgeInsets.only(
                            right: f == DashboardFilter.values.last ? 0 : 8),
                        child: InkWell(
                          onTap: () =>
                              ref.read(dashboardFilterProvider.notifier).state = f,
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
                              _getLocalizedFilterLabel(l10n, f),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                                color:
                                    isSelected ? Colors.white : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // ── 주요 통계 카드 (반응형) ──
                if (isWide)
                  Row(
                    children: [
                      Expanded(child: _totalSalesCard(ref, l10n, priceFormatter)),
                      const SizedBox(width: 10),
                      Expanded(child: _orderCountCard(ref, l10n)),
                      const SizedBox(width: 10),
                      Expanded(child: _avgOrderCard(ref, l10n, priceFormatter)),
                      const SizedBox(width: 10),
                      Expanded(child: _InventoryValueCompactCard()),
                    ],
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(child: _totalSalesCard(ref, l10n, priceFormatter)),
                      const SizedBox(width: 10),
                      Expanded(child: _orderCountCard(ref, l10n)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _avgOrderCard(ref, l10n, priceFormatter)),
                      const SizedBox(width: 10),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _InventoryValueCard(),
                ],
                const SizedBox(height: 20),

                // ── 결제 방법별 + 상품별 (태블릿: 가로, 모바일: 세로) ──
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(title: l10n.paymentMethodSales),
                            const SizedBox(height: 10),
                            _PaymentBreakdownSection(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle(title: l10n.productRanking),
                            const SizedBox(height: 10),
                            _TopSellingSection(),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  _SectionTitle(title: l10n.paymentMethodSales),
                  const SizedBox(height: 10),
                  _PaymentBreakdownSection(),
                  const SizedBox(height: 20),
                  _SectionTitle(title: l10n.productRanking),
                  const SizedBox(height: 10),
                  _TopSellingSection(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _getLocalizedFilterLabel(AppLocalizations l10n, DashboardFilter filter) {
    switch (filter) {
      case DashboardFilter.today:
        return l10n.today;
      case DashboardFilter.week:
        return l10n.week;
      case DashboardFilter.month:
        return l10n.month;
    }
  }
}

// ── Statistics Card Common Layout ────────────────────────
Widget _statCardLayout({
  required String title,
  required IconData icon,
  required Color color,
  required Color bgColor,
  required Widget valueWidget,
}) {
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
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        valueWidget,
      ],
    ),
  );
}

Widget _asyncDoubleWidget(AsyncValue<double> async, Color color, String Function(double) fmt, AppLocalizations l10n) {
  return async.when(
    data: (v) => Text(fmt(v), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
    loading: () => const SizedBox(height: 22, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))),
    error: (_, _) => Text(l10n.error, style: const TextStyle(fontSize: 16, color: AppTheme.error)),
  );
}

// ── 매출 합계 카드 ─────────────────────────────────
Widget _totalSalesCard(WidgetRef ref, AppLocalizations l10n, priceFormatter) {
  final async = ref.watch(totalSalesProvider);
  return _statCardLayout(
    title: l10n.totalSalesAmount,
    icon: Icons.attach_money,
    color: AppTheme.primary,
    bgColor: const Color(0xFFE8F0FE),
    valueWidget: _asyncDoubleWidget(async, AppTheme.primary, (v) => priceFormatter.format(v), l10n),
  );
}

// ── 주문 수 카드 ────────────────────────────────────
Widget _orderCountCard(WidgetRef ref, AppLocalizations l10n) {
  final async = ref.watch(orderCountProvider);
  return _statCardLayout(
    title: l10n.orderCount,
    icon: Icons.receipt_long,
    color: AppTheme.success,
    bgColor: const Color(0xFFE6FAF2),
    valueWidget: async.when(
      data: (v) => Text('$v${l10n.orderUnit}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.success)),
      loading: () => const SizedBox(height: 22, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))),
      error: (_, _) => Text(l10n.error, style: const TextStyle(fontSize: 16, color: AppTheme.error)),
    ),
  );
}

// ── 평균 주문금액 카드 ──────────────────────────────
Widget _avgOrderCard(WidgetRef ref, AppLocalizations l10n, priceFormatter) {
  final async = ref.watch(avgOrderProvider);
  return _statCardLayout(
    title: l10n.avgOrderAmount,
    icon: Icons.bar_chart,
    color: AppTheme.warning,
    bgColor: const Color(0xFFFFF3E0),
    valueWidget: _asyncDoubleWidget(async, AppTheme.warning, (v) => priceFormatter.format(v), l10n),
  );
}

// ── 재고 가치 카드 ──────────────────────────────────
class _InventoryValueCard extends ConsumerWidget {
  const _InventoryValueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncValue = ref.watch(inventoryValueProvider);
    final priceFormatter = ref.watch(priceFormatterProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2, size: 18, color: Color(0xFF7B1FA2)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.inventoryValue,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text(l10n.inventoryValueDesc,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
          asyncValue.when(
            data: (value) => Text(
              priceFormatter.format(value),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF7B1FA2)),
            ),
            loading: () => const SizedBox(
                width: 60,
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))),
            error: (_, _) =>
                Text(l10n.error, style: const TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

// ── 재고 가치 컴팩트 카드 (태블릿 가로 배치용) ─────────
class _InventoryValueCompactCard extends ConsumerWidget {
  const _InventoryValueCompactCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncValue = ref.watch(inventoryValueProvider);
    final priceFormatter = ref.watch(priceFormatterProvider);

    return _statCardLayout(
      title: l10n.inventoryValue,
      icon: Icons.inventory_2,
      color: const Color(0xFF7B1FA2),
      bgColor: const Color(0xFFF3E5F5),
      valueWidget: asyncValue.when(
        data: (v) => Text(
          priceFormatter.format(v),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF7B1FA2)),
        ),
        loading: () => const SizedBox(
          height: 22,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
        ),
        error: (_, _) => Text(l10n.error, style: const TextStyle(fontSize: 16, color: AppTheme.error)),
      ),
    );
  }
}

// ── 섹션 제목 ──────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
    );
  }
}

// ── 결제 방법별 매출 섹션 ──────────────────────────
class _PaymentBreakdownSection extends ConsumerWidget {
  const _PaymentBreakdownSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncValue = ref.watch(paymentBreakdownProvider);
    final priceFormatter = ref.watch(priceFormatterProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: asyncValue.when(
        data: (stats) {
          if (stats.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(l10n.noData,
                    style: const TextStyle(color: AppTheme.textDisabled)),
              ),
            );
          }

          final total = stats.fold(0.0, (sum, s) => sum + s.total);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(stats.length, (i) {
                final stat = stats[i];
                final ratio = total > 0 ? stat.total / total : 0.0;
                return Column(
                  children: [
                    if (i > 0) const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _paymentColor(stat.method),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _paymentLabel(stat.method, l10n),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '${(ratio * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              priceFormatter.format(stat.total),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 프로그레스 바
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: AppTheme.background,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_paymentColor(stat.method)),
                        minHeight: 8,
                      ),
                    ),
                  ],
                );
              }),
            ),
          );
        },
        loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppTheme.primary))),
        error: (_, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.errorOccurred(''), style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}

// ── 상품별 매출 순위 섹션 ──────────────────────────
class _TopSellingSection extends ConsumerWidget {
  const _TopSellingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncValue = ref.watch(topSellingProvider);
    final priceFormatter = ref.watch(priceFormatterProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: asyncValue.when(
        data: (items) {
          if (items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(l10n.noSalesData,
                    style: const TextStyle(color: AppTheme.textDisabled)),
              ),
            );
          }

          final maxSales = items.fold(0.0, (max, i) => i.totalSales > max ? i.totalSales : max);

          return Column(
            children: List.generate(items.length, (idx) {
              final item = items[idx];
              final ratio = maxSales > 0 ? item.totalSales / maxSales : 0.0;

              return Column(
                children: [
                  if (idx > 0) Divider(color: AppTheme.divider, height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // 순위 배지
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: idx < 3
                                ? [
                                  const Color(0xFFFDD835), // 1위 금
                                  const Color(0xFFB0BEC5), // 2위 은
                                  const Color(0xFFD7CCC8), // 3위 동
                                ][idx]
                                : AppTheme.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: idx < 3
                                    ? Colors.black87
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 상품명 + 프로그레스
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary),
                                  ),
                                  Text(
                                    priceFormatter.format(item.totalSales),
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              // 상대적 바
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  backgroundColor: AppTheme.background,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppTheme.primary),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                l10n.soldCount(item.totalQuantity),
                                style: const TextStyle(
                                    fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          );
        },
        loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppTheme.primary))),
        error: (_, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.errorOccurred(''), style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}

// ── 유틸리티 ──────────────────────────────────────

String _fmt(double price) {
  return price.toInt().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

Color _paymentColor(String method) => switch (method) {
      'cash' => const Color(0xFF03B26C),     // 초록
      'card' => const Color(0xFF3182F6),     // 파란색
      'qr' => const Color(0xFFFFA726),       // 주황
      'transfer' => const Color(0xFF7B1FA2), // 보라
      _ => const Color(0xFF6B7280),
    };

String _paymentLabel(String method, AppLocalizations l10n) => switch (method) {
      'cash' => l10n.cash,
      'card' => l10n.card,
      'qr' => l10n.qr,
      'transfer' => l10n.transfer,
      _ => method,
    };

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';

/// 매출 대시보드 화면
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(dashboardFilterProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          '매출 대시보드',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 날짜 필터 ──────────────────────────
            Row(
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
                        f.label,
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
            const SizedBox(height: 16),

            // ── 주요 통계 카드 행 (매출, 주문수, 평균주문) ──
            Row(
              children: [
                Expanded(child: totalSalesCard(ref)),
                const SizedBox(width: 10),
                Expanded(child: orderCountCard(ref)),
                const SizedBox(width: 10),
                Expanded(child: avgOrderCard(ref)),
              ],
            ),
            const SizedBox(height: 14),

            // ── 재고 가치 카드 ──────────────────────
            _InventoryValueCard(),
            const SizedBox(height: 20),

            // ── 결제 방법별 매출 ────────────────────
            _SectionTitle(title: '결제 방법별 매출'),
            const SizedBox(height: 10),
            _PaymentBreakdownSection(),
            const SizedBox(height: 20),

            // ── 상품별 매출 순위 ────────────────────
            _SectionTitle(title: '상품별 매출 순위'),
            const SizedBox(height: 10),
            _TopSellingSection(),
          ],
        ),
      ),
    );
  }
}

// ── 통계 카드 공통 레이아웃 ────────────────────────
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

Widget _asyncDoubleWidget(AsyncValue<double> async, Color color, String Function(double) fmt) {
  return async.when(
    data: (v) => Text(fmt(v), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
    loading: () => const SizedBox(height: 22, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))),
    error: (_, _) => const Text('오류', style: TextStyle(fontSize: 16, color: AppTheme.error)),
  );
}

// ── 매출 합계 카드 ─────────────────────────────────
Widget totalSalesCard(WidgetRef ref) {
  final async = ref.watch(totalSalesProvider);
  return _statCardLayout(
    title: '매출 합계',
    icon: Icons.attach_money,
    color: AppTheme.primary,
    bgColor: const Color(0xFFE8F0FE),
    valueWidget: _asyncDoubleWidget(async, AppTheme.primary, (v) => '₩${_fmt(v)}'),
  );
}

// ── 주문 수 카드 ────────────────────────────────────
Widget orderCountCard(WidgetRef ref) {
  final async = ref.watch(orderCountProvider);
  return _statCardLayout(
    title: '주문 수',
    icon: Icons.receipt_long,
    color: AppTheme.success,
    bgColor: const Color(0xFFE6FAF2),
    valueWidget: async.when(
      data: (v) => Text('$v건', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.success)),
      loading: () => const SizedBox(height: 22, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))),
      error: (_, _) => const Text('오류', style: TextStyle(fontSize: 16, color: AppTheme.error)),
    ),
  );
}

// ── 평균 주문금액 카드 ──────────────────────────────
Widget avgOrderCard(WidgetRef ref) {
  final async = ref.watch(avgOrderProvider);
  return _statCardLayout(
    title: '평균 주문금액',
    icon: Icons.bar_chart,
    color: AppTheme.warning,
    bgColor: const Color(0xFFFFF3E0),
    valueWidget: _asyncDoubleWidget(async, AppTheme.warning, (v) => '₩${_fmt(v)}'),
  );
}

// ── 재고 가치 카드 ──────────────────────────────────
class _InventoryValueCard extends ConsumerWidget {
  const _InventoryValueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(inventoryValueProvider);

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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('재고 가치',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text('현재 보유 재고 총 가치',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
          asyncValue.when(
            data: (value) => Text(
              '₩${_fmt(value)}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF7B1FA2)),
            ),
            loading: () => const SizedBox(
                width: 60,
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))),
            error: (_, _) =>
                const Text('오류', style: TextStyle(color: AppTheme.error)),
          ),
        ],
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
    final asyncValue = ref.watch(paymentBreakdownProvider);

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
              child: const Center(
                child: Text('데이터 없음',
                    style: TextStyle(color: AppTheme.textDisabled)),
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
                              _paymentLabel(stat.method),
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
                              '₩${_fmt(stat.total)}',
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
        error: (_, _) => const Padding(
            padding: EdgeInsets.all(16),
            child: Text('오류 발생', style: TextStyle(color: AppTheme.error))),
      ),
    );
  }
}

// ── 상품별 매출 순위 섹션 ──────────────────────────
class _TopSellingSection extends ConsumerWidget {
  const _TopSellingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(topSellingProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: asyncValue.when(
        data: (items) {
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('판매 데이터 없음',
                    style: TextStyle(color: AppTheme.textDisabled)),
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
                                    '₩${_fmt(item.totalSales)}',
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
                                '${item.totalQuantity}개 판매',
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
        error: (_, _) => const Padding(
            padding: EdgeInsets.all(16),
            child: Text('오류 발생', style: TextStyle(color: AppTheme.error))),
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
      'cash' => const Color(0xFF03B26C), // 초록
      'card' => const Color(0xFF3182F6), // 파란색
      'qr' => const Color(0xFFFFA726),   // 주황
      _ => const Color(0xFF6B7280),
    };

String _paymentLabel(String method) => switch (method) {
      'cash' => '현금',
      'card' => '카드',
      'qr' => 'QR',
      _ => method,
    };

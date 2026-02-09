import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/daos/sales_dao.dart';
import '../../../providers/database_providers.dart';

// ── 기간 열거형 ──────────────────────────────────
enum ReportPeriod {
  today('오늘', 'Today', 'Hôm nay'),
  week('주간', 'Week', 'Tuần'),
  month('월간', 'Month', 'Tháng'),
  custom('직접 선택', 'Custom', 'Tùy chọn');

  final String labelKo;
  final String labelEn;
  final String labelVi;

  const ReportPeriod(this.labelKo, this.labelEn, this.labelVi);
}

/// 현재 리포트 기간
final reportPeriodProvider =
    StateProvider<ReportPeriod>((ref) => ReportPeriod.week);

/// 커스텀 날짜 범위 (custom 선택 시 사용)
final customDateRangeProvider =
    StateProvider<({DateTime from, DateTime to})>((ref) {
  final now = DateTime.now();
  return (
    from: DateTime(now.year, now.month, 1),
    to: now,
  );
});

/// 계산된 날짜 범위
final reportDateRangeProvider =
    Provider<({DateTime from, DateTime to})>((ref) {
  final period = ref.watch(reportPeriodProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final to = today.add(const Duration(days: 1));

  return switch (period) {
    ReportPeriod.today => (from: today, to: to),
    ReportPeriod.week => (from: today.subtract(const Duration(days: 6)), to: to),
    ReportPeriod.month => (from: DateTime(now.year, now.month, 1), to: to),
    ReportPeriod.custom => ref.watch(customDateRangeProvider),
  };
});

/// 이전 동기간 날짜 범위 (성장률 계산용)
final previousDateRangeProvider =
    Provider<({DateTime from, DateTime to})>((ref) {
  final range = ref.watch(reportDateRangeProvider);
  final duration = range.to.difference(range.from);
  return (
    from: range.from.subtract(duration),
    to: range.from,
  );
});

// ── 리포트 데이터 Providers ─────────────────────

/// 매출 합계
final reportTotalSalesProvider = FutureProvider<double>((ref) async {
  final dao = ref.watch(salesDaoProvider);
  final range = ref.watch(reportDateRangeProvider);
  return await dao.getTotalSales(range.from, range.to);
});

/// 주문 건수
final reportOrderCountProvider = FutureProvider<int>((ref) async {
  final dao = ref.watch(salesDaoProvider);
  final range = ref.watch(reportDateRangeProvider);
  return await dao.getOrderCount(range.from, range.to);
});

/// 평균 주문금액
final reportAvgOrderProvider = FutureProvider<double>((ref) async {
  final total = await ref.watch(reportTotalSalesProvider.future);
  final count = await ref.watch(reportOrderCountProvider.future);
  return count > 0 ? total / count : 0;
});

/// 성장률 (%)
final reportGrowthProvider = FutureProvider<double>((ref) async {
  final dao = ref.watch(salesDaoProvider);
  final current = ref.watch(reportDateRangeProvider);
  final previous = ref.watch(previousDateRangeProvider);

  final currentTotal = await dao.getTotalSales(current.from, current.to);
  final previousTotal = await dao.getTotalSales(previous.from, previous.to);

  if (previousTotal == 0) return currentTotal > 0 ? 100.0 : 0.0;
  return ((currentTotal - previousTotal) / previousTotal) * 100;
});

/// 일별 매출 데이터 (Line chart)
final dailySalesChartProvider =
    FutureProvider<List<DailySalesData>>((ref) async {
  final dao = ref.watch(salesDaoProvider);
  final range = ref.watch(reportDateRangeProvider);
  return await dao.getDailySalesData(range.from, range.to);
});

/// 결제 방법별 매출 (Pie chart)
final paymentPieChartProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final dao = ref.watch(salesDaoProvider);
  final range = ref.watch(reportDateRangeProvider);
  return await dao.getPaymentMethodTotals(range.from, range.to);
});

/// 상품별 매출 순위 (Bar chart)
final topProductsBarChartProvider =
    FutureProvider<List<ProductSalesStats>>((ref) async {
  final dao = ref.watch(salesDaoProvider);
  final range = ref.watch(reportDateRangeProvider);
  return await dao.getTopSellingProducts(
    limit: 10,
    from: range.from,
    to: range.to,
  );
});

/// 시간대별 매출 분포
final hourlySalesProvider =
    FutureProvider<Map<int, double>>((ref) async {
  final dao = ref.watch(salesDaoProvider);
  final range = ref.watch(reportDateRangeProvider);
  return await dao.getHourlySalesDistribution(range.from, range.to);
});

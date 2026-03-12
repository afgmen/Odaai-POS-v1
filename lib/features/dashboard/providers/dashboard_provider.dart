import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import '../../../database/daos/sales_dao.dart';
import '../../../providers/database_providers.dart';

// ── Date Filter Enum ──────────────────────────────
enum DashboardFilter {
  today,
  week,
  month;

  String get localizationKey {
    switch (this) {
      case DashboardFilter.today:
        return 'today';
      case DashboardFilter.week:
        return 'week';
      case DashboardFilter.month:
        return 'month';
    }
  }
}

/// 현재 대시보드 날짜 필터
final dashboardFilterProvider =
    StateProvider<DashboardFilter>((ref) => DashboardFilter.today);

// ── 날짜 범위 계산 헬퍼 ────────────────────────────
({DateTime from, DateTime to}) _dateRange(DashboardFilter filter) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final to = now.add(const Duration(days: 1));

  final from = switch (filter) {
    DashboardFilter.today => today,
    DashboardFilter.week => today.subtract(const Duration(days: 6)),
    DashboardFilter.month => DateTime(now.year, now.month, 1),
  };

  return (from: from, to: to);
}

// ── B-103: 기간별 매출 합계 — StreamProvider (결제 즉시 반영) ──
final totalSalesProvider = StreamProvider<double>((ref) {
  final dao = ref.watch(salesDaoProvider);
  final filter = ref.watch(dashboardFilterProvider);
  final range = _dateRange(filter);
  return dao.watchTotalSales(range.from, range.to);
});

// ── B-103: 기간별 주문 수 — StreamProvider ─────────
final orderCountProvider = StreamProvider<int>((ref) {
  final dao = ref.watch(salesDaoProvider);
  final filter = ref.watch(dashboardFilterProvider);
  final range = _dateRange(filter);
  return dao.watchOrderCount(range.from, range.to);
});

// ── 평균 주문금액 (파생 스트림) ────────────────────
final avgOrderProvider = StreamProvider<double>((ref) {
  // combine total + count streams
  final totalAsync = ref.watch(totalSalesProvider);
  final countAsync = ref.watch(orderCountProvider);

  final total = totalAsync.valueOrNull ?? 0;
  final count = countAsync.valueOrNull ?? 0;

  return Stream.value(count > 0 ? total / count : 0);
});

// ── B-103: 결제 방법별 매출 분석 — StreamProvider ──
final paymentBreakdownProvider =
    StreamProvider<List<PaymentStat>>((ref) {
  final dao = ref.watch(salesDaoProvider);
  final filter = ref.watch(dashboardFilterProvider);
  final range = _dateRange(filter);
  return dao.watchPaymentBreakdown(range.from, range.to).map(
        (list) => list
            .map((e) => PaymentStat(method: e.method, total: e.total))
            .toList(),
      );
});

// ── 상품별 매출 순위 (Top 5) — 집계 쿼리라 FutureProvider 유지 ──
// invalidate는 payment_modal에서 결제 완료 시 수행
final topSellingProvider =
    FutureProvider<List<ProductSalesStats>>((ref) async {
  final dao = ref.watch(salesDaoProvider);
  final filter = ref.watch(dashboardFilterProvider);
  final range = _dateRange(filter);
  return await dao.getTopSellingProducts(
    limit: 5,
    from: range.from,
    to: range.to,
  );
});

// ── 재고 가치 합계 (필터 무관) ─────────────────────
final inventoryValueProvider = FutureProvider<double>((ref) async {
  final dao = ref.watch(productsDaoProvider);
  return await dao.getTotalInventoryValue();
});

// ── 재고 부족 상품 목록 ────────────────────────────
final lowStockProvider = FutureProvider<List<Product>>((ref) async {
  final dao = ref.watch(productsDaoProvider);
  return await dao.getLowStockProducts();
});

// ── 재고 부족 상품 실시간 스트림 ─────────────────────
final lowStockStreamProvider = StreamProvider<List<Product>>((ref) {
  final dao = ref.watch(productsDaoProvider);
  return dao.watchLowStockProducts();
});

// ── 결제 방법 통계 모델 ────────────────────────────
class PaymentStat {
  final String method;
  final double total;

  PaymentStat({required this.method, required this.total});
}

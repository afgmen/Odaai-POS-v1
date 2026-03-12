import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';
import '../data/daily_closing_dao.dart';
import '../domain/services/closing_service.dart';

/// DailyClosingDao Provider
final dailyClosingDaoProvider = Provider<DailyClosingDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.dailyClosingDao;
});

/// B-103: 특정 날짜의 마감 데이터 — StreamProvider (마감 후 즉시 반영)
final closingByDateProvider = StreamProvider.family<DailyClosing?, DateTime>(
  (ref, date) {
    return ref.watch(dailyClosingDaoProvider).watchClosingByDate(date);
  },
);

/// 오늘 마감 가능 여부 (FutureProvider 유지 — 단순 bool 체크)
final canCloseTodayProvider = FutureProvider<bool>((ref) {
  return ref.watch(closingServiceProvider).canCloseToday();
});

/// 특정 날짜의 매출 집계 (FutureProvider 유지 — 복잡한 집계 쿼리)
/// 마감 완료 시 invalidate로 갱신
final salesAggregationProvider = FutureProvider.family<SalesAggregation?, DateTime>(
  (ref, date) {
    return ref.watch(dailyClosingDaoProvider).aggregateSalesForDate(date);
  },
);

/// B-103: 최근 마감 목록 (직원 정보 포함) — StreamProvider (마감 후 목록 즉시 반영)
final recentClosingsProvider = StreamProvider.family<List<ClosingWithEmployee>, int>(
  (ref, limit) {
    return ref.watch(dailyClosingDaoProvider).watchClosingsWithEmployee(limit: limit);
  },
);

/// 특정 기간 요약 (FutureProvider 유지 — 복잡한 집계)
final periodSummaryProvider = FutureProvider.family<PeriodSummary, DateRange>(
  (ref, range) {
    return ref.watch(dailyClosingDaoProvider).getPeriodSummary(
      startDate: range.startDate,
      endDate: range.endDate,
    );
  },
);

/// 시재 차이가 있는 마감 목록 (FutureProvider 유지)
final closingsWithCashDifferenceProvider = FutureProvider<List<DailyClosing>>((ref) {
  return ref.watch(dailyClosingDaoProvider).getClosingsWithCashDifference();
});

// ═══════════════════════════════════════════════════════
// 헬퍼 클래스
// ═══════════════════════════════════════════════════════

class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange({
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}

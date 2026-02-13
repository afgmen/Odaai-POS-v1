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

/// 특정 날짜의 마감 데이터
final closingByDateProvider = FutureProvider.family<DailyClosing?, DateTime>(
  (ref, date) {
    return ref.watch(dailyClosingDaoProvider).getClosingByDate(date);
  },
);

/// 오늘 마감 가능 여부
final canCloseTodayProvider = FutureProvider<bool>((ref) {
  return ref.watch(closingServiceProvider).canCloseToday();
});

/// 특정 날짜의 매출 집계
final salesAggregationProvider = FutureProvider.family<SalesAggregation?, DateTime>(
  (ref, date) {
    return ref.watch(dailyClosingDaoProvider).aggregateSalesForDate(date);
  },
);

/// 최근 마감 목록
final recentClosingsProvider = FutureProvider.family<List<ClosingWithEmployee>, int>(
  (ref, limit) {
    return ref.watch(dailyClosingDaoProvider).getClosingsWithEmployee(limit: limit);
  },
);

/// 특정 기간 요약
final periodSummaryProvider = FutureProvider.family<PeriodSummary, DateRange>(
  (ref, range) {
    return ref.watch(dailyClosingDaoProvider).getPeriodSummary(
      startDate: range.startDate,
      endDate: range.endDate,
    );
  },
);

/// 시재 차이가 있는 마감 목록
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

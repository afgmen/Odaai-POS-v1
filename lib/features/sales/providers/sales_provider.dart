import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';

// ── Date Filter Enum ──────────────────────────────
enum DateFilter {
  today,
  week,
  month,
  all;

  String get localizationKey {
    switch (this) {
      case DateFilter.today:
        return 'today';
      case DateFilter.week:
        return 'week';
      case DateFilter.month:
        return 'month';
      case DateFilter.all:
        return 'all';
    }
  }
}

/// 현재 날짜 필터 상태
final selectedDateFilterProvider = StateProvider<DateFilter>((ref) => DateFilter.today);

// ── 날짜 범위 계산 헬퍼 ────────────────────────────
({DateTime from, DateTime to}) _salesDateRange(DateFilter filter) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final to = now.add(const Duration(days: 1));

  final from = switch (filter) {
    DateFilter.today => today,
    DateFilter.week => today.subtract(const Duration(days: 6)),
    DateFilter.month => DateTime(now.year, now.month, 1),
    DateFilter.all => DateTime(2000, 1, 1),
  };

  return (from: from, to: to);
}

/// B-103: 날짜 필터에 맞는 주문 목록 — FutureProvider → StreamProvider
/// 결제/환불 즉시 UI에 반영됨
final salesListProvider = StreamProvider<List<Sale>>((ref) {
  final dao = ref.watch(salesDaoProvider);
  final filter = ref.watch(selectedDateFilterProvider);
  final range = _salesDateRange(filter);
  return dao.watchSalesByDateRange(range.from, range.to);
});

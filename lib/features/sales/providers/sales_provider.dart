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

/// 날짜 필터에 맞는 주문 목록
final salesListProvider = FutureProvider<List<Sale>>((ref) async {
  final dao = ref.watch(salesDaoProvider);
  final filter = ref.watch(selectedDateFilterProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final DateTime from;
  final DateTime to = now.add(const Duration(days: 1)); // 오늘 끝

  switch (filter) {
    case DateFilter.today:
      from = today;
    case DateFilter.week:
      from = today.subtract(const Duration(days: 6));
    case DateFilter.month:
      from = DateTime(now.year, now.month, 1);
    case DateFilter.all:
      from = DateTime(2000, 1, 1); // 실질적 전체
  }

  return await dao.getSalesByDateRange(from, to);
});

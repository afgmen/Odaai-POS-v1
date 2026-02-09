import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../data/tables_dao.dart';
import '../../../providers/database_providers.dart';

/// 테이블 DAO Provider
final tablesDaoProvider = Provider<TablesDao>((ref) {
  return ref.watch(databaseProvider).tablesDao;
});

/// 전체 테이블 목록 (실시간)
final allTablesProvider = StreamProvider<List<RestaurantTable>>((ref) {
  return ref.watch(tablesDaoProvider).watchAllActiveTables();
});

/// 테이블 상태 필터
final tableStatusFilterProvider = StateProvider<String?>((ref) => null); // null = 전체

/// 필터링된 테이블 목록
final filteredTablesProvider = Provider<AsyncValue<List<RestaurantTable>>>((ref) {
  final tablesAsync = ref.watch(allTablesProvider);
  final filter = ref.watch(tableStatusFilterProvider);

  return tablesAsync.whenData((tables) {
    if (filter == null) return tables;
    return tables.where((t) => t.status == filter).toList();
  });
});

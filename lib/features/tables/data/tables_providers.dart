import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';
import 'tables_dao.dart';

// ============================================================
// DAO Provider
// ============================================================

/// Tables DAO Provider
final tablesDaoProvider = Provider<TablesDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.tablesDao;
});

// ============================================================
// Stream Providers (실시간 데이터)
// ============================================================

/// 모든 활성 테이블 스트림
final allTablesStreamProvider = StreamProvider<List<RestaurantTable>>((ref) {
  final dao = ref.watch(tablesDaoProvider);
  final stream = dao.watchAllActiveTables();
  
  // Stream 모니터링 로그
  return stream.map((tables) {
    debugPrint('[TableSync] allTablesStreamProvider emitted: ${tables.length} tables at ${DateTime.now()}');
    return tables;
  });
});

/// 상태별 테이블 스트림
final tablesByStatusStreamProvider =
    StreamProvider.family<List<RestaurantTable>, String>(
  (ref, status) {
    final dao = ref.watch(tablesDaoProvider);
    return dao.watchTablesByStatus(status);
  },
);

/// 단일 테이블 스트림
final tableStreamProvider = StreamProvider.family<RestaurantTable?, int>(
  (ref, tableId) {
    final dao = ref.watch(tablesDaoProvider);
    return dao.watchTable(tableId);
  },
);

// ============================================================
// State Providers
// ============================================================

/// 선택된 테이블 필터 (null = 전체)
final selectedTableStatusProvider = StateProvider<String?>((ref) => null);

/// 필터링된 테이블 목록 (클라이언트 사이드 필터링)
final filteredTablesProvider = StreamProvider<List<RestaurantTable>>((ref) {
  final allTablesAsync = ref.watch(allTablesStreamProvider);
  final selectedStatus = ref.watch(selectedTableStatusProvider);

  return allTablesAsync.when(
    data: (allTables) {
      if (selectedStatus == null) {
        return Stream.value(allTables);
      }
      final filtered =
          allTables.where((t) => t.status == selectedStatus).toList();
      return Stream.value(filtered);
    },
    loading: () => Stream.value(<RestaurantTable>[]),
    error: (err, stack) => Stream.value(<RestaurantTable>[]),
  ).asyncExpand((tables) => Stream.value(tables));
});

/// 선택된 테이블 ID
final selectedTableIdProvider = StateProvider<int?>((ref) => null);

/// 테이블 상세 모달 표시 상태
final showTableDetailProvider = StateProvider<bool>((ref) => false);

/// 테이블 추가 모달 표시 상태
final showAddTableModalProvider = StateProvider<bool>((ref) => false);

// ============================================================
// Statistics Providers
// ============================================================

/// 상태별 테이블 개수 (실시간 - allTablesStreamProvider에서 파생)
final tableCountByStatusProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(allTablesStreamProvider.stream).map((tables) {
    final counts = <String, int>{};
    for (final table in tables) {
      counts[table.status] = (counts[table.status] ?? 0) + 1;
    }
    return counts;
  });
});

/// 평균 테이블 회전율 (오늘)
final avgTableTurnoverProvider = FutureProvider<double>((ref) {
  final dao = ref.watch(tablesDaoProvider);
  return dao.getAverageTableTurnoverToday();
});

/// 평균 테이블 점유 시간 (분)
final avgOccupancyTimeProvider = FutureProvider<double>((ref) {
  final dao = ref.watch(tablesDaoProvider);
  return dao.getAverageOccupancyTime();
});

/// 빈 테이블 개수 (Fix #4: FutureProvider → StreamProvider 실시간 갱신)
final availableTableCountProvider = StreamProvider<int>((ref) {
  return ref.watch(allTablesStreamProvider.stream).map(
    (tables) => tables.where((t) => t.status == 'AVAILABLE').length,
  );
});

/// 점유 중인 테이블 개수 (Fix #4: FutureProvider → StreamProvider 실시간 갱신)
final occupiedTableCountProvider = StreamProvider<int>((ref) {
  return ref.watch(allTablesStreamProvider.stream).map(
    (tables) => tables
        .where((t) => t.status != 'AVAILABLE' && t.status != 'CLEANING')
        .length,
  );
});

// ============================================================
// Phase 3: Open Tab Providers
// ============================================================

/// 특정 테이블의 Open Tab (활성 Sale) 스트림
final watchOpenTabByTableProvider =
    StreamProvider.family<Sale?, int>((ref, tableId) {
  final db = ref.watch(databaseProvider);
  return db.salesDao.watchOpenTabByTableId(tableId);
});

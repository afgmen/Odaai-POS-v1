import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  return dao.watchAllActiveTables();
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

/// 상태별 테이블 개수
final tableCountByStatusProvider = FutureProvider<Map<String, int>>((ref) {
  final dao = ref.watch(tablesDaoProvider);
  return dao.getTableCountByStatus();
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

/// 빈 테이블 개수
final availableTableCountProvider = FutureProvider<int>((ref) {
  final dao = ref.watch(tablesDaoProvider);
  return dao.getAvailableTableCount();
});

/// 점유 중인 테이블 개수
final occupiedTableCountProvider = FutureProvider<int>((ref) {
  final dao = ref.watch(tablesDaoProvider);
  return dao.getOccupiedTableCount();
});

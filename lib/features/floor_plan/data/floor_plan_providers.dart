import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';
import 'floor_zone_dao.dart';
import 'floor_element_dao.dart';

// ============================================================
// DAO Providers
// ============================================================

/// Floor Zone DAO Provider
final floorZoneDaoProvider = Provider<FloorZoneDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.floorZoneDao;
});

/// Floor Element DAO Provider
final floorElementDaoProvider = Provider<FloorElementDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.floorElementDao;
});

// ============================================================
// Stream Providers (실시간 데이터)
// ============================================================

/// 모든 구역 스트림
final allZonesStreamProvider = StreamProvider<List<FloorZone>>((ref) {
  final dao = ref.watch(floorZoneDaoProvider);
  return dao.watchAllZones();
});

/// 모든 요소 스트림
final allElementsStreamProvider = StreamProvider<List<FloorElement>>((ref) {
  final dao = ref.watch(floorElementDaoProvider);
  return dao.watchAllElements();
});

// ============================================================
// Floor Plan Config Provider
// ============================================================

/// 플로어 플랜 설정 로드
final floorPlanConfigProvider =
    FutureProvider<FloorPlanConfigData?>((ref) async {
  final db = ref.watch(databaseProvider);
  final result = await db.select(db.floorPlanConfig).get();
  return result.isEmpty ? null : result.first;
});

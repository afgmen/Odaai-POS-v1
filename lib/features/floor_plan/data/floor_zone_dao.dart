import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/floor_zones.dart';

part 'floor_zone_dao.g.dart';

/// Floor Zone DAO
/// 매장 구역 관리를 위한 데이터베이스 접근 계층
@DriftAccessor(tables: [FloorZones])
class FloorZoneDao extends DatabaseAccessor<AppDatabase>
    with _$FloorZoneDaoMixin {
  FloorZoneDao(super.db);

  // ============================================================
  // CREATE
  // ============================================================

  /// 새 구역 생성
  Future<int> createZone(FloorZonesCompanion zone) {
    return into(floorZones).insert(zone);
  }

  // ============================================================
  // READ
  // ============================================================

  /// 모든 구역 조회
  Future<List<FloorZone>> getAllZones() {
    return (select(floorZones)
          ..orderBy([(z) => OrderingTerm(expression: z.name)]))
        .get();
  }

  /// ID로 구역 조회
  Future<FloorZone?> getZoneById(int id) {
    return (select(floorZones)..where((z) => z.id.equals(id)))
        .getSingleOrNull();
  }

  // ============================================================
  // STREAM
  // ============================================================

  /// 모든 구역 실시간 스트림
  Stream<List<FloorZone>> watchAllZones() {
    return (select(floorZones)
          ..orderBy([(z) => OrderingTerm(expression: z.name)]))
        .watch();
  }

  // ============================================================
  // UPDATE
  // ============================================================

  /// 구역 정보 업데이트
  Future<bool> updateZone(FloorZonesCompanion zone) {
    return update(floorZones).replace(zone);
  }

  /// 구역 위치/크기 업데이트
  Future<bool> updateZonePositionAndSize({
    required int zoneId,
    required double posX,
    required double posY,
    required double width,
    required double height,
  }) {
    return (update(floorZones)..where((z) => z.id.equals(zoneId)))
        .write(
      FloorZonesCompanion(
        posX: Value(posX),
        posY: Value(posY),
        width: Value(width),
        height: Value(height),
      ),
    )
        .then((count) => count > 0);
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// 구역 삭제
  Future<int> deleteZone(int id) {
    return (delete(floorZones)..where((z) => z.id.equals(id))).go();
  }
}

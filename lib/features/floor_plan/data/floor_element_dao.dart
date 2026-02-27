import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/floor_elements.dart';

part 'floor_element_dao.g.dart';

/// Floor Element DAO
/// 매장 고정 요소 관리를 위한 데이터베이스 접근 계층
@DriftAccessor(tables: [FloorElements])
class FloorElementDao extends DatabaseAccessor<AppDatabase>
    with _$FloorElementDaoMixin {
  FloorElementDao(super.db);

  // ============================================================
  // CREATE
  // ============================================================

  /// 새 요소 생성
  Future<int> createElement(FloorElementsCompanion element) {
    return into(floorElements).insert(element);
  }

  // ============================================================
  // READ
  // ============================================================

  /// 모든 요소 조회
  Future<List<FloorElement>> getAllElements() {
    return select(floorElements).get();
  }

  /// ID로 요소 조회
  Future<FloorElement?> getElementById(int id) {
    return (select(floorElements)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
  }

  // ============================================================
  // STREAM
  // ============================================================

  /// 모든 요소 실시간 스트림
  Stream<List<FloorElement>> watchAllElements() {
    return select(floorElements).watch();
  }

  // ============================================================
  // UPDATE
  // ============================================================

  /// 요소 정보 업데이트
  Future<bool> updateElement(FloorElementsCompanion element) {
    return update(floorElements).replace(element);
  }

  /// 요소 위치 업데이트
  Future<bool> updateElementPosition({
    required int elementId,
    required double posX,
    required double posY,
  }) {
    return (update(floorElements)..where((e) => e.id.equals(elementId)))
        .write(
      FloorElementsCompanion(
        posX: Value(posX),
        posY: Value(posY),
      ),
    )
        .then((count) => count > 0);
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// 요소 삭제
  Future<int> deleteElement(int id) {
    return (delete(floorElements)..where((e) => e.id.equals(id))).go();
  }
}

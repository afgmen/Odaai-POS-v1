import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/store_tables_management.dart';
import '../../../database/tables/reservations.dart';

part 'tables_dao.g.dart';

/// Tables DAO
/// 식당 테이블 관리를 위한 데이터베이스 접근 계층
@DriftAccessor(tables: [RestaurantTables, Reservations])
class TablesDao extends DatabaseAccessor<AppDatabase> with _$TablesDaoMixin {
  TablesDao(super.db);

  // ============================================================
  // CREATE
  // ============================================================

  /// 새 테이블 생성
  Future<int> createTable(RestaurantTablesCompanion table) {
    return into(restaurantTables).insert(table);
  }

  // ============================================================
  // READ - Single
  // ============================================================

  /// ID로 테이블 조회
  Future<RestaurantTable?> getTableById(int id) {
    return (select(restaurantTables)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 테이블 번호로 조회
  Future<RestaurantTable?> getTableByNumber(String tableNumber) {
    return (select(restaurantTables)
          ..where((t) => t.tableNumber.equals(tableNumber)))
        .getSingleOrNull();
  }

  // ============================================================
  // READ - List
  // ============================================================

  /// 모든 활성 테이블 조회
  Future<List<RestaurantTable>> getAllActiveTables() {
    return (select(restaurantTables)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.tableNumber, mode: OrderingMode.asc)
          ]))
        .get();
  }

  /// 상태별 테이블 조회
  Future<List<RestaurantTable>> getTablesByStatus(String status) {
    return (select(restaurantTables)
          ..where((t) => t.status.equals(status) & t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.tableNumber, mode: OrderingMode.asc)
          ]))
        .get();
  }

  // ============================================================
  // STREAM - Real-time Updates
  // ============================================================

  /// 모든 활성 테이블 실시간 스트림
  Stream<List<RestaurantTable>> watchAllActiveTables() {
    return (select(restaurantTables)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.tableNumber, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  /// 상태별 테이블 실시간 스트림
  Stream<List<RestaurantTable>> watchTablesByStatus(String status) {
    return (select(restaurantTables)
          ..where((t) => t.status.equals(status) & t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.tableNumber, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  /// 테이블 상세 정보 스트림 (단일 테이블)
  Stream<RestaurantTable?> watchTable(int tableId) {
    return (select(restaurantTables)..where((t) => t.id.equals(tableId)))
        .watchSingleOrNull();
  }

  // ============================================================
  // UPDATE
  // ============================================================

  /// 테이블 상태 업데이트
  Future<bool> updateTableStatus({
    required int tableId,
    required String status,
    int? currentSaleId,
    DateTime? occupiedAt,
    int? reservationId,
  }) {
    return (update(restaurantTables)..where((t) => t.id.equals(tableId)))
        .write(
      RestaurantTablesCompanion(
        status: Value(status),
        currentSaleId: Value(currentSaleId),
        occupiedAt: Value(occupiedAt),
        reservationId: Value(reservationId),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((count) => count > 0);
  }

  /// 테이블 위치 업데이트 (드래그앤드롭)
  Future<bool> updateTablePosition({
    required int tableId,
    required double x,
    required double y,
  }) {
    return (update(restaurantTables)..where((t) => t.id.equals(tableId)))
        .write(
      RestaurantTablesCompanion(
        positionX: Value(x),
        positionY: Value(y),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((count) => count > 0);
  }

  /// 테이블 정보 수정 (번호, 좌석 수)
  Future<bool> updateTableInfo({
    required int tableId,
    String? tableNumber,
    int? seats,
  }) {
    return (update(restaurantTables)..where((t) => t.id.equals(tableId)))
        .write(
      RestaurantTablesCompanion(
        tableNumber:
            tableNumber != null ? Value(tableNumber) : const Value.absent(),
        seats: seats != null ? Value(seats) : const Value.absent(),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((count) => count > 0);
  }

  /// 테이블 전체 업데이트
  Future<bool> updateTable(RestaurantTablesCompanion table) async {
    return await update(restaurantTables).replace(table);
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// 테이블 소프트 삭제 (isActive = false)
  Future<bool> softDeleteTable(int tableId) {
    return (update(restaurantTables)..where((t) => t.id.equals(tableId)))
        .write(
      RestaurantTablesCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((count) => count > 0);
  }

  /// 테이블 영구 삭제 (테스트용)
  Future<int> hardDeleteTable(int tableId) {
    return (delete(restaurantTables)..where((t) => t.id.equals(tableId))).go();
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// 상태별 테이블 개수
  Future<Map<String, int>> getTableCountByStatus() async {
    final allTables = await getAllActiveTables();
    final counts = <String, int>{};
    for (final table in allTables) {
      counts[table.status] = (counts[table.status] ?? 0) + 1;
    }
    return counts;
  }

  /// 평균 테이블 회전율 (오늘)
  /// 오늘 완료된 판매 건수 / 활성 테이블 수
  Future<double> getAverageTableTurnoverToday() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Sales 테이블과 JOIN하여 오늘 테이블 사용 판매 건수 조회
    final query = selectOnly(db.sales)
      ..addColumns([db.sales.id.count()])
      ..where(
        db.sales.saleDate.isBetweenValues(startOfDay, endOfDay),
      );

    final result = await query.getSingle();
    final totalSales = result.read(db.sales.id.count()) ?? 0;

    final activeTables = await getAllActiveTables();
    if (activeTables.isEmpty) return 0;

    return totalSales / activeTables.length;
  }

  /// 평균 테이블 점유 시간 (분)
  Future<double> getAverageOccupancyTime() async {
    final occupiedTables = await getTablesByStatus('OCCUPIED');
    if (occupiedTables.isEmpty) return 0;

    var totalMinutes = 0.0;
    final now = DateTime.now();

    for (final table in occupiedTables) {
      if (table.occupiedAt != null) {
        final duration = now.difference(table.occupiedAt!);
        totalMinutes += duration.inMinutes;
      }
    }

    return totalMinutes / occupiedTables.length;
  }

  /// 빈 테이블 개수
  Future<int> getAvailableTableCount() async {
    final availableTables = await getTablesByStatus('AVAILABLE');
    return availableTables.length;
  }

  /// 점유 중인 테이블 개수
  Future<int> getOccupiedTableCount() async {
    final occupiedTables = await getTablesByStatus('OCCUPIED');
    return occupiedTables.length;
  }

  // ============================================================
  // BATCH OPERATIONS
  // ============================================================

  /// 여러 테이블 위치 일괄 업데이트
  Future<void> updateMultipleTablePositions(
      List<MapEntry<int, Offset>> positions) async {
    await batch((b) {
      for (final entry in positions) {
        b.update(
          restaurantTables,
          RestaurantTablesCompanion(
            positionX: Value(entry.value.dx),
            positionY: Value(entry.value.dy),
            updatedAt: Value(DateTime.now()),
          ),
          where: (t) => t.id.equals(entry.key),
        );
      }
    });
  }
}

/// Offset helper class for position updates
class Offset {
  final double dx;
  final double dy;

  const Offset(this.dx, this.dy);
}

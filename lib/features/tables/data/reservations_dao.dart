import 'package:drift/drift.dart';
import '../../../database/app_database.dart';

part 'reservations_dao.g.dart';

/// Reservations DAO
/// 예약 관리를 위한 데이터베이스 접근 계층
@DriftAccessor(tables: [Reservations, RestaurantTables])
class ReservationsDao extends DatabaseAccessor<AppDatabase>
    with _$ReservationsDaoMixin {
  ReservationsDao(super.db);

  // ============================================================
  // CREATE
  // ============================================================

  /// 새 예약 생성
  Future<int> createReservation(ReservationsCompanion reservation) {
    return into(reservations).insert(reservation);
  }

  // ============================================================
  // READ - Single
  // ============================================================

  /// ID로 예약 조회
  Future<Reservation?> getReservationById(int id) {
    return (select(reservations)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  // ============================================================
  // READ - List
  // ============================================================

  /// 날짜별 예약 목록 조회
  Future<List<Reservation>> getReservationsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(reservations)
          ..where((r) =>
              r.reservationDate.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([
            (r) =>
                OrderingTerm(expression: r.reservationTime, mode: OrderingMode.asc)
          ]))
        .get();
  }

  /// 상태별 예약 목록 조회
  Future<List<Reservation>> getReservationsByStatus(String status) {
    return (select(reservations)
          ..where((r) => r.status.equals(status))
          ..orderBy([
            (r) => OrderingTerm(
                expression: r.reservationDate, mode: OrderingMode.asc),
            (r) => OrderingTerm(
                expression: r.reservationTime, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// 오늘 예약 목록 조회
  Future<List<Reservation>> getTodayReservations() {
    return getReservationsByDate(DateTime.now());
  }

  /// 이번 주 예약 목록 조회
  Future<List<Reservation>> getWeekReservations() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return (select(reservations)
          ..where((r) =>
              r.reservationDate.isBetweenValues(startOfWeek, endOfWeek))
          ..orderBy([
            (r) => OrderingTerm(
                expression: r.reservationDate, mode: OrderingMode.asc),
            (r) => OrderingTerm(
                expression: r.reservationTime, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// 날짜 범위별 예약 조회
  Future<List<Reservation>> getReservationsByDateRange(
      DateTime startDate, DateTime endDate) {
    return (select(reservations)
          ..where((r) =>
              r.reservationDate.isBetweenValues(startDate, endDate))
          ..orderBy([
            (r) => OrderingTerm(
                expression: r.reservationDate, mode: OrderingMode.asc),
            (r) => OrderingTerm(
                expression: r.reservationTime, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// 전화번호로 예약 검색
  Future<List<Reservation>> getReservationsByPhone(String phone) {
    return (select(reservations)
          ..where((r) => r.customerPhone.equals(phone))
          ..orderBy([
            (r) => OrderingTerm(
                expression: r.reservationDate, mode: OrderingMode.desc),
          ]))
        .get();
  }

  // ============================================================
  // STREAM - Real-time Updates
  // ============================================================

  /// 날짜별 예약 실시간 스트림
  Stream<List<Reservation>> watchReservationsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(reservations)
          ..where((r) =>
              r.reservationDate.isBetweenValues(startOfDay, endOfDay))
          ..orderBy([
            (r) => OrderingTerm(
                expression: r.reservationTime, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  /// 오늘 예약 실시간 스트림
  Stream<List<Reservation>> watchTodayReservations() {
    return watchReservationsByDate(DateTime.now());
  }

  /// 상태별 예약 실시간 스트림
  Stream<List<Reservation>> watchReservationsByStatus(String status) {
    return (select(reservations)
          ..where((r) => r.status.equals(status))
          ..orderBy([
            (r) => OrderingTerm(
                expression: r.reservationDate, mode: OrderingMode.asc),
            (r) => OrderingTerm(
                expression: r.reservationTime, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// 단일 예약 실시간 스트림
  Stream<Reservation?> watchReservation(int reservationId) {
    return (select(reservations)..where((r) => r.id.equals(reservationId)))
        .watchSingleOrNull();
  }

  // ============================================================
  // UPDATE
  // ============================================================

  /// 예약 상태 업데이트
  Future<bool> updateReservationStatus({
    required int reservationId,
    required String status,
  }) {
    return (update(reservations)..where((r) => r.id.equals(reservationId)))
        .write(
      ReservationsCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((count) => count > 0);
  }

  /// 예약 테이블 배정
  Future<bool> assignTableToReservation({
    required int reservationId,
    required int tableId,
  }) {
    return (update(reservations)..where((r) => r.id.equals(reservationId)))
        .write(
      ReservationsCompanion(
        tableId: Value(tableId),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((count) => count > 0);
  }

  /// 예약 수정
  Future<bool> updateReservation({
    required int reservationId,
    String? customerName,
    String? customerPhone,
    int? partySize,
    DateTime? reservationDate,
    String? reservationTime,
    String? specialRequests,
  }) {
    return (update(reservations)..where((r) => r.id.equals(reservationId)))
        .write(
      ReservationsCompanion(
        customerName: customerName != null
            ? Value(customerName)
            : const Value.absent(),
        customerPhone: customerPhone != null
            ? Value(customerPhone)
            : const Value.absent(),
        partySize:
            partySize != null ? Value(partySize) : const Value.absent(),
        reservationDate: reservationDate != null
            ? Value(reservationDate)
            : const Value.absent(),
        reservationTime: reservationTime != null
            ? Value(reservationTime)
            : const Value.absent(),
        specialRequests: Value(specialRequests),
        updatedAt: Value(DateTime.now()),
      ),
    ).then((count) => count > 0);
  }

  /// 예약 전체 업데이트
  Future<bool> updateReservationFull(ReservationsCompanion reservation) {
    return update(reservations)
        .replace(reservation)
        .then((count) => count > 0);
  }

  // ============================================================
  // DELETE
  // ============================================================

  /// 예약 삭제
  Future<int> deleteReservation(int reservationId) {
    return (delete(reservations)..where((r) => r.id.equals(reservationId)))
        .go();
  }

  /// 오래된 예약 일괄 삭제 (90일 이상)
  Future<int> deleteOldReservations({int daysOld = 90}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    return (delete(reservations)
          ..where((r) => r.reservationDate.isSmallerThanValue(cutoffDate)))
        .go();
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  /// 상태별 예약 개수
  Future<Map<String, int>> getReservationCountByStatus() async {
    final allReservations = await select(reservations).get();
    final counts = <String, int>{};
    for (final reservation in allReservations) {
      counts[reservation.status] = (counts[reservation.status] ?? 0) + 1;
    }
    return counts;
  }

  /// 오늘 노쇼 개수
  Future<int> getTodayNoShowCount() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = selectOnly(reservations)
      ..addColumns([reservations.id.count()])
      ..where(
        reservations.reservationDate.isBetweenValues(startOfDay, endOfDay) &
            reservations.status.equals('NO_SHOW'),
      );

    final result = await query.getSingle();
    return result.read(reservations.id.count()) ?? 0;
  }

  /// 오늘 확정된 예약 개수
  Future<int> getTodayConfirmedCount() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = selectOnly(reservations)
      ..addColumns([reservations.id.count()])
      ..where(
        reservations.reservationDate.isBetweenValues(startOfDay, endOfDay) &
            reservations.status.equals('CONFIRMED'),
      );

    final result = await query.getSingle();
    return result.read(reservations.id.count()) ?? 0;
  }

  /// 날짜별 예약 개수
  Future<int> getReservationCountByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = selectOnly(reservations)
      ..addColumns([reservations.id.count()])
      ..where(
          reservations.reservationDate.isBetweenValues(startOfDay, endOfDay));

    final result = await query.getSingle();
    return result.read(reservations.id.count()) ?? 0;
  }

  /// 예약 취소율 (%)
  Future<double> getCancellationRate() async {
    final allReservations = await select(reservations).get();
    if (allReservations.isEmpty) return 0;

    final cancelledCount = allReservations
        .where((r) => r.status == 'CANCELLED' || r.status == 'NO_SHOW')
        .length;

    return (cancelledCount / allReservations.length) * 100;
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  /// 시간대 예약 가능 여부 확인
  /// 같은 날짜, 같은 시간에 이미 예약이 있는지 확인
  Future<bool> isTimeSlotAvailable({
    required DateTime date,
    required String time,
    int? excludeReservationId,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    var query = select(reservations)
      ..where((r) =>
          r.reservationDate.isBetweenValues(startOfDay, endOfDay) &
          r.reservationTime.equals(time) &
          (r.status.equals('PENDING') |
              r.status.equals('CONFIRMED') |
              r.status.equals('SEATED')));

    if (excludeReservationId != null) {
      query = query..where((r) => r.id.equals(excludeReservationId).not());
    }

    final existingReservations = await query.get();
    return existingReservations.isEmpty;
  }

  /// 테이블에 이미 배정된 예약이 있는지 확인
  Future<bool> isTableAlreadyReserved({
    required int tableId,
    required DateTime date,
    int? excludeReservationId,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    var query = select(reservations)
      ..where((r) =>
          r.tableId.equals(tableId) &
          r.reservationDate.isBetweenValues(startOfDay, endOfDay) &
          (r.status.equals('CONFIRMED') | r.status.equals('PENDING')));

    if (excludeReservationId != null) {
      query = query..where((r) => r.id.equals(excludeReservationId).not());
    }

    final existingReservations = await query.get();
    return existingReservations.isNotEmpty;
  }
}

import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/attendance_logs.dart';
import '../../../database/tables/leave_requests.dart';
import '../../../database/tables/work_schedules.dart';
import '../../../database/tables/leave_balances.dart';

part 'attendance_dao.g.dart';

@DriftAccessor(tables: [
  AttendanceLogs,
  LeaveRequests,
  WorkSchedules,
  LeaveBalances,
])
class AttendanceDao extends DatabaseAccessor<AppDatabase>
    with _$AttendanceDaoMixin {
  AttendanceDao(super.db);

  // ═══════════════════════════════════════════════════════
  // 출퇴근 기록
  // ═══════════════════════════════════════════════════════

  /// 출근 기록 생성
  Future<int> checkIn(AttendanceLogsCompanion entry) {
    return into(attendanceLogs).insert(entry);
  }

  /// 퇴근 기록 업데이트
  Future<bool> checkOut({
    required int employeeId,
    required DateTime checkOutTime,
    String? note,
    int? totalMinutes,
    int? regularMinutes,
    int? overtimeMinutes,
    int? nightMinutes,
    bool isEarlyLeave = false,
  }) {
    return (update(attendanceLogs)
          ..where((log) =>
              log.employeeId.equals(employeeId) &
              log.status.equals('working')))
        .write(AttendanceLogsCompanion(
      checkOutTime: Value(checkOutTime),
      checkOutNote: Value(note),
      totalMinutes: Value(totalMinutes),
      regularMinutes: Value(regularMinutes),
      overtimeMinutes: Value(overtimeMinutes),
      nightMinutes: Value(nightMinutes),
      isEarlyLeave: Value(isEarlyLeave),
      status: Value('completed'),
      updatedAt: Value(DateTime.now()),
    )).then((rows) => rows > 0);
  }

  /// 특정 직원의 오늘 출근 기록 조회
  Future<AttendanceLog?> getTodayAttendance(int employeeId) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(attendanceLogs)
          ..where((log) =>
              log.employeeId.equals(employeeId) &
              log.workDate.isBiggerOrEqualValue(startOfDay) &
              log.workDate.isSmallerThanValue(endOfDay))
          ..limit(1))
        .getSingleOrNull();
  }

  /// 이미 출근했는지 확인
  Future<bool> isAlreadyCheckedIn(int employeeId, DateTime date) async {
    final log = await getTodayAttendance(employeeId);
    return log != null;
  }

  /// 현재 근무 중인 기록 조회
  Future<AttendanceLog?> getActiveWorkingLog(int employeeId) {
    return (select(attendanceLogs)
          ..where((log) =>
              log.employeeId.equals(employeeId) & log.status.equals('working'))
          ..limit(1))
        .getSingleOrNull();
  }

  /// 날짜 범위별 출근 기록 조회
  Future<List<AttendanceLog>> getAttendanceByDateRange(
    int employeeId,
    DateTime start,
    DateTime end,
  ) {
    return (select(attendanceLogs)
          ..where((log) =>
              log.employeeId.equals(employeeId) &
              log.workDate.isBiggerOrEqualValue(start) &
              log.workDate.isSmallerOrEqualValue(end))
          ..orderBy([(log) => OrderingTerm.desc(log.workDate)]))
        .get();
  }

  /// 월별 출근 기록 조회
  Future<List<AttendanceLog>> getAttendanceByMonth(
    int employeeId,
    int year,
    int month,
  ) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));
    return getAttendanceByDateRange(employeeId, start, end);
  }

  /// 최근 출근 기록 조회
  Future<List<AttendanceLog>> getRecentAttendance(int employeeId,
      {int limit = 30}) {
    return (select(attendanceLogs)
          ..where((log) => log.employeeId.equals(employeeId))
          ..orderBy([(log) => OrderingTerm.desc(log.workDate)])
          ..limit(limit))
        .get();
  }

  /// 출근 기록 스트림
  Stream<List<AttendanceLog>> watchRecentAttendance(int employeeId,
      {int limit = 30}) {
    return (select(attendanceLogs)
          ..where((log) => log.employeeId.equals(employeeId))
          ..orderBy([(log) => OrderingTerm.desc(log.workDate)])
          ..limit(limit))
        .watch();
  }

  /// 특정 날짜의 모든 직원 출근 현황
  Future<List<AttendanceLog>> getAllAttendanceByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(attendanceLogs)
          ..where((log) =>
              log.workDate.isBiggerOrEqualValue(startOfDay) &
              log.workDate.isSmallerThanValue(endOfDay))
          ..orderBy([(log) => OrderingTerm.asc(log.checkInTime)]))
        .get();
  }

  // ═══════════════════════════════════════════════════════
  // 통계
  // ═══════════════════════════════════════════════════════

  /// 이번 달 총 근무 시간 (분)
  Future<int> getTotalWorkMinutesThisMonth(int employeeId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final result = await customSelect(
      'SELECT COALESCE(SUM(total_minutes), 0) as total FROM attendance_logs '
      'WHERE employee_id = ? AND work_date >= ? AND work_date <= ? '
      'AND status = ?',
      variables: [
        Variable.withInt(employeeId),
        Variable.withInt(startOfMonth.millisecondsSinceEpoch),
        Variable.withInt(endOfMonth.millisecondsSinceEpoch),
        Variable.withString('completed'),
      ],
    ).getSingle();

    return result.read<int>('total');
  }

  /// 이번 달 연장 근무 시간 (분)
  Future<int> getOvertimeMinutesThisMonth(int employeeId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final result = await customSelect(
      'SELECT COALESCE(SUM(overtime_minutes), 0) as total FROM attendance_logs '
      'WHERE employee_id = ? AND work_date >= ? AND work_date <= ?',
      variables: [
        Variable.withInt(employeeId),
        Variable.withInt(startOfMonth.millisecondsSinceEpoch),
        Variable.withInt(endOfMonth.millisecondsSinceEpoch),
      ],
    ).getSingle();

    return result.read<int>('total');
  }

  /// 상태별 출근 통계
  Future<Map<String, int>> getAttendanceStatsByStatus(
    int employeeId,
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1).subtract(const Duration(days: 1));

    final results = await customSelect(
      'SELECT status, COUNT(*) as count FROM attendance_logs '
      'WHERE employee_id = ? AND work_date >= ? AND work_date <= ? '
      'GROUP BY status',
      variables: [
        Variable.withInt(employeeId),
        Variable.withInt(start.millisecondsSinceEpoch),
        Variable.withInt(end.millisecondsSinceEpoch),
      ],
    ).get();

    return {
      for (var row in results) row.read<String>('status'): row.read<int>('count')
    };
  }

  /// 이번 달 지각 횟수
  Future<int> getLateCountThisMonth(int employeeId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final result = await customSelect(
      'SELECT COUNT(*) as count FROM attendance_logs '
      'WHERE employee_id = ? AND work_date >= ? AND work_date <= ? '
      'AND is_late = 1',
      variables: [
        Variable.withInt(employeeId),
        Variable.withInt(startOfMonth.millisecondsSinceEpoch),
        Variable.withInt(endOfMonth.millisecondsSinceEpoch),
      ],
    ).getSingle();

    return result.read<int>('count');
  }

  // ═══════════════════════════════════════════════════════
  // 휴가 관리
  // ═══════════════════════════════════════════════════════

  /// 휴가 신청 생성
  Future<int> createLeaveRequest(LeaveRequestsCompanion entry) {
    return into(leaveRequests).insert(entry);
  }

  /// 휴가 신청 상태 업데이트
  Future<bool> updateLeaveRequestStatus({
    required int requestId,
    required String status,
    required int reviewerId,
    String? note,
  }) {
    return (update(leaveRequests)..where((req) => req.id.equals(requestId)))
        .write(LeaveRequestsCompanion(
      status: Value(status),
      reviewedBy: Value(reviewerId),
      reviewedAt: Value(DateTime.now()),
      reviewNote: Value(note),
      updatedAt: Value(DateTime.now()),
    )).then((rows) => rows > 0);
  }

  /// 휴가 신청 조회
  Future<LeaveRequest?> getLeaveRequest(int requestId) {
    return (select(leaveRequests)..where((req) => req.id.equals(requestId)))
        .getSingleOrNull();
  }

  /// 직원의 휴가 신청 목록
  Future<List<LeaveRequest>> getLeaveRequestsByEmployee(int employeeId) {
    return (select(leaveRequests)
          ..where((req) => req.employeeId.equals(employeeId))
          ..orderBy([(req) => OrderingTerm.desc(req.createdAt)]))
        .get();
  }

  /// 대기 중인 휴가 신청 목록
  Future<List<LeaveRequest>> getPendingLeaveRequests() {
    return (select(leaveRequests)
          ..where((req) => req.status.equals('pending'))
          ..orderBy([(req) => OrderingTerm.asc(req.createdAt)]))
        .get();
  }

  /// 휴가 신청 스트림
  Stream<List<LeaveRequest>> watchLeaveRequests(int employeeId) {
    return (select(leaveRequests)
          ..where((req) => req.employeeId.equals(employeeId))
          ..orderBy([(req) => OrderingTerm.desc(req.createdAt)]))
        .watch();
  }

  /// 기간 내 승인된 휴가가 있는지 확인
  Future<bool> hasOverlappingApprovedLeave({
    required int employeeId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final results = await (select(leaveRequests)
          ..where((req) =>
              req.employeeId.equals(employeeId) &
              req.status.equals('approved') &
              ((req.startDate.isSmallerOrEqualValue(endDate) &
                  req.endDate.isBiggerOrEqualValue(startDate)))))
        .get();

    return results.isNotEmpty;
  }

  // ═══════════════════════════════════════════════════════
  // 휴가 잔여
  // ═══════════════════════════════════════════════════════

  /// 휴가 잔여 조회
  Future<LeaveBalance?> getLeaveBalance(int employeeId, int year) {
    return (select(leaveBalances)
          ..where((balance) =>
              balance.employeeId.equals(employeeId) &
              balance.year.equals(year)))
        .getSingleOrNull();
  }

  /// 휴가 잔여 업데이트
  Future<bool> updateLeaveBalance({
    required int employeeId,
    required String leaveType,
    required double days,
  }) async {
    final year = DateTime.now().year;
    final balance = await getLeaveBalance(employeeId, year);

    if (balance == null) {
      return false;
    }

    final updates = <String, double>{};

    switch (leaveType) {
      case 'annual':
        updates['annualUsed'] = balance.annualUsed + days;
        updates['annualRemaining'] = balance.annualRemaining - days;
        break;
      case 'sick':
        updates['sickUsed'] = balance.sickUsed + days;
        updates['sickRemaining'] = balance.sickRemaining - days;
        break;
      case 'personal':
        updates['personalUsed'] = balance.personalUsed + days;
        updates['personalRemaining'] = balance.personalRemaining - days;
        break;
    }

    if (updates.isEmpty) return false;

    return (update(leaveBalances)
          ..where((b) => b.employeeId.equals(employeeId) & b.year.equals(year)))
        .write(LeaveBalancesCompanion(
      annualUsed: Value(updates['annualUsed'] ?? balance.annualUsed),
      annualRemaining:
          Value(updates['annualRemaining'] ?? balance.annualRemaining),
      sickUsed: Value(updates['sickUsed'] ?? balance.sickUsed),
      sickRemaining: Value(updates['sickRemaining'] ?? balance.sickRemaining),
      personalUsed: Value(updates['personalUsed'] ?? balance.personalUsed),
      personalRemaining:
          Value(updates['personalRemaining'] ?? balance.personalRemaining),
      updatedAt: Value(DateTime.now()),
    )).then((rows) => rows > 0);
  }

  /// 휴가 잔여 스트림
  Stream<LeaveBalance?> watchLeaveBalance(int employeeId, int year) {
    return (select(leaveBalances)
          ..where((balance) =>
              balance.employeeId.equals(employeeId) &
              balance.year.equals(year)))
        .watchSingleOrNull();
  }

  // ═══════════════════════════════════════════════════════
  // 근무 스케줄
  // ═══════════════════════════════════════════════════════

  /// 근무 스케줄 생성
  Future<int> createWorkSchedule(WorkSchedulesCompanion entry) {
    return into(workSchedules).insert(entry);
  }

  /// 특정 날짜의 스케줄 조회
  Future<WorkSchedule?> getScheduleForDate(int employeeId, DateTime date) {
    final dayOfWeek = date.weekday % 7; // 0=일요일, 6=토요일

    return (select(workSchedules)
          ..where((schedule) =>
              schedule.employeeId.equals(employeeId) &
              schedule.dayOfWeek.equals(dayOfWeek) &
              schedule.isActive.equals(true) &
              schedule.effectiveFrom.isSmallerOrEqualValue(date) &
              (schedule.effectiveTo.isNull() |
                  schedule.effectiveTo.isBiggerOrEqualValue(date)))
          ..limit(1))
        .getSingleOrNull();
  }

  /// 활성 스케줄 조회
  Future<List<WorkSchedule>> getActiveSchedules(int employeeId) {
    final now = DateTime.now();

    return (select(workSchedules)
          ..where((schedule) =>
              schedule.employeeId.equals(employeeId) &
              schedule.isActive.equals(true) &
              schedule.effectiveFrom.isSmallerOrEqualValue(now) &
              (schedule.effectiveTo.isNull() |
                  schedule.effectiveTo.isBiggerOrEqualValue(now)))
          ..orderBy([(schedule) => OrderingTerm.asc(schedule.dayOfWeek)]))
        .get();
  }

  /// 스케줄 업데이트
  Future<bool> updateWorkSchedule(
    int scheduleId,
    WorkSchedulesCompanion updates,
  ) {
    return (update(workSchedules)
          ..where((schedule) => schedule.id.equals(scheduleId)))
        .write(updates)
        .then((rows) => rows > 0);
  }

  /// 스케줄 비활성화
  Future<bool> deactivateSchedule(int scheduleId) {
    return updateWorkSchedule(
      scheduleId,
      WorkSchedulesCompanion(
        isActive: Value(false),
        effectiveTo: Value(DateTime.now()),
      ),
    );
  }

  /// 스케줄 스트림
  Stream<List<WorkSchedule>> watchActiveSchedules(int employeeId) {
    final now = DateTime.now();

    return (select(workSchedules)
          ..where((schedule) =>
              schedule.employeeId.equals(employeeId) &
              schedule.isActive.equals(true) &
              schedule.effectiveFrom.isSmallerOrEqualValue(now) &
              (schedule.effectiveTo.isNull() |
                  schedule.effectiveTo.isBiggerOrEqualValue(now)))
          ..orderBy([(schedule) => OrderingTerm.asc(schedule.dayOfWeek)]))
        .watch();
  }
}

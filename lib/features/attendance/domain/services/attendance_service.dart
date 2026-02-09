import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';
import '../../data/attendance_dao.dart';

/// AttendanceDao Provider
final attendanceDaoProvider = Provider<AttendanceDao>((ref) {
  return ref.watch(databaseProvider).attendanceDao;
});

/// AttendanceService Provider
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  final dao = ref.watch(attendanceDaoProvider);
  return AttendanceService(dao);
});

// ═══════════════════════════════════════════════════════
// 결과 클래스들
// ═══════════════════════════════════════════════════════

/// 체크인 결과
class CheckInResult {
  final bool success;
  final int? logId;
  final bool isLate;
  final String? message;
  final DateTime? checkInTime;

  CheckInResult({
    required this.success,
    this.logId,
    this.isLate = false,
    this.message,
    this.checkInTime,
  });
}

/// 체크아웃 결과
class CheckOutResult {
  final bool success;
  final bool isEarlyLeave;
  final int? totalMinutes;
  final int? overtimeMinutes;
  final String? message;
  final DateTime? checkOutTime;

  CheckOutResult({
    required this.success,
    this.isEarlyLeave = false,
    this.totalMinutes,
    this.overtimeMinutes,
    this.message,
    this.checkOutTime,
  });
}

/// 근무 시간 분석 결과
class WorkTimeBreakdown {
  final int totalMinutes;
  final int regularMinutes;
  final int overtimeMinutes;
  final int nightMinutes;

  WorkTimeBreakdown({
    required this.totalMinutes,
    required this.regularMinutes,
    required this.overtimeMinutes,
    required this.nightMinutes,
  });
}

/// 휴가 신청 결과
class LeaveRequestResult {
  final bool success;
  final int? requestId;
  final String? errorMessage;

  LeaveRequestResult({
    required this.success,
    this.requestId,
    this.errorMessage,
  });
}

/// 월간 근태 리포트
class MonthlyAttendanceReport {
  final int employeeId;
  final int year;
  final int month;
  final int totalWorkDays;
  final int actualWorkDays;
  final int absentDays;
  final int lateDays;
  final int earlyLeaveDays;
  final int totalWorkMinutes;
  final int overtimeMinutes;
  final int nightMinutes;
  final Map<String, int> statusCounts;

  MonthlyAttendanceReport({
    required this.employeeId,
    required this.year,
    required this.month,
    required this.totalWorkDays,
    required this.actualWorkDays,
    required this.absentDays,
    required this.lateDays,
    required this.earlyLeaveDays,
    required this.totalWorkMinutes,
    required this.overtimeMinutes,
    required this.nightMinutes,
    required this.statusCounts,
  });

  String get formattedTotalWorkTime {
    final hours = totalWorkMinutes ~/ 60;
    final minutes = totalWorkMinutes % 60;
    return '$hours시간 $minutes분';
  }

  String get formattedOvertimeWorkTime {
    final hours = overtimeMinutes ~/ 60;
    final minutes = overtimeMinutes % 60;
    return '$hours시간 $minutes분';
  }
}

// ═══════════════════════════════════════════════════════
// AttendanceService
// ═══════════════════════════════════════════════════════

class AttendanceService {
  final AttendanceDao _dao;

  AttendanceService(this._dao);

  // ═══════════════════════════════════════════════════════
  // 출퇴근 관리
  // ═══════════════════════════════════════════════════════

  /// 체크인
  Future<CheckInResult> checkIn({
    required int employeeId,
    String? note,
    String? location,
  }) async {
    try {
      // 1. 이미 출근했는지 확인
      final today = DateTime.now();
      final alreadyCheckedIn = await _dao.isAlreadyCheckedIn(employeeId, today);

      if (alreadyCheckedIn) {
        return CheckInResult(
          success: false,
          message: '이미 출근 처리되었습니다.',
        );
      }

      // 2. 오늘의 스케줄 조회
      final schedule = await _dao.getScheduleForDate(employeeId, today);

      if (schedule == null) {
        return CheckInResult(
          success: false,
          message: '오늘의 근무 스케줄이 없습니다.',
        );
      }

      if (schedule.shiftType == 'off') {
        return CheckInResult(
          success: false,
          message: '오늘은 휴무일입니다.',
        );
      }

      // 3. 지각 여부 판단
      final checkInTime = DateTime.now();
      final scheduledStart = _parseTimeToDateTime(schedule.startTime, today);
      final lateThreshold = scheduledStart.add(const Duration(minutes: 15));
      final isLate = checkInTime.isAfter(lateThreshold);

      // 4. 출근 기록 생성
      final logId = await _dao.checkIn(
        AttendanceLogsCompanion.insert(
          employeeId: employeeId,
          workDate: today,
          checkInTime: checkInTime,
          status: 'working',
          isLate: Value(isLate),
          checkInNote: Value(note),
          location: Value(location),
        ),
      );

      return CheckInResult(
        success: true,
        logId: logId,
        isLate: isLate,
        message: isLate ? '지각 처리되었습니다.' : '출근 처리되었습니다.',
        checkInTime: checkInTime,
      );
    } catch (e) {
      return CheckInResult(
        success: false,
        message: '출근 처리 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// 체크아웃
  Future<CheckOutResult> checkOut({
    required int employeeId,
    String? note,
  }) async {
    try {
      // 1. 현재 근무 중인 기록 조회
      final activeLog = await _dao.getActiveWorkingLog(employeeId);

      if (activeLog == null) {
        return CheckOutResult(
          success: false,
          message: '출근 기록이 없습니다.',
        );
      }

      // 2. 오늘의 스케줄 조회
      final schedule = await _dao.getScheduleForDate(
        employeeId,
        activeLog.workDate,
      );

      if (schedule == null) {
        return CheckOutResult(
          success: false,
          message: '근무 스케줄을 찾을 수 없습니다.',
        );
      }

      // 3. 퇴근 시간 및 근무 시간 계산
      final checkOutTime = DateTime.now();
      final workTime = calculateWorkTime(
        checkIn: activeLog.checkInTime,
        checkOut: checkOutTime,
        scheduledStart: _parseTimeToDateTime(
          schedule.startTime,
          activeLog.workDate,
        ),
        scheduledEnd: _parseTimeToDateTime(
          schedule.endTime,
          activeLog.workDate,
        ),
      );

      // 4. 조퇴 여부 판단
      final scheduledEnd = _parseTimeToDateTime(
        schedule.endTime,
        activeLog.workDate,
      );
      final earlyLeaveThreshold = scheduledEnd.subtract(
        const Duration(minutes: 30),
      );
      final isEarlyLeave = checkOutTime.isBefore(earlyLeaveThreshold);

      // 5. 체크아웃 처리
      final success = await _dao.checkOut(
        employeeId: employeeId,
        checkOutTime: checkOutTime,
        note: note,
        totalMinutes: workTime.totalMinutes,
        regularMinutes: workTime.regularMinutes,
        overtimeMinutes: workTime.overtimeMinutes,
        nightMinutes: workTime.nightMinutes,
        isEarlyLeave: isEarlyLeave,
      );

      if (!success) {
        return CheckOutResult(
          success: false,
          message: '퇴근 처리에 실패했습니다.',
        );
      }

      return CheckOutResult(
        success: true,
        isEarlyLeave: isEarlyLeave,
        totalMinutes: workTime.totalMinutes,
        overtimeMinutes: workTime.overtimeMinutes,
        message: isEarlyLeave ? '조퇴 처리되었습니다.' : '퇴근 처리되었습니다.',
        checkOutTime: checkOutTime,
      );
    } catch (e) {
      return CheckOutResult(
        success: false,
        message: '퇴근 처리 중 오류가 발생했습니다: $e',
      );
    }
  }

  // ═══════════════════════════════════════════════════════
  // 근무 시간 계산
  // ═══════════════════════════════════════════════════════

  /// 근무 시간 계산
  WorkTimeBreakdown calculateWorkTime({
    required DateTime checkIn,
    required DateTime checkOut,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
  }) {
    final totalMinutes = checkOut.difference(checkIn).inMinutes;

    // 정규 근무 시간: 스케줄 기준 시간 (최대)
    final scheduledMinutes = scheduledEnd.difference(scheduledStart).inMinutes;
    final regularMinutes = totalMinutes > scheduledMinutes
        ? scheduledMinutes
        : totalMinutes;

    // 연장 근무: 스케줄 종료 시간 이후 근무
    final overtimeMinutes = totalMinutes > scheduledMinutes
        ? totalMinutes - scheduledMinutes
        : 0;

    // 야간 근무: 22:00 ~ 06:00 사이 근무 시간
    final nightMinutes = _calculateNightMinutes(checkIn, checkOut);

    return WorkTimeBreakdown(
      totalMinutes: totalMinutes,
      regularMinutes: regularMinutes,
      overtimeMinutes: overtimeMinutes,
      nightMinutes: nightMinutes,
    );
  }

  /// 야간 근무 시간 계산 (22:00 ~ 06:00)
  int _calculateNightMinutes(DateTime start, DateTime end) {
    int nightMinutes = 0;
    DateTime current = start;

    while (current.isBefore(end)) {
      final nextHour = DateTime(
        current.year,
        current.month,
        current.day,
        current.hour + 1,
      );
      final segmentEnd = nextHour.isAfter(end) ? end : nextHour;

      // 22시 ~ 06시 사이인지 확인
      if (current.hour >= 22 || current.hour < 6) {
        nightMinutes += segmentEnd.difference(current).inMinutes;
      }

      current = segmentEnd;
    }

    return nightMinutes;
  }

  /// 지각 여부 판단
  bool isLate(DateTime checkIn, DateTime scheduledStart) {
    final lateThreshold = scheduledStart.add(const Duration(minutes: 15));
    return checkIn.isAfter(lateThreshold);
  }

  /// 조퇴 여부 판단
  bool isEarlyLeave(DateTime checkOut, DateTime scheduledEnd) {
    final earlyLeaveThreshold = scheduledEnd.subtract(
      const Duration(minutes: 30),
    );
    return checkOut.isBefore(earlyLeaveThreshold);
  }

  // ═══════════════════════════════════════════════════════
  // 휴가 관리
  // ═══════════════════════════════════════════════════════

  /// 휴가 신청
  Future<LeaveRequestResult> requestLeave({
    required int employeeId,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String? attachments,
  }) async {
    try {
      // 1. 휴가 일수 계산
      final days = _calculateLeaveDays(startDate, endDate);

      // 2. 휴가 잔여일 확인
      final year = DateTime.now().year;
      final balance = await _dao.getLeaveBalance(employeeId, year);

      if (balance == null) {
        return LeaveRequestResult(
          success: false,
          errorMessage: '휴가 잔여 정보를 찾을 수 없습니다.',
        );
      }

      // 3. 잔여일 검증
      final remaining = _getRemaining(balance, leaveType);
      if (remaining < days) {
        return LeaveRequestResult(
          success: false,
          errorMessage: '휴가 잔여일이 부족합니다. (신청: $days일, 잔여: $remaining일)',
        );
      }

      // 4. 중복 신청 방지
      final hasOverlap = await _dao.hasOverlappingApprovedLeave(
        employeeId: employeeId,
        startDate: startDate,
        endDate: endDate,
      );

      if (hasOverlap) {
        return LeaveRequestResult(
          success: false,
          errorMessage: '이미 승인된 휴가와 기간이 겹칩니다.',
        );
      }

      // 5. 휴가 신청 생성
      final requestId = await _dao.createLeaveRequest(
        LeaveRequestsCompanion.insert(
          employeeId: employeeId,
          leaveType: leaveType,
          startDate: startDate,
          endDate: endDate,
          days: days,
          reason: reason,
          status: 'pending',
          attachments: Value(attachments),
        ),
      );

      return LeaveRequestResult(
        success: true,
        requestId: requestId,
      );
    } catch (e) {
      return LeaveRequestResult(
        success: false,
        errorMessage: '휴가 신청 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// 휴가 승인
  Future<bool> approveLeave({
    required int requestId,
    required int approverId,
    String? note,
  }) async {
    try {
      // 1. 휴가 신청 조회
      final request = await _dao.getLeaveRequest(requestId);
      if (request == null) return false;

      // 2. 상태 업데이트
      final updated = await _dao.updateLeaveRequestStatus(
        requestId: requestId,
        status: 'approved',
        reviewerId: approverId,
        note: note,
      );

      if (!updated) return false;

      // 3. 휴가 잔여일 차감
      await _dao.updateLeaveBalance(
        employeeId: request.employeeId,
        leaveType: request.leaveType,
        days: request.days,
      );

      // 4. 해당 기간에 absent 로그 생성
      await _createAbsentLogsForLeave(request);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 휴가 거절
  Future<bool> rejectLeave({
    required int requestId,
    required int approverId,
    String? note,
  }) async {
    return await _dao.updateLeaveRequestStatus(
      requestId: requestId,
      status: 'rejected',
      reviewerId: approverId,
      note: note,
    );
  }

  /// 휴가 기간에 absent 로그 생성
  Future<void> _createAbsentLogsForLeave(LeaveRequest request) async {
    DateTime current = request.startDate;
    final end = request.endDate;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      // 주말은 제외
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        final schedule = await _dao.getScheduleForDate(
          request.employeeId,
          current,
        );

        if (schedule != null && schedule.shiftType != 'off') {
          final alreadyExists = await _dao.getTodayAttendance(
            request.employeeId,
          );

          if (alreadyExists == null) {
            await _dao.checkIn(
              AttendanceLogsCompanion.insert(
                employeeId: request.employeeId,
                workDate: current,
                checkInTime: current,
                status: 'absent',
                checkInNote: Value('휴가: ${request.leaveType}'),
              ),
            );
          }
        }
      }

      current = current.add(const Duration(days: 1));
    }
  }

  // ═══════════════════════════════════════════════════════
  // 통계 및 리포트
  // ═══════════════════════════════════════════════════════

  /// 월간 근태 리포트
  Future<MonthlyAttendanceReport> getMonthlyReport(
    int employeeId,
    int year,
    int month,
  ) async {
    // 1. 해당 월의 출근 기록 조회
    final logs = await _dao.getAttendanceByMonth(employeeId, year, month);

    // 2. 상태별 통계
    final statusCounts = await _dao.getAttendanceStatsByStatus(
      employeeId,
      year,
      month,
    );

    // 3. 근무 시간 통계
    final totalWorkMinutes = await _dao.getTotalWorkMinutesThisMonth(
      employeeId,
    );
    final overtimeMinutes = await _dao.getOvertimeMinutesThisMonth(
      employeeId,
    );

    // 4. 지각/조퇴 카운트
    final lateDays = logs.where((log) => log.isLate).length;
    final earlyLeaveDays = logs.where((log) => log.isEarlyLeave).length;
    final absentDays = logs.where((log) => log.status == 'absent').length;

    // 5. 총 근무일 (월~금)
    final totalWorkDays = _countWeekdaysInMonth(year, month);
    final actualWorkDays = logs.where((log) => log.status == 'completed').length;

    // 6. 야간 근무 합계
    final nightMinutes = logs
        .where((log) => log.nightMinutes != null)
        .fold<int>(0, (sum, log) => sum + (log.nightMinutes ?? 0));

    return MonthlyAttendanceReport(
      employeeId: employeeId,
      year: year,
      month: month,
      totalWorkDays: totalWorkDays,
      actualWorkDays: actualWorkDays,
      absentDays: absentDays,
      lateDays: lateDays,
      earlyLeaveDays: earlyLeaveDays,
      totalWorkMinutes: totalWorkMinutes,
      overtimeMinutes: overtimeMinutes,
      nightMinutes: nightMinutes,
      statusCounts: statusCounts,
    );
  }

  /// 오늘 지각한 직원 목록
  Future<List<AttendanceLog>> getLateEmployees(DateTime date) async {
    final logs = await _dao.getAllAttendanceByDate(date);
    return logs.where((log) => log.isLate).toList();
  }

  /// 오늘 결근한 직원 목록 (스케줄은 있으나 출근 기록 없음)
  Future<List<AttendanceLog>> getAbsentEmployees(DateTime date) async {
    final logs = await _dao.getAllAttendanceByDate(date);
    return logs.where((log) => log.status == 'absent').toList();
  }

  // ═══════════════════════════════════════════════════════
  // 자동화 배치 작업
  // ═══════════════════════════════════════════════════════

  /// 자동 체크아웃: 미체크아웃 직원 처리
  Future<void> autoCheckOutMissing() async {
    // 구현 예정: 전날 working 상태인 기록을 스케줄 종료 시간으로 자동 체크아웃
  }

  /// 결근 처리: 스케줄은 있으나 출근 기록 없는 직원
  Future<void> processAbsentees() async {
    // 구현 예정: 매일 자정에 실행하여 결근자 자동 기록
  }

  /// 휴가자 absent 로그 생성
  Future<void> createAbsentLogsForLeaves() async {
    // 구현 예정: 승인된 휴가 기간에 자동으로 absent 로그 생성
  }

  // ═══════════════════════════════════════════════════════
  // 유틸리티 메서드
  // ═══════════════════════════════════════════════════════

  /// 문자열 시간을 DateTime으로 변환
  DateTime _parseTimeToDateTime(String time, DateTime date) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  /// 휴가 일수 계산 (주말 제외)
  double _calculateLeaveDays(DateTime start, DateTime end) {
    int days = 0;
    DateTime current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      // 주말 제외
      if (current.weekday != DateTime.saturday &&
          current.weekday != DateTime.sunday) {
        days++;
      }
      current = current.add(const Duration(days: 1));
    }

    return days.toDouble();
  }

  /// 휴가 타입별 잔여일 조회
  double _getRemaining(LeaveBalance balance, String leaveType) {
    switch (leaveType) {
      case 'annual':
        return balance.annualRemaining;
      case 'sick':
        return balance.sickRemaining;
      case 'personal':
        return balance.personalRemaining;
      default:
        return 0.0;
    }
  }

  /// 해당 월의 평일(월~금) 일수 계산
  int _countWeekdaysInMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0);
    int count = 0;

    for (int day = 1; day <= lastDay.day; day++) {
      final date = DateTime(year, month, day);
      if (date.weekday != DateTime.saturday &&
          date.weekday != DateTime.sunday) {
        count++;
      }
    }

    return count;
  }
}

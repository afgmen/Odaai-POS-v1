import 'package:drift/drift.dart';
import 'employees.dart';

/// 출퇴근 기록 테이블
/// 직원의 출근, 퇴근 시간과 근무 시간을 기록합니다.
class AttendanceLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 직원 정보
  IntColumn get employeeId => integer()
      .named('employee_id')
      .references(Employees, #id, onDelete: KeyAction.cascade)();

  // 날짜 및 시간
  DateTimeColumn get workDate => dateTime().named('work_date')(); // 근무일
  DateTimeColumn get checkInTime =>
      dateTime().named('check_in_time')(); // 출근 시간
  DateTimeColumn get checkOutTime =>
      dateTime().nullable().named('check_out_time')(); // 퇴근 시간

  // 근무 시간 (분 단위)
  IntColumn get totalMinutes =>
      integer().nullable().named('total_minutes')(); // 총 근무 시간
  IntColumn get regularMinutes =>
      integer().nullable().named('regular_minutes')(); // 정규 근무
  IntColumn get overtimeMinutes =>
      integer().nullable().named('overtime_minutes')(); // 연장 근무
  IntColumn get nightMinutes =>
      integer().nullable().named('night_minutes')(); // 야간 근무

  // 상태 및 플래그
  TextColumn get status => text()();
  // 'working' | 'completed' | 'absent' | 'late' | 'early_leave'
  BoolColumn get isLate =>
      boolean().named('is_late').withDefault(const Constant(false))();
  BoolColumn get isEarlyLeave =>
      boolean().named('is_early_leave').withDefault(const Constant(false))();

  // 메모 및 위치
  TextColumn get checkInNote => text().nullable().named('check_in_note')();
  TextColumn get checkOutNote => text().nullable().named('check_out_note')();
  TextColumn get location => text().nullable()(); // GPS 좌표 또는 위치명

  // 승인 정보
  IntColumn get approvedBy => integer().nullable().named('approved_by')();
  DateTimeColumn get approvedAt => dateTime().nullable().named('approved_at')();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();
}

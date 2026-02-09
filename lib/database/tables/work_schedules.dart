import 'package:drift/drift.dart';
import 'employees.dart';

/// 근무 스케줄 테이블
/// 직원의 주간 근무 스케줄을 정의합니다.
class WorkSchedules extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 직원 정보
  IntColumn get employeeId => integer()
      .named('employee_id')
      .references(Employees, #id, onDelete: KeyAction.cascade)();

  // 스케줄 정보
  IntColumn get dayOfWeek =>
      integer().named('day_of_week')(); // 0=일요일, 6=토요일
  TextColumn get shiftType =>
      text().named('shift_type')(); // 'day' | 'night' | 'off'

  // 근무 시간
  TextColumn get startTime => text().named('start_time')(); // HH:mm 형식
  TextColumn get endTime => text().named('end_time')(); // HH:mm 형식
  IntColumn get plannedMinutes =>
      integer().named('planned_minutes')(); // 계획된 근무 시간

  // 유효 기간
  DateTimeColumn get effectiveFrom => dateTime().named('effective_from')();
  DateTimeColumn get effectiveTo =>
      dateTime().nullable().named('effective_to')();

  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
}

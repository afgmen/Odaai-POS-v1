import 'package:drift/drift.dart';
import 'employees.dart';

/// 휴가 잔여 테이블
/// 직원의 연차별 휴가 사용 및 잔여 일수를 추적합니다.
class LeaveBalances extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get employeeId => integer()
      .named('employee_id')
      .unique()
      .references(Employees, #id, onDelete: KeyAction.cascade)();

  // 연차
  RealColumn get annualTotal => real().named('annual_total')(); // 총 연차 일수
  RealColumn get annualUsed => real().named('annual_used')(); // 사용한 연차
  RealColumn get annualRemaining =>
      real().named('annual_remaining')(); // 남은 연차

  // 병가
  RealColumn get sickTotal => real().named('sick_total')();
  RealColumn get sickUsed => real().named('sick_used')();
  RealColumn get sickRemaining => real().named('sick_remaining')();

  // 기타
  RealColumn get personalTotal => real().named('personal_total')();
  RealColumn get personalUsed => real().named('personal_used')();
  RealColumn get personalRemaining => real().named('personal_remaining')();

  // 연도 정보
  IntColumn get year => integer()();

  DateTimeColumn get updatedAt =>
      dateTime().named('updated_at').withDefault(currentDateAndTime)();
}

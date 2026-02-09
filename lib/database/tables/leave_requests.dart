import 'package:drift/drift.dart';
import 'employees.dart';

/// 휴가 신청 테이블
/// 직원의 휴가 신청과 승인 워크플로우를 관리합니다.
class LeaveRequests extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 직원 정보
  IntColumn get employeeId => integer()
      .named('employee_id')
      .references(Employees, #id, onDelete: KeyAction.cascade)();

  // 휴가 정보
  TextColumn get leaveType => text().named('leave_type')();
  // 'annual' | 'sick' | 'personal' | 'maternity' | 'paternity' | 'unpaid'

  DateTimeColumn get startDate => dateTime().named('start_date')();
  DateTimeColumn get endDate => dateTime().named('end_date')();
  RealColumn get days => real()(); // 휴가 일수 (0.5일 단위)

  TextColumn get reason => text()();
  TextColumn get attachments =>
      text().nullable()(); // JSON array of file paths

  // 승인 워크플로우
  TextColumn get status => text()();
  // 'pending' | 'approved' | 'rejected' | 'cancelled'

  IntColumn get reviewedBy => integer().nullable().named('reviewed_by')();
  DateTimeColumn get reviewedAt => dateTime().nullable().named('reviewed_at')();
  TextColumn get reviewNote => text().nullable().named('review_note')();

  DateTimeColumn get createdAt =>
      dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable().named('updated_at')();
}

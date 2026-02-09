// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_dao.dart';

// ignore_for_file: type=lint
mixin _$AttendanceDaoMixin on DatabaseAccessor<AppDatabase> {
  $EmployeesTable get employees => attachedDatabase.employees;
  $AttendanceLogsTable get attendanceLogs => attachedDatabase.attendanceLogs;
  $LeaveRequestsTable get leaveRequests => attachedDatabase.leaveRequests;
  $WorkSchedulesTable get workSchedules => attachedDatabase.workSchedules;
  $LeaveBalancesTable get leaveBalances => attachedDatabase.leaveBalances;
  AttendanceDaoManager get managers => AttendanceDaoManager(this);
}

class AttendanceDaoManager {
  final _$AttendanceDaoMixin _db;
  AttendanceDaoManager(this._db);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$AttendanceLogsTableTableManager get attendanceLogs =>
      $$AttendanceLogsTableTableManager(
        _db.attachedDatabase,
        _db.attendanceLogs,
      );
  $$LeaveRequestsTableTableManager get leaveRequests =>
      $$LeaveRequestsTableTableManager(_db.attachedDatabase, _db.leaveRequests);
  $$WorkSchedulesTableTableManager get workSchedules =>
      $$WorkSchedulesTableTableManager(_db.attachedDatabase, _db.workSchedules);
  $$LeaveBalancesTableTableManager get leaveBalances =>
      $$LeaveBalancesTableTableManager(_db.attachedDatabase, _db.leaveBalances);
}

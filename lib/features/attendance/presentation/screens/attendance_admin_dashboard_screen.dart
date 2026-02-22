import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../data/attendance_dao.dart';
import '../../domain/services/attendance_service.dart';
import 'employee_attendance_detail_screen.dart';
import 'leave_approval_screen.dart';

/// 관리자용 근태 관리 대시보드
class AttendanceAdminDashboardScreen extends ConsumerStatefulWidget {
  const AttendanceAdminDashboardScreen({super.key});

  @override
  ConsumerState<AttendanceAdminDashboardScreen> createState() =>
      _AttendanceAdminDashboardScreenState();
}

class _AttendanceAdminDashboardScreenState
    extends ConsumerState<AttendanceAdminDashboardScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceDao = ref.watch(attendanceDaoProvider);
    final attendanceService = ref.watch(attendanceServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Management'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.approval),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaveApprovalScreen(),
                ),
              );
            },
            tooltip: 'Leave Approval',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 날짜 선택
              Card(
                child: InkWell(
                  onTap: _selectDate,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy (E)', 'vi')
                                    .format(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 오늘의 현황 요약
              _buildTodaySummary(attendanceDao, _selectedDate),
              const SizedBox(height: 16),

              // 승인 대기 휴가
              _buildPendingLeaveRequests(attendanceDao),
              const SizedBox(height: 16),

              // 주의 필요 직원
              _buildAttentionRequired(attendanceDao, attendanceService),
              const SizedBox(height: 16),

              // 전체 직원 출근 현황
              _buildAllEmployeesStatus(attendanceDao, _selectedDate),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySummary(AttendanceDao dao, DateTime date) {
    return FutureBuilder<List<AttendanceLog>>(
      future: dao.getAllAttendanceByDate(date),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final logs = snapshot.data ?? [];
        final working = logs.where((log) => log.status == 'working').length;
        final completed = logs.where((log) => log.status == 'completed').length;
        final absent = logs.where((log) => log.status == 'absent').length;
        final late = logs.where((log) => log.isLate).length;
        final total = logs.length;

        return Card(
          color: AppTheme.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dashboard, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      "Today's Status",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (DateFormat('yyyy-MM-dd').format(date) ==
                        DateFormat('yyyy-MM-dd').format(DateTime.now()))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Total',
                        total.toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Working',
                        working.toString(),
                        Icons.work,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Checked Out',
                        completed.toString(),
                        Icons.check_circle,
                        Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Late',
                        late.toString(),
                        Icons.warning,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Absent',
                        absent.toString(),
                        Icons.cancel,
                        Colors.red,
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingLeaveRequests(AttendanceDao dao) {
    return FutureBuilder<List<LeaveRequest>>(
      future: dao.getPendingLeaveRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final requests = snapshot.data ?? [];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notification_important,
                        color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Pending Approval',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (requests.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${requests.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 24),
                if (requests.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No pending leave requests',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...requests.take(3).map((request) =>
                      _buildPendingLeaveItem(request, dao)),
                if (requests.length > 3)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LeaveApprovalScreen(),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingLeaveItem(LeaveRequest request, AttendanceDao dao) {
    return FutureBuilder<Employee?>(
      future: dao.attachedDatabase.employeesDao
          .getEmployee(request.employeeId),
      builder: (context, snapshot) {
        final employee = snapshot.data;
        final employeeName = employee?.name ?? 'Employee ${request.employeeId}';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeaveApprovalScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.orange[200],
                    child: Text(
                      employeeName[0],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employeeName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getLeaveTypeName(request.leaveType)} • '
                          '${DateFormat('MM/dd').format(request.startDate)} ~ '
                          '${DateFormat('MM/dd').format(request.endDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttentionRequired(
    AttendanceDao dao,
    AttendanceService service,
  ) {
    final now = DateTime.now();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Attention Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            FutureBuilder<List<AttendanceLog>>(
              future: service.getLateEmployees(now),
              builder: (context, lateSnapshot) {
                return FutureBuilder(
                  future: Future.wait([
                    for (var i = 1; i <= 5; i++)
                      dao.getLateCountThisMonth(i),
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final lateCounts = snapshot.data ?? [];
                    final hasWarnings = lateCounts.any((count) => count >= 3);

                    if (!hasWarnings &&
                        (lateSnapshot.data?.isEmpty ?? true)) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No attention required',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        if (lateSnapshot.data?.isNotEmpty ?? false)
                          ...lateSnapshot.data!.take(3).map(
                                (log) => _buildWarningItem(
                                  dao,
                                  log.employeeId,
                                  'Late today',
                                  Icons.schedule,
                                ),
                              ),
                        for (var i = 0; i < lateCounts.length; i++)
                          if (lateCounts[i] >= 3)
                            _buildWarningItem(
                              dao,
                              i + 1,
                              'Late this month: ${lateCounts[i]}x',
                              Icons.warning,
                            ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningItem(
    AttendanceDao dao,
    int employeeId,
    String warning,
    IconData icon,
  ) {
    return FutureBuilder<Employee?>(
      future: dao.attachedDatabase.employeesDao.getEmployee(employeeId),
      builder: (context, snapshot) {
        final employee = snapshot.data;
        final employeeName = employee?.name ?? 'Employee $employeeId';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              if (employee != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EmployeeAttendanceDetailScreen(employee: employee),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.red[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$employeeName - $warning',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllEmployeesStatus(AttendanceDao dao, DateTime date) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.people, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  'All Employee Attendance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            FutureBuilder(
              future: Future.wait([
                dao.getAllAttendanceByDate(date),
                dao.attachedDatabase.employeesDao.getAllEmployees(),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final logs = (snapshot.data?[0] as List<AttendanceLog>?) ?? [];
                final employees = (snapshot.data?[1] as List<Employee>?) ?? [];

                if (employees.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No employees registered',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return Column(
                  children: employees.map((employee) {
                    final log = logs.firstWhere(
                      (l) => l.employeeId == employee.id,
                      orElse: () => AttendanceLog(
                        id: 0,
                        employeeId: employee.id,
                        workDate: date,
                        checkInTime: date,
                        status: 'not_checked_in',
                        isLate: false,
                        isEarlyLeave: false,
                        createdAt: date,
                      ),
                    );

                    return _buildEmployeeStatusItem(employee, log);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeStatusItem(Employee employee, AttendanceLog log) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (log.status) {
      case 'working':
        statusColor = Colors.green;
        statusIcon = Icons.work;
        statusText = 'Working';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        statusText = 'Checked Out';
        break;
      case 'absent':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Absent';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.pending;
        statusText = 'Not In';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  EmployeeAttendanceDetailScreen(employee: employee),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: Text(
                  employee.name[0],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (log.status != 'not_checked_in')
                      Text(
                        'In: ${DateFormat('HH:mm').format(log.checkInTime)}'
                        '${log.isLate ? ' (Late)' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: log.isLate ? Colors.red : Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  String _getLeaveTypeName(String type) {
    switch (type) {
      case 'annual':
        return 'Annual Leave';
      case 'sick':
        return 'Sick Leave';
      case 'personal':
        return 'Personal Leave';
      case 'maternity':
        return 'Maternity Leave';
      case 'paternity':
        return 'Paternity Leave';
      case 'unpaid':
        return 'Unpaid Leave';
      default:
        return type;
    }
  }
}

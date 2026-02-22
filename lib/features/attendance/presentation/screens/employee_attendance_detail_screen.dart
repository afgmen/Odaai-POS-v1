import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../data/attendance_dao.dart';
import '../../domain/services/attendance_service.dart';

/// 직원별 근태 상세 화면
class EmployeeAttendanceDetailScreen extends ConsumerStatefulWidget {
  final Employee employee;

  const EmployeeAttendanceDetailScreen({
    super.key,
    required this.employee,
  });

  @override
  ConsumerState<EmployeeAttendanceDetailScreen> createState() =>
      _EmployeeAttendanceDetailScreenState();
}

class _EmployeeAttendanceDetailScreenState
    extends ConsumerState<EmployeeAttendanceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showMonthPicker() async {
    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => _MonthPickerDialog(
        initialYear: _selectedYear,
        initialMonth: _selectedMonth,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedYear = result['year']!;
        _selectedMonth = result['month']!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceDao = ref.watch(attendanceDaoProvider);
    final attendanceService = ref.watch(attendanceServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.employee.name} - Attendance'),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _showMonthPicker,
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            label: Text(
              '$_selectedYear / $_selectedMonth',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Attendance Log'),
            Tab(text: 'Leave Status'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(attendanceService),
          _buildAttendanceTab(attendanceDao),
          _buildLeaveTab(attendanceDao),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(AttendanceService service) {
    return FutureBuilder<MonthlyAttendanceReport>(
      future: service.getMonthlyReport(
        widget.employee.id,
        _selectedYear,
        _selectedMonth,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final report = snapshot.data;
        if (report == null) {
          return const Center(child: Text('Unable to load data.'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 직원 정보
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.primary,
                        child: Text(
                          widget.employee.name[0],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.employee.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getRoleName(widget.employee.role),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
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
                          color: widget.employee.isActive
                              ? Colors.green[100]
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.employee.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.employee.isActive
                                ? Colors.green[700]
                                : Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 이번 달 통계
              Card(
                color: AppTheme.primary.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Stats ($_selectedYear / $_selectedMonth)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildStatRow('Work Days',
                          '${report.actualWorkDays} / ${report.totalWorkDays} days'),
                      _buildStatRow('Total Work', report.formattedTotalWorkTime),
                      _buildStatRow(
                          'Overtime', report.formattedOvertimeWorkTime),
                      _buildStatRow('Late', '${report.lateDays}x',
                          isWarning: report.lateDays > 0),
                      _buildStatRow('Early Leave', '${report.earlyLeaveDays}x',
                          isWarning: report.earlyLeaveDays > 0),
                      _buildStatRow('Absent', '${report.absentDays} days',
                          isWarning: report.absentDays > 0),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 상태별 분포
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Distribution',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      if (report.statusCounts.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No data',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...report.statusCounts.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_getStatusText(entry.key)),
                                Text(
                                  '${entry.value} days',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTab(AttendanceDao dao) {
    return FutureBuilder<List<AttendanceLog>>(
      future: dao.getAttendanceByMonth(
        widget.employee.id,
        _selectedYear,
        _selectedMonth,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No attendance records',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            return _buildAttendanceCard(logs[index]);
          },
        );
      },
    );
  }

  Widget _buildLeaveTab(AttendanceDao dao) {
    final year = DateTime.now().year;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 휴가 잔여
          FutureBuilder<LeaveBalance?>(
            future: dao.getLeaveBalance(widget.employee.id, year),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final balance = snapshot.data;
              if (balance == null) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Unable to load leave information.'),
                  ),
                );
              }

              return Card(
                color: AppTheme.primary.withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Leave Balance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      _buildBalanceRow(
                        'Annual Leave',
                        balance.annualRemaining,
                        balance.annualTotal,
                        balance.annualUsed,
                      ),
                      _buildBalanceRow(
                        'Sick Leave',
                        balance.sickRemaining,
                        balance.sickTotal,
                        balance.sickUsed,
                      ),
                      _buildBalanceRow(
                        'Personal Leave',
                        balance.personalRemaining,
                        balance.personalTotal,
                        balance.personalUsed,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // 휴가 신청 내역
          StreamBuilder<List<LeaveRequest>>(
            stream: dao.watchLeaveRequests(widget.employee.id),
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
                      const Text(
                        'Leave History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      if (requests.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No leave history',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...requests.map((request) =>
                            _buildLeaveRequestCard(request)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isWarning ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceRow(
    String label,
    double remaining,
    double total,
    double used,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 16)),
              Text(
                '${remaining.toStringAsFixed(1)} / ${total.toStringAsFixed(1)} days',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: total > 0 ? (total - remaining) / total : 0,
            backgroundColor: Colors.grey[300],
            valueColor:
                AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
          const SizedBox(height: 4),
          Text(
            'Used: ${used.toStringAsFixed(1)} days',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceLog log) {
    final isAbsent = log.status == 'absent';
    final isCompleted = log.status == 'completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy (E)', 'vi').format(log.workDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(log.status),
              ],
            ),
            if (!isAbsent) ...[
              const Divider(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Check-in', style: TextStyle(color: Colors.grey[600])),
                        Text(
                          DateFormat('HH:mm').format(log.checkInTime),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (log.isLate)
                          Text(
                            'Late',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (log.checkOutTime != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Check-out',
                              style: TextStyle(color: Colors.grey[600])),
                          Text(
                            DateFormat('HH:mm').format(log.checkOutTime!),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (log.isEarlyLeave)
                            Text(
                              'Early Leave',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              if (isCompleted && log.totalMinutes != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Total: ${(log.totalMinutes! ~/ 60)}h ${(log.totalMinutes! % 60)}m',
                  style: const TextStyle(color: AppTheme.primary),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'working':
        color = Colors.green;
        text = 'Working';
        break;
      case 'completed':
        color = Colors.blue;
        text = 'Completed';
        break;
      case 'absent':
        color = Colors.red;
        text = 'Absent';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLeaveRequestCard(LeaveRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getLeaveTypeName(request.leaveType),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(request.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${DateFormat('yyyy-MM-dd').format(request.startDate)} ~ '
              '${DateFormat('yyyy-MM-dd').format(request.endDate)} '
              '(${request.days.toStringAsFixed(1)} days)',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(request.reason),
          ],
        ),
      ),
    );
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'manager':
        return 'Manager';
      case 'cashier':
        return 'Staff';
      default:
        return role;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'working':
        return 'Working';
      case 'completed':
        return 'Completed';
      case 'absent':
        return 'Absent';
      default:
        return status;
    }
  }

  String _getLeaveTypeName(String type) {
    switch (type) {
      case 'annual':
        return 'Annual Leave';
      case 'sick':
        return 'Sick Leave';
      case 'personal':
        return 'Personal Leave';
      default:
        return type;
    }
  }
}

/// 월 선택 다이얼로그
class _MonthPickerDialog extends StatefulWidget {
  final int initialYear;
  final int initialMonth;

  const _MonthPickerDialog({
    required this.initialYear,
    required this.initialMonth,
  });

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    return AlertDialog(
      title: const Text('Select Period'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _selectedYear,
            decoration: const InputDecoration(
              labelText: 'Year',
              border: OutlineInputBorder(),
            ),
            items: List.generate(5, (index) {
              final year = currentYear - index;
              return DropdownMenuItem(
                value: year,
                child: Text('$year'),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedYear = value);
              }
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _selectedMonth,
            decoration: const InputDecoration(
              labelText: 'Month',
              border: OutlineInputBorder(),
            ),
            items: List.generate(12, (index) {
              final month = index + 1;
              return DropdownMenuItem(
                value: month,
                child: Text('$month'),
              );
            }),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedMonth = value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'year': _selectedYear,
              'month': _selectedMonth,
            });
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../domain/services/attendance_service.dart';

/// 근태 기록 화면
class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends ConsumerState<AttendanceHistoryScreen> {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

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
    final employee = ref.watch(currentEmployeeProvider);
    final attendanceDao = ref.watch(attendanceDaoProvider);

    if (employee == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
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
      ),
      body: FutureBuilder<List<AttendanceLog>>(
        future: attendanceDao.getAttendanceByMonth(
          employee.id,
          _selectedYear,
          _selectedMonth,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('An error occurred: ${snapshot.error}'),
            );
          }

          final logs = snapshot.data ?? [];

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No attendance records',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _buildAttendanceCard(log);
            },
          );
        },
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceLog log) {
    final isAbsent = log.status == 'absent';
    final isWorking = log.status == 'working';
    final isCompleted = log.status == 'completed';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isAbsent) {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Absent';
    } else if (isWorking) {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
      statusText = 'Working';
    } else if (isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Completed';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.help_outline;
      statusText = log.status;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDetailDialog(log),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 및 상태
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
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
                ],
              ),

              if (!isAbsent) ...[
                const Divider(height: 24),

                // 출근/퇴근 시간
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeInfo(
                        'Check-in',
                        DateFormat('HH:mm').format(log.checkInTime),
                        log.isLate,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimeInfo(
                        'Check-out',
                        log.checkOutTime != null
                            ? DateFormat('HH:mm').format(log.checkOutTime!)
                            : '-',
                        log.isEarlyLeave,
                      ),
                    ),
                  ],
                ),

                if (isCompleted && log.totalMinutes != null) ...[
                  const SizedBox(height: 12),
                  _buildWorkTimeInfo(log),
                ],
              ],

              // 메모
              if (log.checkInNote != null && log.checkInNote!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          log.checkInNote!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, bool hasWarning) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              time,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasWarning) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label == 'Check-in' ? 'Late' : 'Early',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildWorkTimeInfo(AttendanceLog log) {
    final totalHours = (log.totalMinutes ?? 0) ~/ 60;
    final totalMinutes = (log.totalMinutes ?? 0) % 60;
    final overtimeHours = (log.overtimeMinutes ?? 0) ~/ 60;
    final overtimeMinutes = (log.overtimeMinutes ?? 0) % 60;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Work',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalHours}h ${totalMinutes}m',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          if ((log.overtimeMinutes ?? 0) > 0)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overtime',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${overtimeHours}h ${overtimeMinutes}m',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showDetailDialog(AttendanceLog log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          DateFormat('dd/MM/yyyy (E)', 'vi').format(log.workDate),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Status', _getStatusText(log.status)),
              _buildDetailRow(
                'Check-in',
                DateFormat('HH:mm:ss').format(log.checkInTime),
              ),
              if (log.checkOutTime != null)
                _buildDetailRow(
                  'Check-out',
                  DateFormat('HH:mm:ss').format(log.checkOutTime!),
                ),
              if (log.totalMinutes != null)
                _buildDetailRow(
                  'Total Work',
                  '${(log.totalMinutes! ~/ 60)}h ${(log.totalMinutes! % 60)}m',
                ),
              if (log.overtimeMinutes != null && log.overtimeMinutes! > 0)
                _buildDetailRow(
                  'Overtime',
                  '${(log.overtimeMinutes! ~/ 60)}h ${(log.overtimeMinutes! % 60)}m',
                ),
              if (log.nightMinutes != null && log.nightMinutes! > 0)
                _buildDetailRow(
                  'Night Work',
                  '${(log.nightMinutes! ~/ 60)}h ${(log.nightMinutes! % 60)}m',
                ),
              if (log.isLate) _buildDetailRow('Late', 'Yes', isWarning: true),
              if (log.isEarlyLeave)
                _buildDetailRow('Early Leave', 'Yes', isWarning: true),
              if (log.checkInNote != null && log.checkInNote!.isNotEmpty)
                _buildDetailRow('Note', log.checkInNote!),
              if (log.location != null && log.location!.isNotEmpty)
                _buildDetailRow('Location', log.location!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isWarning ? Colors.red : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'working':
        return 'Working';
      case 'completed':
        return 'Completed';
      case 'absent':
        return 'Absent';
      case 'late':
        return 'Late';
      case 'early_leave':
        return 'Early Leave';
      default:
        return status;
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
          // 연도 선택
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

          // 월 선택
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
                child: Text('Month $month'),
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

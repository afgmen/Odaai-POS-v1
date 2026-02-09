import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../domain/services/attendance_service.dart';

/// 체크인/체크아웃 화면
class AttendanceCheckScreen extends ConsumerStatefulWidget {
  const AttendanceCheckScreen({super.key});

  @override
  ConsumerState<AttendanceCheckScreen> createState() =>
      _AttendanceCheckScreenState();
}

class _AttendanceCheckScreenState
    extends ConsumerState<AttendanceCheckScreen> {
  final _noteController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    final employee = ref.read(currentEmployeeProvider);
    if (employee == null) {
      _showErrorDialog('로그인 정보를 찾을 수 없습니다.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final service = ref.read(attendanceServiceProvider);
      final result = await service.checkIn(
        employeeId: employee.id,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        location: '본사', // TODO: GPS 위치 연동
      );

      if (!mounted) return;

      if (result.success) {
        _noteController.clear();
        _showSuccessDialog(
          result.isLate ? '지각 처리되었습니다' : '출근 처리되었습니다',
          result.message ?? '',
        );
        setState(() {}); // 상태 갱신
      } else {
        _showErrorDialog(result.message ?? '출근 처리에 실패했습니다.');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleCheckOut() async {
    final employee = ref.read(currentEmployeeProvider);
    if (employee == null) {
      _showErrorDialog('로그인 정보를 찾을 수 없습니다.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final service = ref.read(attendanceServiceProvider);
      final result = await service.checkOut(
        employeeId: employee.id,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (!mounted) return;

      if (result.success) {
        _noteController.clear();
        final hours = (result.totalMinutes ?? 0) ~/ 60;
        final minutes = (result.totalMinutes ?? 0) % 60;
        _showSuccessDialog(
          result.isEarlyLeave ? '조퇴 처리되었습니다' : '퇴근 처리되었습니다',
          '총 근무 시간: ${hours}시간 ${minutes}분',
        );
        setState(() {}); // 상태 갱신
      } else {
        _showErrorDialog(result.message ?? '퇴근 처리에 실패했습니다.');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('알림'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employee = ref.watch(currentEmployeeProvider);
    final attendanceService = ref.watch(attendanceServiceProvider);
    final attendanceDao = ref.watch(attendanceDaoProvider);

    if (employee == null) {
      return const Scaffold(
        body: Center(
          child: Text('로그인이 필요합니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('출퇴근 관리'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 직원 정보 카드
            _buildEmployeeCard(employee),
            const SizedBox(height: 24),

            // 현재 시간
            _buildCurrentTimeCard(),
            const SizedBox(height: 24),

            // 오늘의 출근 상태
            FutureBuilder(
              future: attendanceDao.getTodayAttendance(employee.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final todayLog = snapshot.data;
                final isCheckedIn = todayLog != null;
                final isWorking = todayLog?.status == 'working';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 오늘의 스케줄
                    FutureBuilder(
                      future: attendanceDao.getScheduleForDate(
                        employee.id,
                        DateTime.now(),
                      ),
                      builder: (context, scheduleSnapshot) {
                        final schedule = scheduleSnapshot.data;
                        return _buildScheduleCard(schedule);
                      },
                    ),
                    const SizedBox(height: 24),

                    // 현재 상태 표시
                    _buildStatusCard(todayLog, isCheckedIn, isWorking),
                    const SizedBox(height: 24),

                    // 메모 입력
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: '메모 (선택)',
                        hintText: '출퇴근 메모를 입력하세요',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 2,
                      enabled: !_isProcessing,
                    ),
                    const SizedBox(height: 24),

                    // 체크인/체크아웃 버튼
                    _isProcessing
                        ? const Center(child: CircularProgressIndicator())
                        : isWorking
                            ? _buildCheckOutButton()
                            : _buildCheckInButton(isCheckedIn),

                    const SizedBox(height: 24),

                    // 이번 달 통계
                    _buildMonthlyStats(employee.id, attendanceService),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(employee) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primary,
              child: Text(
                employee.name[0],
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
                    '${employee.name}님',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    employee.role == 'admin'
                        ? '관리자'
                        : employee.role == 'manager'
                            ? '매니저'
                            : '직원',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTimeCard() {
    return Card(
      color: AppTheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '현재 시각',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, snapshot) {
                return Text(
                  DateFormat('HH:mm:ss').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                );
              },
            ),
            Text(
              DateFormat('yyyy년 MM월 dd일 (E)', 'ko').format(DateTime.now()),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(schedule) {
    if (schedule == null || schedule.shiftType == 'off') {
      return Card(
        color: Colors.orange[50],
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.event_busy, color: Colors.orange),
              SizedBox(width: 12),
              Text(
                '오늘은 휴무일입니다',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: AppTheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘의 근무 시간',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${schedule.startTime} ~ ${schedule.endTime}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(todayLog, bool isCheckedIn, bool isWorking) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String? detailText;

    if (!isCheckedIn) {
      statusColor = Colors.grey;
      statusIcon = Icons.pending;
      statusText = '출근 전';
      detailText = null;
    } else if (isWorking) {
      statusColor = Colors.green;
      statusIcon = Icons.work;
      statusText = '근무 중';
      final checkInTime = DateFormat('HH:mm').format(todayLog.checkInTime);
      detailText = '출근 시간: $checkInTime';
      if (todayLog.isLate) {
        detailText += ' (지각)';
      }
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.check_circle;
      statusText = '퇴근 완료';
      final checkOutTime = DateFormat('HH:mm').format(todayLog.checkOutTime);
      final hours = (todayLog.totalMinutes ?? 0) ~/ 60;
      final minutes = (todayLog.totalMinutes ?? 0) % 60;
      detailText = '퇴근 시간: $checkOutTime\n총 근무: ${hours}시간 ${minutes}분';
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(statusIcon, size: 48, color: statusColor),
            const SizedBox(height: 12),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            if (detailText != null) ...[
              const SizedBox(height: 8),
              Text(
                detailText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInButton(bool isCheckedIn) {
    return ElevatedButton(
      onPressed: isCheckedIn ? null : _handleCheckIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        disabledBackgroundColor: Colors.grey[300],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 28),
          SizedBox(width: 12),
          Text(
            '출근하기',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckOutButton() {
    return ElevatedButton(
      onPressed: _handleCheckOut,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout, size: 28),
          SizedBox(width: 12),
          Text(
            '퇴근하기',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStats(int employeeId, AttendanceService service) {
    final now = DateTime.now();
    return FutureBuilder(
      future: service.getMonthlyReport(employeeId, now.year, now.month),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final report = snapshot.data!;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이번 달 근무 통계 (${now.month}월)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),
                _buildStatRow('총 근무', report.formattedTotalWorkTime),
                _buildStatRow('연장 근무', report.formattedOvertimeWorkTime),
                _buildStatRow('출근 일수',
                    '${report.actualWorkDays}일 / ${report.totalWorkDays}일'),
                _buildStatRow('지각', '${report.lateDays}회', isWarning: true),
                _buildStatRow('조퇴', '${report.earlyLeaveDays}회',
                    isWarning: true),
                _buildStatRow('결근', '${report.absentDays}일',
                    isWarning: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isWarning && value != '0회' && value != '0일'
                  ? Colors.red
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

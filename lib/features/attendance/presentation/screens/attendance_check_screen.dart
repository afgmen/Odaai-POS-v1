import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../settings/providers/store_settings_provider.dart';
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
  String _currentLocation = '';
  double? _latitude;
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _locationLoading = true);

    try {
      final settings = ref.read(storeSettingsProvider);
      final storeName =
          settings[StoreSettingsKeys.storeName] as String? ?? 'Oda POS';

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = storeName;
          _locationLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = storeName;
            _locationLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = storeName;
          _locationLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _currentLocation =
              '$storeName (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
          _locationLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        final settings = ref.read(storeSettingsProvider);
        final storeName =
            settings[StoreSettingsKeys.storeName] as String? ?? 'Oda POS';
        setState(() {
          _currentLocation = storeName;
          _locationLoading = false;
        });
      }
    }
  }

  Future<void> _handleCheckIn() async {
    final employee = ref.read(currentEmployeeProvider);
    if (employee == null) {
      _showErrorDialog('Login information not found.');
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
        location: _currentLocation.isNotEmpty ? _currentLocation : 'Unknown',
      );

      if (!mounted) return;

      if (result.success) {
        _noteController.clear();
        _showSuccessDialog(
          result.isLate ? 'Checked In Late' : 'Checked In',
          result.message ?? '',
        );
        setState(() {});
      } else {
        _showErrorDialog(result.message ?? 'Check-in failed.');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleCheckOut() async {
    final employee = ref.read(currentEmployeeProvider);
    if (employee == null) {
      _showErrorDialog('Login information not found.');
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
          result.isEarlyLeave ? 'Early Check-Out' : 'Checked Out',
          'Total work time: ${hours}h ${minutes}m',
        );
        setState(() {});
      } else {
        _showErrorDialog(result.message ?? 'Check-out failed.');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('An error occurred: $e');
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
            child: const Text('OK'),
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
            const Text('Notice'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
          child: Text('Please log in.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 직원 정보 카드
            _buildEmployeeCard(employee),
            const SizedBox(height: 12),

            // 위치 정보
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: _latitude != null ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _locationLoading
                          ? const Row(
                              children: [
                                SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                                SizedBox(width: 8),
                                Text('Getting location...',
                                    style: TextStyle(fontSize: 13)),
                              ],
                            )
                          : Text(
                              _currentLocation,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                    ),
                    if (!_locationLoading)
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        onPressed: _fetchLocation,
                        tooltip: 'Refresh location',
                      ),
                  ],
                ),
              ),
            ),
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
                        labelText: 'Note (optional)',
                        hintText: 'Enter a note for check-in/out',
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

  Widget _buildEmployeeCard(Employee employee) {
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
                    employee.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    employee.role == 'admin'
                        ? 'Admin'
                        : employee.role == 'manager'
                            ? 'Manager'
                            : 'Staff',
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
      color: AppTheme.primary.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Current Time',
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
              DateFormat('dd/MM/yyyy (E)', 'vi').format(DateTime.now()),
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

  Widget _buildScheduleCard(WorkSchedule? schedule) {
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
                'Today is a day off',
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
                  "Today's Work Hours",
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

  Widget _buildStatusCard(AttendanceLog? todayLog, bool isCheckedIn, bool isWorking) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String? detailText;

    if (!isCheckedIn) {
      statusColor = Colors.grey;
      statusIcon = Icons.pending;
      statusText = 'Not Checked In';
      detailText = null;
    } else if (isWorking) {
      statusColor = Colors.green;
      statusIcon = Icons.work;
      statusText = 'Working';
      final checkInTime = DateFormat('HH:mm').format(todayLog!.checkInTime);
      detailText = 'Check-in: $checkInTime';
      if (todayLog.isLate) {
        detailText += ' (Late)';
      }
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.check_circle;
      statusText = 'Checked Out';
      final checkOutTime = DateFormat('HH:mm').format(todayLog!.checkOutTime!);
      final hours = (todayLog.totalMinutes ?? 0) ~/ 60;
      final minutes = (todayLog.totalMinutes ?? 0) % 60;
      detailText = 'Check-out: $checkOutTime\nTotal: ${hours}h ${minutes}m';
    }

    return Card(
      color: statusColor.withValues(alpha: 0.1),
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
            'Check In',
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
            'Check Out',
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
                  'This Month\'s Stats (Month ${now.month})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),
                _buildStatRow('Total Work', report.formattedTotalWorkTime),
                _buildStatRow('Overtime', report.formattedOvertimeWorkTime),
                _buildStatRow('Work Days',
                    '${report.actualWorkDays} / ${report.totalWorkDays} days'),
                _buildStatRow('Late', '${report.lateDays}x', isWarning: true),
                _buildStatRow('Early Leave', '${report.earlyLeaveDays}x',
                    isWarning: true),
                _buildStatRow('Absent', '${report.absentDays} days',
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
              color: isWarning && value != '0x' && value != '0 days'
                  ? Colors.red
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

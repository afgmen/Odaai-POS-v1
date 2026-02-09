import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../data/attendance_dao.dart';
import '../../domain/services/attendance_service.dart';

/// 휴가 승인 화면
class LeaveApprovalScreen extends ConsumerWidget {
  const LeaveApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceDao = ref.watch(attendanceDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('휴가 승인 관리'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<LeaveRequest>>(
        future: attendanceDao.getPendingLeaveRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('오류가 발생했습니다: ${snapshot.error}'),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '승인 대기 중인 휴가가 없습니다',
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
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _LeaveRequestCard(request: requests[index]);
            },
          );
        },
      ),
    );
  }
}

/// 휴가 신청 카드 (승인/거절 기능 포함)
class _LeaveRequestCard extends ConsumerStatefulWidget {
  final LeaveRequest request;

  const _LeaveRequestCard({required this.request});

  @override
  ConsumerState<_LeaveRequestCard> createState() => _LeaveRequestCardState();
}

class _LeaveRequestCardState extends ConsumerState<_LeaveRequestCard> {
  bool _isProcessing = false;

  Future<void> _handleApprove() async {
    final employee = ref.read(currentEmployeeProvider);
    if (employee == null) return;

    final confirm = await _showConfirmDialog(
      title: '휴가 승인',
      content: '이 휴가 신청을 승인하시겠습니까?\n승인 시 휴가 잔여일이 차감됩니다.',
      confirmText: '승인',
      confirmColor: Colors.green,
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final service = ref.read(attendanceServiceProvider);
      final success = await service.approveLeave(
        requestId: widget.request.id,
        approverId: employee.id,
      );

      if (!mounted) return;

      if (success) {
        _showSuccessSnackBar('휴가가 승인되었습니다');
      } else {
        _showErrorSnackBar('휴가 승인에 실패했습니다');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleReject() async {
    final employee = ref.read(currentEmployeeProvider);
    if (employee == null) return;

    final noteController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('휴가 거절'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('이 휴가 신청을 거절하시겠습니까?'),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: '거절 사유 (선택)',
                hintText: '거절 사유를 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('거절'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final service = ref.read(attendanceServiceProvider);
      final success = await service.rejectLeave(
        requestId: widget.request.id,
        approverId: employee.id,
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        _showSuccessSnackBar('휴가가 거절되었습니다');
      } else {
        _showErrorSnackBar('휴가 거절에 실패했습니다');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceDao = ref.watch(attendanceDaoProvider);

    return FutureBuilder<Employee?>(
      future: attendanceDao.attachedDatabase.employeesDao
          .getEmployee(widget.request.employeeId),
      builder: (context, employeeSnapshot) {
        final employee = employeeSnapshot.data;
        final employeeName = employee?.name ?? '직원 ${widget.request.employeeId}';

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 직원 정보
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.primary,
                      child: Text(
                        employeeName[0],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getLeaveTypeName(widget.request.leaveType),
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
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pending, size: 14, color: Colors.orange),
                          SizedBox(width: 4),
                          Text(
                            '승인 대기',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // 휴가 기간
                Row(
                  children: [
                    const Icon(Icons.calendar_month,
                        size: 20, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${DateFormat('yyyy-MM-dd (E)', 'ko').format(widget.request.startDate)} ~ '
                        '${DateFormat('yyyy-MM-dd (E)', 'ko').format(widget.request.endDate)}',
                      ),
                    ),
                    Text(
                      '${widget.request.days.toStringAsFixed(1)}일',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 신청 사유
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.description,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.request.reason,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 신청 일시
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '신청일: ${DateFormat('yyyy-MM-dd HH:mm').format(widget.request.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

                // 휴가 잔여 확인
                const SizedBox(height: 12),
                FutureBuilder<LeaveBalance?>(
                  future: attendanceDao.getLeaveBalance(
                    widget.request.employeeId,
                    DateTime.now().year,
                  ),
                  builder: (context, balanceSnapshot) {
                    final balance = balanceSnapshot.data;
                    if (balance == null) {
                      return const SizedBox.shrink();
                    }

                    double remaining;
                    switch (widget.request.leaveType) {
                      case 'annual':
                        remaining = balance.annualRemaining;
                        break;
                      case 'sick':
                        remaining = balance.sickRemaining;
                        break;
                      case 'personal':
                        remaining = balance.personalRemaining;
                        break;
                      default:
                        remaining = 0;
                    }

                    final hasEnough = remaining >= widget.request.days;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hasEnough
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasEnough
                              ? Colors.green[300]!
                              : Colors.red[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hasEnough ? Icons.check_circle : Icons.warning,
                            size: 16,
                            color: hasEnough ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '잔여 휴가: ${remaining.toStringAsFixed(1)}일 '
                              '${hasEnough ? '' : '(부족!)'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: hasEnough
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const Divider(height: 24),

                // 승인/거절 버튼
                _isProcessing
                    ? const Center(child: CircularProgressIndicator())
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _handleReject,
                              icon: const Icon(Icons.cancel),
                              label: const Text('거절'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _handleApprove,
                              icon: const Icon(Icons.check_circle),
                              label: const Text('승인'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getLeaveTypeName(String type) {
    switch (type) {
      case 'annual':
        return '연차';
      case 'sick':
        return '병가';
      case 'personal':
        return '개인 사유';
      case 'maternity':
        return '출산 휴가';
      case 'paternity':
        return '육아 휴가';
      case 'unpaid':
        return '무급 휴가';
      default:
        return type;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../database/tables/permission_logs.dart';
import '../../providers/audit_logging_provider.dart';
import '../../providers/permission_provider.dart';

/// 감사 로그 조회 화면 (관리자 전용)
class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    // 관리자 권한 확인
    final isManager = ref.watch(isManagerProvider);

    if (!isManager) {
      return Scaffold(
        appBar: AppBar(title: const Text('감사 로그')),
        body: const Center(
          child: Text('관리자 권한이 필요합니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('감사 로그'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '최근 활동'),
            Tab(text: '오늘 로그인'),
            Tab(text: '권한 거부'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecentActivityTab(),
          _buildTodayLoginsTab(),
          _buildDeniedLogsTab(),
        ],
      ),
    );
  }

  Widget _buildRecentActivityTab() {
    final recentActivityAsync = ref.watch(recentActivityProvider);

    return recentActivityAsync.when(
      data: (logs) => _buildLogList(logs),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('로드 실패: $error')),
    );
  }

  Widget _buildTodayLoginsTab() {
    final todayLoginsAsync = ref.watch(todayLoginsProvider);

    return todayLoginsAsync.when(
      data: (logs) => _buildLogList(logs),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('로드 실패: $error')),
    );
  }

  Widget _buildDeniedLogsTab() {
    final deniedLogsAsync = ref.watch(deniedLogsProvider);

    return deniedLogsAsync.when(
      data: (logs) => _buildLogList(logs),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('로드 실패: $error')),
    );
  }

  Widget _buildLogList(List<PermissionLog> logs) {
    if (logs.isEmpty) {
      return const Center(
        child: Text('로그가 없습니다.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogCard(log);
      },
    );
  }

  Widget _buildLogCard(PermissionLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _buildLogIcon(log),
        title: Text(
          _getActionTypeDisplay(log.actionType),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('직원 ID: ${log.employeeId}'),
            if (log.actionTarget != null)
              Text('대상: ${log.actionTarget}'),
            if (log.approvedByEmployeeId != null)
              Text('승인자: ${log.approvedByEmployeeId}'),
            Text(
              DateFormat('yyyy-MM-dd HH:mm:ss').format(log.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: log.permissionGranted
            ? Icon(Icons.check_circle, color: Colors.green.shade600)
            : Icon(Icons.cancel, color: Colors.red.shade600),
      ),
    );
  }

  Widget _buildLogIcon(PermissionLog log) {
    IconData icon;
    Color color;

    switch (log.actionType) {
      case 'LOGIN':
        icon = Icons.login;
        color = Colors.blue;
        break;
      case 'LOGOUT':
        icon = Icons.logout;
        color = Colors.grey;
        break;
      case 'REFUND':
        icon = Icons.receipt_long;
        color = Colors.orange;
        break;
      case 'DISCOUNT':
        icon = Icons.discount;
        color = Colors.purple;
        break;
      case 'OVERRIDE_REQUEST':
        icon = Icons.admin_panel_settings;
        color = Colors.amber;
        break;
      case 'OVERRIDE_GRANTED':
        icon = Icons.verified;
        color = Colors.green;
        break;
      case 'PERMISSION_DENIED':
        icon = Icons.block;
        color = Colors.red;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _getActionTypeDisplay(String actionType) {
    switch (actionType) {
      case 'LOGIN':
        return '로그인';
      case 'LOGOUT':
        return '로그아웃';
      case 'REFUND':
        return '환불';
      case 'DISCOUNT':
        return '할인';
      case 'OVERRIDE_REQUEST':
        return '관리자 승인 요청';
      case 'OVERRIDE_GRANTED':
        return '관리자 승인 완료';
      case 'PERMISSION_DENIED':
        return '권한 거부';
      default:
        return actionType;
    }
  }
}

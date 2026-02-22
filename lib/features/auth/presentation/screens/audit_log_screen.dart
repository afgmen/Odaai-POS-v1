import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../database/app_database.dart';
import '../../providers/audit_logging_provider.dart';
import '../../providers/permission_provider.dart';

/// Audit log screen (manager only)
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
    final isManager = ref.watch(isManagerProvider);

    if (!isManager) {
      return Scaffold(
        appBar: AppBar(title: const Text('Audit Log')),
        body: const Center(
          child: Text('Manager access required.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Recent Activity'),
            Tab(text: 'Today\'s Logins'),
            Tab(text: 'Permission Denied'),
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
      error: (error, stack) => Center(child: Text('Failed to load: $error')),
    );
  }

  Widget _buildTodayLoginsTab() {
    final todayLoginsAsync = ref.watch(todayLoginsProvider);

    return todayLoginsAsync.when(
      data: (logs) => _buildLogList(logs),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Failed to load: $error')),
    );
  }

  Widget _buildDeniedLogsTab() {
    final deniedLogsAsync = ref.watch(deniedLogsProvider);

    return deniedLogsAsync.when(
      data: (logs) => _buildLogList(logs),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Failed to load: $error')),
    );
  }

  Widget _buildLogList(List<PermissionLog> logs) {
    if (logs.isEmpty) {
      return const Center(
        child: Text('No logs found.'),
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
            Text('Employee ID: ${log.employeeId}'),
            if (log.actionTarget != null)
              Text('Target: ${log.actionTarget}'),
            if (log.approvedByEmployeeId != null)
              Text('Approved by: ${log.approvedByEmployeeId}'),
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
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _getActionTypeDisplay(String actionType) {
    switch (actionType) {
      case 'LOGIN':
        return 'Login';
      case 'LOGOUT':
        return 'Logout';
      case 'REFUND':
        return 'Refund';
      case 'DISCOUNT':
        return 'Discount';
      case 'OVERRIDE_REQUEST':
        return 'Manager Override Request';
      case 'OVERRIDE_GRANTED':
        return 'Manager Override Approved';
      case 'PERMISSION_DENIED':
        return 'Permission Denied';
      default:
        return actionType;
    }
  }
}

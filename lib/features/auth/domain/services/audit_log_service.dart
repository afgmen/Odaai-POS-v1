import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../database/app_database.dart';

/// Audit event types for permission changes
class AuditEventType {
  static const String ROLE_PERMISSION_UPDATED = 'ROLE_PERMISSION_UPDATED';
  static const String ROLE_PERMISSIONS_RESET = 'ROLE_PERMISSIONS_RESET';
  static const String USER_ROLE_ASSIGNED = 'USER_ROLE_ASSIGNED';
  static const String USER_ROLE_CHANGED = 'USER_ROLE_CHANGED';
  static const String STORE_ASSIGNMENT_ADDED = 'STORE_ASSIGNMENT_ADDED';
  static const String STORE_ASSIGNMENT_REMOVED = 'STORE_ASSIGNMENT_REMOVED';
  static const String RBAC_SYSTEM_ENABLED = 'RBAC_SYSTEM_ENABLED';
  static const String RBAC_SYSTEM_DISABLED = 'RBAC_SYSTEM_DISABLED';
}

/// Service for recording audit logs
/// Tracks all permission changes with actor, timestamp, and details
class AuditLogService {
  final AppDatabase _db;

  AuditLogService(this._db);

  /// Log permission change
  ///
  /// [eventType] - Type of event (e.g., ROLE_PERMISSION_UPDATED)
  /// [actorId] - Employee ID who performed the action
  /// [actorName] - Denormalized actor name for history (e.g., "John Doe (OWNER)")
  /// [targetRole] - Role being modified (optional)
  /// [permission] - Permission being changed (optional)
  /// [oldValue] - Previous value (optional)
  /// [newValue] - New value (optional)
  /// [ipAddress] - IP address of the actor (optional)
  Future<void> logPermissionChange({
    required String eventType,
    required int actorId,
    required String actorName,
    String? targetRole,
    String? permission,
    String? oldValue,
    String? newValue,
    String? ipAddress,
  }) async {
    try {
      await _db.customInsert(
        '''
        INSERT INTO audit_logs (
          id, event_type, actor_id, actor_name, target_role,
          permission, old_value, new_value, timestamp, ip_address
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        variables: [
          Variable.withString(const Uuid().v4()),
          Variable.withString(eventType),
          Variable.withInt(actorId),
          Variable.withString(actorName),
          targetRole != null ? Variable.withString(targetRole) : const Variable.withNull(),
          permission != null ? Variable.withString(permission) : const Variable.withNull(),
          oldValue != null ? Variable.withString(oldValue) : const Variable.withNull(),
          newValue != null ? Variable.withString(newValue) : const Variable.withNull(),
          Variable.withDateTime(DateTime.now()),
          ipAddress != null ? Variable.withString(ipAddress) : const Variable.withNull(),
        ],
      );
    } catch (e) {
      // Log insertion failed - this shouldn't break the main operation
      print('Audit log insertion failed: $e');
    }
  }

  /// Get audit logs with pagination and filters
  ///
  /// [limit] - Maximum number of logs to return (default: 100)
  /// [offset] - Number of logs to skip (for pagination)
  /// [eventTypeFilter] - Filter by specific event type
  /// [actorId] - Filter by specific actor
  /// [targetRole] - Filter by specific target role
  /// [startDate] - Filter logs after this date
  /// [endDate] - Filter logs before this date
  Future<List<AuditLog>> getAuditLogs({
    int limit = 100,
    int offset = 0,
    String? eventTypeFilter,
    int? actorId,
    String? targetRole,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = '''
      SELECT * FROM audit_logs
      WHERE 1=1
    ''';

    final variables = <Variable>[];

    if (eventTypeFilter != null) {
      query += ' AND event_type = ?';
      variables.add(Variable.withString(eventTypeFilter));
    }

    if (actorId != null) {
      query += ' AND actor_id = ?';
      variables.add(Variable.withInt(actorId));
    }

    if (targetRole != null) {
      query += ' AND target_role = ?';
      variables.add(Variable.withString(targetRole));
    }

    if (startDate != null) {
      query += ' AND timestamp >= ?';
      variables.add(Variable.withDateTime(startDate));
    }

    if (endDate != null) {
      query += ' AND timestamp <= ?';
      variables.add(Variable.withDateTime(endDate));
    }

    query += ' ORDER BY timestamp DESC LIMIT ? OFFSET ?';
    variables.add(Variable.withInt(limit));
    variables.add(Variable.withInt(offset));

    final result = await _db.customSelect(
      query,
      variables: variables,
    ).get();

    return result.map((row) => _mapToAuditLog(row)).toList();
  }

  /// Get recent audit logs (last 50)
  Future<List<AuditLog>> getRecentLogs({int limit = 50}) async {
    return await getAuditLogs(limit: limit);
  }

  /// Get audit logs for a specific role
  Future<List<AuditLog>> getLogsForRole(String role, {int limit = 100}) async {
    return await getAuditLogs(targetRole: role, limit: limit);
  }

  /// Get audit logs by actor (who made the changes)
  Future<List<AuditLog>> getLogsByActor(int actorId, {int limit = 100}) async {
    return await getAuditLogs(actorId: actorId, limit: limit);
  }

  /// Get audit logs for a date range
  Future<List<AuditLog>> getLogsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) async {
    return await getAuditLogs(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  /// Get count of audit logs with filters
  Future<int> getAuditLogCount({
    String? eventTypeFilter,
    int? actorId,
    String? targetRole,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = '''
      SELECT COUNT(*) as count FROM audit_logs
      WHERE 1=1
    ''';

    final variables = <Variable>[];

    if (eventTypeFilter != null) {
      query += ' AND event_type = ?';
      variables.add(Variable.withString(eventTypeFilter));
    }

    if (actorId != null) {
      query += ' AND actor_id = ?';
      variables.add(Variable.withInt(actorId));
    }

    if (targetRole != null) {
      query += ' AND target_role = ?';
      variables.add(Variable.withString(targetRole));
    }

    if (startDate != null) {
      query += ' AND timestamp >= ?';
      variables.add(Variable.withDateTime(startDate));
    }

    if (endDate != null) {
      query += ' AND timestamp <= ?';
      variables.add(Variable.withDateTime(endDate));
    }

    final result = await _db.customSelect(query, variables: variables).getSingle();
    return result.data['count'] as int;
  }

  /// Export audit logs to CSV format (as string)
  Future<String> exportToCSV({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final logs = await getAuditLogs(
      startDate: startDate,
      endDate: endDate,
      limit: 10000, // Large limit for export
    );

    final buffer = StringBuffer();
    // CSV header
    buffer.writeln('Timestamp,Event Type,Actor,Target Role,Permission,Old Value,New Value');

    // CSV rows
    for (final log in logs) {
      buffer.writeln([
        log.timestamp.toIso8601String(),
        log.eventType,
        _escapeCsv(log.actorName),
        log.targetRole ?? '',
        log.permission ?? '',
        log.oldValue ?? '',
        log.newValue ?? '',
      ].join(','));
    }

    return buffer.toString();
  }

  /// Helper to escape CSV values
  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Map database row to AuditLog object
  AuditLog _mapToAuditLog(QueryRow row) {
    return AuditLog(
      id: row.data['id'] as String,
      eventType: row.data['event_type'] as String,
      actorId: row.data['actor_id'] as int,
      actorName: row.data['actor_name'] as String,
      targetRole: row.data['target_role'] as String?,
      permission: row.data['permission'] as String?,
      oldValue: row.data['old_value'] as String?,
      newValue: row.data['new_value'] as String?,
      timestamp: row.data['timestamp'] as DateTime,
      ipAddress: row.data['ip_address'] as String?,
    );
  }
}

/// Audit log data class
class AuditLog {
  final String id;
  final String eventType;
  final int actorId;
  final String actorName;
  final String? targetRole;
  final String? permission;
  final String? oldValue;
  final String? newValue;
  final DateTime timestamp;
  final String? ipAddress;

  AuditLog({
    required this.id,
    required this.eventType,
    required this.actorId,
    required this.actorName,
    this.targetRole,
    this.permission,
    this.oldValue,
    this.newValue,
    required this.timestamp,
    this.ipAddress,
  });
}

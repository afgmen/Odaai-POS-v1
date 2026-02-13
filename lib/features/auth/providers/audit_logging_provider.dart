import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/permission_logs.dart';
import '../../../providers/database_providers.dart';
import '../data/permission_logs_dao.dart';

/// 감사 로거
class AuditLogger {
  final PermissionLogsDao _logsDao;

  AuditLogger(this._logsDao);

  /// 로그인 기록
  ///
  /// [employeeId] 직원 ID
  /// [success] 성공 여부
  /// [errorCode] 에러 코드 (실패 시)
  Future<void> logLogin(
    int employeeId, {
    required bool success,
    String? errorCode,
  }) async {
    final log = PermissionLogsCompanion.insert(
      employeeId: employeeId,
      actionType: 'LOGIN',
      permissionGranted: success,
      metadata: errorCode != null
          ? Value(jsonEncode({'errorCode': errorCode}))
          : const Value.absent(),
    );

    await _logsDao.logAction(log);
  }

  /// 로그아웃 기록
  ///
  /// [employeeId] 직원 ID
  Future<void> logLogout(int employeeId) async {
    final log = PermissionLogsCompanion.insert(
      employeeId: employeeId,
      actionType: 'LOGOUT',
      permissionGranted: true,
    );

    await _logsDao.logAction(log);
  }

  /// 권한 거부 기록
  ///
  /// [employeeId] 직원 ID
  /// [action] 시도한 작업
  /// [requiredPermission] 필요한 권한
  Future<void> logPermissionDenied(
    int employeeId,
    String action,
    String requiredPermission,
  ) async {
    final log = PermissionLogsCompanion.insert(
      employeeId: employeeId,
      actionType: 'PERMISSION_DENIED',
      actionTarget: Value(action),
      permissionGranted: false,
      metadata: Value(jsonEncode({
        'requiredPermission': requiredPermission,
      })),
    );

    await _logsDao.logAction(log);
  }

  /// 관리자 승인 시도 기록
  ///
  /// [employeeId] 직원 ID
  /// [action] 시도한 작업
  /// [success] 승인 성공 여부
  Future<void> logOverrideAttempt(
    int employeeId,
    String action, {
    required bool success,
  }) async {
    final log = PermissionLogsCompanion.insert(
      employeeId: employeeId,
      actionType: 'OVERRIDE_REQUEST',
      actionTarget: Value(action),
      permissionGranted: success,
    );

    await _logsDao.logAction(log);
  }

  /// 관리자 승인 성공 기록
  ///
  /// [employeeId] 요청자 ID
  /// [action] 작업 설명
  /// [permission] 권한 설명
  /// [managerId] 승인자 ID
  Future<void> logOverrideGranted(
    int employeeId,
    String action,
    String permission,
    int? managerId,
  ) async {
    final log = PermissionLogsCompanion.insert(
      employeeId: employeeId,
      actionType: 'OVERRIDE_GRANTED',
      actionTarget: Value(action),
      permissionGranted: true,
      approvedByEmployeeId: Value(managerId),
      metadata: Value(jsonEncode({
        'permission': permission,
      })),
    );

    await _logsDao.logAction(log);
  }

  /// 환불 작업 기록
  ///
  /// [employeeId] 직원 ID
  /// [saleId] 판매 ID
  /// [amount] 환불 금액
  /// [success] 성공 여부
  /// [managerId] 승인자 ID (관리자 승인 시)
  Future<void> logRefund(
    int employeeId,
    int saleId,
    int amount, {
    required bool success,
    int? managerId,
  }) async {
    final log = PermissionLogsCompanion.insert(
      employeeId: employeeId,
      actionType: 'REFUND',
      actionTarget: Value('sale_$saleId'),
      permissionGranted: success,
      approvedByEmployeeId: Value(managerId),
      metadata: Value(jsonEncode({
        'amount': amount,
      })),
    );

    await _logsDao.logAction(log);
  }

  /// 할인 작업 기록
  ///
  /// [employeeId] 직원 ID
  /// [saleId] 판매 ID
  /// [discountAmount] 할인 금액
  /// [managerId] 승인자 ID (관리자 승인 시)
  Future<void> logDiscount(
    int employeeId,
    int saleId,
    int discountAmount, {
    int? managerId,
  }) async {
    final log = PermissionLogsCompanion.insert(
      employeeId: employeeId,
      actionType: 'DISCOUNT',
      actionTarget: Value('sale_$saleId'),
      permissionGranted: true,
      approvedByEmployeeId: Value(managerId),
      metadata: Value(jsonEncode({
        'discountAmount': discountAmount,
      })),
    );

    await _logsDao.logAction(log);
  }

  /// 직원별 로그 조회
  ///
  /// [employeeId] 직원 ID
  /// [limit] 조회 개수
  /// Returns: 로그 목록
  Future<List<PermissionLog>> getLogsByEmployee(
    int employeeId, {
    int limit = 50,
  }) {
    return _logsDao.getLogsByEmployee(employeeId, limit: limit);
  }

  /// 최근 활동 조회 (관리자용)
  ///
  /// [limit] 조회 개수
  /// Returns: 로그 목록
  Future<List<PermissionLog>> getRecentActivity({int limit = 20}) {
    return _logsDao.getRecentActivity(limit: limit);
  }

  /// 실시간 활동 감시 (관리자용)
  ///
  /// [limit] 조회 개수
  /// Returns: 로그 스트림
  Stream<List<PermissionLog>> watchRecentActivity({int limit = 20}) {
    return _logsDao.watchRecentActivity(limit: limit);
  }

  /// 권한 거부 로그 조회 (감사용)
  ///
  /// [limit] 조회 개수
  /// Returns: 로그 목록
  Future<List<PermissionLog>> getDeniedLogs({int limit = 100}) {
    return _logsDao.getDeniedLogs(limit: limit);
  }

  /// 오늘의 로그인 기록 조회
  ///
  /// Returns: 오늘 로그인한 직원 로그
  Future<List<PermissionLog>> getTodayLogins() {
    return _logsDao.getTodayLogins();
  }

  /// 오래된 로그 삭제 (데이터 정리)
  ///
  /// [daysOld] 삭제할 로그의 기준 일수
  /// Returns: 삭제된 로그 개수
  Future<int> deleteOldLogs({int daysOld = 90}) {
    return _logsDao.deleteOldLogs(daysOld: daysOld);
  }
}

// ============================================================
// Providers
// ============================================================

/// PermissionLogsDao Provider
final permissionLogsDaoProvider = Provider<PermissionLogsDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.permissionLogsDao;
});

/// Audit Logging Provider
final auditLoggingProvider = Provider<AuditLogger>((ref) {
  final logsDao = ref.watch(permissionLogsDaoProvider);
  return AuditLogger(logsDao);
});

/// 최근 활동 로그 Provider (실시간 감시)
final recentActivityProvider = StreamProvider.autoDispose<List<PermissionLog>>((ref) {
  final logger = ref.watch(auditLoggingProvider);
  return logger.watchRecentActivity(limit: 20);
});

/// 오늘의 로그인 기록 Provider
final todayLoginsProvider = FutureProvider.autoDispose<List<PermissionLog>>((ref) {
  final logger = ref.watch(auditLoggingProvider);
  return logger.getTodayLogins();
});

/// 권한 거부 로그 Provider (감사용)
final deniedLogsProvider = FutureProvider.autoDispose<List<PermissionLog>>((ref) {
  final logger = ref.watch(auditLoggingProvider);
  return logger.getDeniedLogs(limit: 100);
});

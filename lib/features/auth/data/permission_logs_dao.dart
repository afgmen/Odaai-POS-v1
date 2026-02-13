import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/permission_logs.dart';

part 'permission_logs_dao.g.dart';

@DriftAccessor(tables: [PermissionLogs])
class PermissionLogsDao extends DatabaseAccessor<AppDatabase>
    with _$PermissionLogsDaoMixin {
  PermissionLogsDao(super.db);

  /// 로그 기록
  ///
  /// [log] 로그 데이터
  /// Returns: 생성된 로그 ID
  Future<int> logAction(PermissionLogsCompanion log) {
    return into(permissionLogs).insert(log);
  }

  /// 직원별 로그 조회
  ///
  /// [employeeId] 직원 ID
  /// [limit] 조회 개수 (기본 50개)
  /// Returns: 로그 목록 (최신순)
  Future<List<PermissionLog>> getLogsByEmployee(int employeeId, {int limit = 50}) {
    return (select(permissionLogs)
          ..where((log) => log.employeeId.equals(employeeId))
          ..orderBy([(log) => OrderingTerm.desc(log.createdAt)])
          ..limit(limit))
        .get();
  }

  /// 기간별 로그 조회
  ///
  /// [startDate] 시작 날짜
  /// [endDate] 종료 날짜
  /// Returns: 로그 목록
  Future<List<PermissionLog>> getLogsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return (select(permissionLogs)
          ..where((log) =>
              log.createdAt.isBiggerOrEqualValue(startDate) &
              log.createdAt.isSmallerOrEqualValue(endDate))
          ..orderBy([(log) => OrderingTerm.desc(log.createdAt)]))
        .get();
  }

  /// 작업 타입별 로그 조회
  ///
  /// [actionType] 작업 타입
  /// [limit] 조회 개수
  /// Returns: 로그 목록
  Future<List<PermissionLog>> getLogsByActionType(String actionType, {int limit = 50}) {
    return (select(permissionLogs)
          ..where((log) => log.actionType.equals(actionType))
          ..orderBy([(log) => OrderingTerm.desc(log.createdAt)])
          ..limit(limit))
        .get();
  }

  /// 관리자 승인 요청 로그 조회
  ///
  /// Returns: 승인 요청 로그 목록
  Future<List<PermissionLog>> getOverrideRequests() {
    return (select(permissionLogs)
          ..where((log) =>
              log.actionType.equals('OVERRIDE_REQUEST') |
              log.actionType.equals('OVERRIDE_GRANTED'))
          ..orderBy([(log) => OrderingTerm.desc(log.createdAt)]))
        .get();
  }

  /// 권한 거부된 로그 조회 (감사용)
  ///
  /// [limit] 조회 개수
  /// Returns: 권한 거부 로그 목록
  Future<List<PermissionLog>> getDeniedLogs({int limit = 100}) {
    return (select(permissionLogs)
          ..where((log) => log.permissionGranted.equals(false))
          ..orderBy([(log) => OrderingTerm.desc(log.createdAt)])
          ..limit(limit))
        .get();
  }

  /// 오늘의 로그인 기록 조회
  ///
  /// Returns: 오늘 로그인한 직원 목록
  Future<List<PermissionLog>> getTodayLogins() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(permissionLogs)
          ..where((log) =>
              log.actionType.equals('LOGIN') &
              log.createdAt.isBiggerOrEqualValue(startOfDay) &
              log.createdAt.isSmallerThanValue(endOfDay))
          ..orderBy([(log) => OrderingTerm.desc(log.createdAt)]))
        .get();
  }

  /// 오래된 로그 삭제 (데이터 정리)
  ///
  /// [daysOld] 삭제할 로그의 기준 일수 (기본 90일)
  /// Returns: 삭제된 로그 개수
  Future<int> deleteOldLogs({int daysOld = 90}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    return (delete(permissionLogs)
          ..where((log) => log.createdAt.isSmallerThanValue(cutoffDate)))
        .go();
  }

  /// 특정 직원의 로그 개수 조회
  ///
  /// [employeeId] 직원 ID
  /// Returns: 로그 개수
  Future<int> getLogCountByEmployee(int employeeId) async {
    final countQuery = selectOnly(permissionLogs)
      ..addColumns([permissionLogs.id.count()])
      ..where(permissionLogs.employeeId.equals(employeeId));

    final result = await countQuery.getSingle();
    return result.read(permissionLogs.id.count()) ?? 0;
  }

  /// 최근 활동 로그 조회 (관리자용 대시보드)
  ///
  /// [limit] 조회 개수
  /// Returns: 최근 활동 로그
  Future<List<PermissionLog>> getRecentActivity({int limit = 20}) {
    return (select(permissionLogs)
          ..orderBy([(log) => OrderingTerm.desc(log.createdAt)])
          ..limit(limit))
        .get();
  }

  /// 스트림으로 실시간 로그 감시 (관리자용)
  ///
  /// Returns: 로그 스트림
  Stream<List<PermissionLog>> watchRecentActivity({int limit = 20}) {
    return (select(permissionLogs)
          ..orderBy([(log) => OrderingTerm.desc(log.createdAt)])
          ..limit(limit))
        .watch();
  }
}

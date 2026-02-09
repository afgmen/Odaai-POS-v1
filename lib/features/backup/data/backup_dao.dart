import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/backup_logs.dart';
import '../../../database/tables/backup_settings.dart';

part 'backup_dao.g.dart';

@DriftAccessor(tables: [BackupLogs, BackupSettings])
class BackupDao extends DatabaseAccessor<AppDatabase> with _$BackupDaoMixin {
  BackupDao(super.db);

  // ═══════════════════════════════════════════════════════
  // 백업 로그
  // ═══════════════════════════════════════════════════════

  /// 백업 로그 생성
  Future<int> createBackupLog(BackupLogsCompanion entry) {
    return into(backupLogs).insert(entry);
  }

  /// 백업 로그 업데이트
  Future<bool> updateBackupLog(int id, BackupLogsCompanion updateData) {
    return (update(backupLogs)..where((log) => log.id.equals(id)))
        .write(updateData)
        .then((rows) => rows > 0);
  }

  /// 백업 ID로 조회
  Future<BackupLog?> getBackupById(String backupId) {
    return (select(backupLogs)..where((log) => log.backupId.equals(backupId)))
        .getSingleOrNull();
  }

  /// 최근 백업 이력 조회
  Future<List<BackupLog>> getRecentBackups({int limit = 30}) {
    return (select(backupLogs)
          ..orderBy([(log) => OrderingTerm.desc(log.createdAt)])
          ..limit(limit))
        .get();
  }

  /// 상태별 백업 조회
  Future<List<BackupLog>> getBackupsByStatus(String status) {
    return (select(backupLogs)
          ..where((log) => log.status.equals(status))
          ..orderBy([(log) => OrderingTerm.desc(log.createdAt)]))
        .get();
  }

  /// 완료된 백업 수 조회
  Future<int> getCompletedBackupCount() async {
    final query = selectOnly(backupLogs)
      ..where(backupLogs.status.equals('completed'))
      ..addColumns([backupLogs.id.count()]);

    final result = await query.getSingle();
    return result.read(backupLogs.id.count()) ?? 0;
  }

  /// 백업 삭제
  Future<void> deleteBackup(int id) {
    return (delete(backupLogs)..where((log) => log.id.equals(id))).go();
  }

  /// 오래된 백업 삭제
  Future<void> deleteOldBackups(int keepCount) async {
    final oldBackups = await (select(backupLogs)
          ..orderBy([(log) => OrderingTerm.desc(log.createdAt)])
          ..limit(keepCount, offset: keepCount))
        .get();

    for (final backup in oldBackups) {
      await deleteBackup(backup.id);
    }
  }

  /// 백업 로그 스트림 (실시간)
  Stream<List<BackupLog>> watchBackupLogs({int limit = 30}) {
    return (select(backupLogs)
          ..orderBy([(log) => OrderingTerm.desc(log.createdAt)])
          ..limit(limit))
        .watch();
  }

  /// 마지막 성공한 백업 조회
  Future<BackupLog?> getLastSuccessfulBackup() {
    return (select(backupLogs)
          ..where((log) => log.status.equals('completed'))
          ..orderBy([(log) => OrderingTerm.desc(log.completedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// 백업 타입별 통계
  Future<Map<String, int>> getBackupStatsByType() async {
    final results = await customSelect(
      'SELECT backup_type, COUNT(*) as count FROM backup_logs '
      'WHERE status = ? GROUP BY backup_type',
      variables: [Variable.withString('completed')],
    ).get();

    return {
      for (var row in results)
        row.read<String>('backup_type'): row.read<int>('count')
    };
  }

  // ═══════════════════════════════════════════════════════
  // 백업 설정
  // ═══════════════════════════════════════════════════════

  /// 설정값 조회
  Future<String?> getSetting(String key) async {
    final setting = await (select(backupSettings)
          ..where((s) => s.settingKey.equals(key)))
        .getSingleOrNull();
    return setting?.settingValue;
  }

  /// 설정값 업데이트
  Future<bool> updateSetting(String key, String value) {
    return (update(backupSettings)..where((s) => s.settingKey.equals(key)))
        .write(BackupSettingsCompanion(
      settingValue: Value(value),
      updatedAt: Value(DateTime.now()),
    ))
        .then((rows) => rows > 0);
  }

  /// 모든 설정 조회
  Future<Map<String, String>> getAllSettings() async {
    final settings = await select(backupSettings).get();
    return {for (var s in settings) s.settingKey: s.settingValue};
  }

  /// 카테고리별 설정 조회
  Future<Map<String, String>> getSettingsByCategory(String category) async {
    final settings = await (select(backupSettings)
          ..where((s) => s.category.equals(category)))
        .get();
    return {for (var s in settings) s.settingKey: s.settingValue};
  }

  /// 설정 스트림 (실시간)
  Stream<Map<String, String>> watchSettings() {
    return select(backupSettings).watch().map((settings) {
      return {for (var s in settings) s.settingKey: s.settingValue};
    });
  }

  // ═══════════════════════════════════════════════════════
  // 통계
  // ═══════════════════════════════════════════════════════

  /// 총 백업 크기 계산
  Future<int> getTotalBackupSize() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(file_size), 0) as total FROM backup_logs '
      'WHERE status = ?',
      variables: [Variable.withString('completed')],
    ).getSingle();

    return result.read<int>('total');
  }

  /// 최근 24시간 백업 수
  Future<int> getBackupsInLast24Hours() async {
    final oneDayAgo = DateTime.now().subtract(const Duration(hours: 24));

    final result = await customSelect(
      'SELECT COUNT(*) as count FROM backup_logs '
      'WHERE created_at >= ?',
      variables: [Variable.withInt(oneDayAgo.millisecondsSinceEpoch)],
    ).getSingle();

    return result.read<int>('count');
  }
}

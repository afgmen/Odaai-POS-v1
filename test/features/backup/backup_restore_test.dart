import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';
import 'package:oda_pos/features/backup/data/backup_dao.dart';
import 'package:drift/native.dart';

AppDatabase _openDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase database;
  late BackupDao backupDao;

  setUp(() {
    database = _openDb();
    backupDao = BackupDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('BackupDao Basic Operations', () {
    test('getRecentBackups returns empty list initially', () async {
      final logs = await backupDao.getRecentBackups(limit: 10);
      expect(logs, isEmpty);
    });

    test('getLastSuccessfulBackup returns null initially', () async {
      final last = await backupDao.getLastSuccessfulBackup();
      expect(last, isNull);
    });

    test('getCompletedBackupCount returns 0 initially', () async {
      final count = await backupDao.getCompletedBackupCount();
      expect(count, 0);
    });

    test('getBackupStatsByType returns empty map initially', () async {
      final stats = await backupDao.getBackupStatsByType();
      expect(stats, isEmpty);
    });

    test('getTotalBackupSize returns 0 initially', () async {
      final size = await backupDao.getTotalBackupSize();
      expect(size, 0);
    });

    test('getBackupsInLast24Hours returns 0 initially', () async {
      final count = await backupDao.getBackupsInLast24Hours();
      expect(count, 0);
    });

    test('getBackupById returns null for non-existent id', () async {
      final backup = await backupDao.getBackupById('non-existent-id');
      expect(backup, isNull);
    });

    test('getAllSettings returns empty map initially', () async {
      final settings = await backupDao.getAllSettings();
      expect(settings, isMap);
    });
  });
}

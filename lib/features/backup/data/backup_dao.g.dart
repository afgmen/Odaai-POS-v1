// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_dao.dart';

// ignore_for_file: type=lint
mixin _$BackupDaoMixin on DatabaseAccessor<AppDatabase> {
  $BackupLogsTable get backupLogs => attachedDatabase.backupLogs;
  $BackupSettingsTable get backupSettings => attachedDatabase.backupSettings;
  BackupDaoManager get managers => BackupDaoManager(this);
}

class BackupDaoManager {
  final _$BackupDaoMixin _db;
  BackupDaoManager(this._db);
  $$BackupLogsTableTableManager get backupLogs =>
      $$BackupLogsTableTableManager(_db.attachedDatabase, _db.backupLogs);
  $$BackupSettingsTableTableManager get backupSettings =>
      $$BackupSettingsTableTableManager(
        _db.attachedDatabase,
        _db.backupSettings,
      );
}

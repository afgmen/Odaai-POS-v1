// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_logs_dao.dart';

// ignore_for_file: type=lint
mixin _$PermissionLogsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PermissionLogsTable get permissionLogs => attachedDatabase.permissionLogs;
  PermissionLogsDaoManager get managers => PermissionLogsDaoManager(this);
}

class PermissionLogsDaoManager {
  final _$PermissionLogsDaoMixin _db;
  PermissionLogsDaoManager(this._db);
  $$PermissionLogsTableTableManager get permissionLogs =>
      $$PermissionLogsTableTableManager(
        _db.attachedDatabase,
        _db.permissionLogs,
      );
}

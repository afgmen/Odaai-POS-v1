// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_roles_dao.dart';

// ignore_for_file: type=lint
mixin _$UserRolesDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserRolesTable get userRoles => attachedDatabase.userRoles;
  UserRolesDaoManager get managers => UserRolesDaoManager(this);
}

class UserRolesDaoManager {
  final _$UserRolesDaoMixin _db;
  UserRolesDaoManager(this._db);
  $$UserRolesTableTableManager get userRoles =>
      $$UserRolesTableTableManager(_db.attachedDatabase, _db.userRoles);
}

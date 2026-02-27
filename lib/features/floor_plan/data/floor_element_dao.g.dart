// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'floor_element_dao.dart';

// ignore_for_file: type=lint
mixin _$FloorElementDaoMixin on DatabaseAccessor<AppDatabase> {
  $FloorElementsTable get floorElements => attachedDatabase.floorElements;
  FloorElementDaoManager get managers => FloorElementDaoManager(this);
}

class FloorElementDaoManager {
  final _$FloorElementDaoMixin _db;
  FloorElementDaoManager(this._db);
  $$FloorElementsTableTableManager get floorElements =>
      $$FloorElementsTableTableManager(_db.attachedDatabase, _db.floorElements);
}

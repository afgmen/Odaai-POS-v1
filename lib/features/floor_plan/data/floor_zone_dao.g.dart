// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'floor_zone_dao.dart';

// ignore_for_file: type=lint
mixin _$FloorZoneDaoMixin on DatabaseAccessor<AppDatabase> {
  $FloorZonesTable get floorZones => attachedDatabase.floorZones;
  FloorZoneDaoManager get managers => FloorZoneDaoManager(this);
}

class FloorZoneDaoManager {
  final _$FloorZoneDaoMixin _db;
  FloorZoneDaoManager(this._db);
  $$FloorZonesTableTableManager get floorZones =>
      $$FloorZonesTableTableManager(_db.attachedDatabase, _db.floorZones);
}

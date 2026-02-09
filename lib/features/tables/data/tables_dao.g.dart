// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tables_dao.dart';

// ignore_for_file: type=lint
mixin _$TablesDaoMixin on DatabaseAccessor<AppDatabase> {
  $RestaurantTablesTable get restaurantTables =>
      attachedDatabase.restaurantTables;
  $ReservationsTable get reservations => attachedDatabase.reservations;
  TablesDaoManager get managers => TablesDaoManager(this);
}

class TablesDaoManager {
  final _$TablesDaoMixin _db;
  TablesDaoManager(this._db);
  $$RestaurantTablesTableTableManager get restaurantTables =>
      $$RestaurantTablesTableTableManager(
        _db.attachedDatabase,
        _db.restaurantTables,
      );
  $$ReservationsTableTableManager get reservations =>
      $$ReservationsTableTableManager(_db.attachedDatabase, _db.reservations);
}

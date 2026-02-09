// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservations_dao.dart';

// ignore_for_file: type=lint
mixin _$ReservationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReservationsTable get reservations => attachedDatabase.reservations;
  $RestaurantTablesTable get restaurantTables =>
      attachedDatabase.restaurantTables;
  ReservationsDaoManager get managers => ReservationsDaoManager(this);
}

class ReservationsDaoManager {
  final _$ReservationsDaoMixin _db;
  ReservationsDaoManager(this._db);
  $$ReservationsTableTableManager get reservations =>
      $$ReservationsTableTableManager(_db.attachedDatabase, _db.reservations);
  $$RestaurantTablesTableTableManager get restaurantTables =>
      $$RestaurantTablesTableTableManager(
        _db.attachedDatabase,
        _db.restaurantTables,
      );
}

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';

/// B-060: Table Status Sync Tests
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Table Status Updates', () {
    test('should update table status in DB', () async {
      // Create table
      final tableId = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T01',
          status: const Value('AVAILABLE'),
          seats: 4,
        ),
      );

      // Update status
      await (db.update(db.restaurantTables)..where((t) => t.id.equals(tableId)))
          .write(const RestaurantTablesCompanion(
        status: Value('ORDERING'),
      ));

      // Verify
      final table = await (db.select(db.restaurantTables)
            ..where((t) => t.id.equals(tableId)))
          .getSingle();

      expect(table.status, 'ORDERING');
    });

    test('should emit new value when status changes', () async {
      // Create table
      final tableId = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T02',
          status: const Value('AVAILABLE'),
          seats: 4,
        ),
      );

      // Watch stream
      final stream = (db.select(db.restaurantTables)
            ..where((t) => t.id.equals(tableId)))
          .watchSingle();

      // Collect emitted values
      final emittedStatuses = <String>[];
      
      stream.listen((table) {
        emittedStatuses.add(table.status);
      });

      // Wait for initial value
      await Future.delayed(const Duration(milliseconds: 100));

      // Update status
      await (db.update(db.restaurantTables)..where((t) => t.id.equals(tableId)))
          .write(const RestaurantTablesCompanion(
        status: Value('ORDERING'),
      ));

      // Wait for stream to emit
      await Future.delayed(const Duration(milliseconds: 100));

      // Should have emitted AVAILABLE then ORDERING
      expect(emittedStatuses.length >= 2, true);
      expect(emittedStatuses.contains('AVAILABLE'), true);
      expect(emittedStatuses.contains('ORDERING'), true);
    });

    test('should handle multiple status transitions', () async {
      final tableId = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T03',
          status: const Value('AVAILABLE'),
          seats: 4,
        ),
      );

      // Transition: AVAILABLE → ORDERING
      await (db.update(db.restaurantTables)..where((t) => t.id.equals(tableId)))
          .write(const RestaurantTablesCompanion(
        status: Value('ORDERING'),
      ));

      var table = await (db.select(db.restaurantTables)
            ..where((t) => t.id.equals(tableId)))
          .getSingle();
      expect(table.status, 'ORDERING');

      // Transition: ORDERING → CHECKOUT
      await (db.update(db.restaurantTables)..where((t) => t.id.equals(tableId)))
          .write(const RestaurantTablesCompanion(
        status: Value('CHECKOUT'),
      ));

      table = await (db.select(db.restaurantTables)
            ..where((t) => t.id.equals(tableId)))
          .getSingle();
      expect(table.status, 'CHECKOUT');

      // Transition: CHECKOUT → AVAILABLE
      await (db.update(db.restaurantTables)..where((t) => t.id.equals(tableId)))
          .write(const RestaurantTablesCompanion(
        status: Value('AVAILABLE'),
      ));

      table = await (db.select(db.restaurantTables)
            ..where((t) => t.id.equals(tableId)))
          .getSingle();
      expect(table.status, 'AVAILABLE');
    });
  });

  group('Drift Stream Behavior', () {
    test('should watch all tables stream', () async {
      // Create 3 tables
      await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T10',
          status: const Value('AVAILABLE'),
          seats: 4,
        ),
      );
      await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T11',
          status: const Value('ORDERING'),
          seats: 2,
        ),
      );
      await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T12',
          status: const Value('CHECKOUT'),
          seats: 6,
        ),
      );

      // Watch stream
      final stream = db.select(db.restaurantTables).watch();

      final tables = await stream.first;
      expect(tables.length >= 3, true);
    });

    test('should update timestamp on status change', () async {
      final tableId = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T20',
          status: const Value('AVAILABLE'),
          seats: 4,
        ),
      );

      final before = DateTime.now();

      await Future.delayed(const Duration(milliseconds: 10));

      await (db.update(db.restaurantTables)..where((t) => t.id.equals(tableId)))
          .write(RestaurantTablesCompanion(
        status: const Value('ORDERING'),
        updatedAt: Value(DateTime.now()),
      ));

      final table = await (db.select(db.restaurantTables)
            ..where((t) => t.id.equals(tableId)))
          .getSingle();

      expect(table.updatedAt.isAfter(before), true);
    });
  });

  group('Bidirectional Sync', () {
    test('should sync from Floor Plan to Tables', () async {
      // Simulate Floor Plan updating a table
      final tableId = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'SYNC-FP',
          status: const Value('AVAILABLE'),
          seats: 4,
        ),
      );

      // Floor Plan updates status
      await (db.update(db.restaurantTables)..where((t) => t.id.equals(tableId)))
          .write(const RestaurantTablesCompanion(
        status: Value('ORDERING'),
      ));

      // Tables should see the change
      final table = await (db.select(db.restaurantTables)
            ..where((t) => t.id.equals(tableId)))
          .getSingle();

      expect(table.status, 'ORDERING');
    });

    test('should sync from Tables to Floor Plan', () async {
      // Simulate Tables updating a table
      final tableId = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'SYNC-TB',
          status: const Value('AVAILABLE'),
          seats: 4,
        ),
      );

      // Tables updates status
      await (db.update(db.restaurantTables)..where((t) => t.id.equals(tableId)))
          .write(const RestaurantTablesCompanion(
        status: Value('CHECKOUT'),
      ));

      // Floor Plan should see the change
      final table = await (db.select(db.restaurantTables)
            ..where((t) => t.id.equals(tableId)))
          .getSingle();

      expect(table.status, 'CHECKOUT');
    });
  });
}

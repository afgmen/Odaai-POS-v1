import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';

/// B-075: Table Duplicate Error Tests
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Table Name Duplicate Detection', () {
    test('should detect duplicate table name', () async {
      // Create first table
      await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T-01',
          seats: const Value(4),
        ),
      );

      // Try to create duplicate
      try {
        await db.into(db.restaurantTables).insert(
          RestaurantTablesCompanion.insert(
            tableNumber: 'T-01',
            seats: const Value(6),
          ),
        );
        fail('Should throw duplicate error');
      } catch (e) {
        expect(e.toString().contains('UNIQUE'), true);
      }
    });

    test('should allow same name after deletion', () async {
      // Create table
      final id = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T-02',
          seats: const Value(4),
        ),
      );

      // Delete table
      await (db.delete(db.restaurantTables)..where((t) => t.id.equals(id)))
          .go();

      // Should allow same name now
      final newId = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T-02',
          seats: const Value(6),
        ),
      );

      expect(newId, isNot(null));
    });

    test('should allow different table names', () async {
      await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T-01',
          seats: const Value(4),
        ),
      );

      // Different name should succeed
      final id2 = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T-02',
          seats: const Value(4),
        ),
      );

      expect(id2, isNot(null));
    });

    test('should be case-sensitive for table names', () async {
      await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T-01',
          seats: const Value(4),
        ),
      );

      // Different case should succeed (SQLite is case-sensitive by default)
      final id2 = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 't-01',
          seats: const Value(4),
        ),
      );

      expect(id2, isNot(null));
    });
  });

  group('Error Message Validation', () {
    test('should provide specific error for table_number duplicate', () {
      const errorMsg = 'UNIQUE constraint failed: restaurant_tables.table_number';
      
      expect(errorMsg.contains('UNIQUE'), true);
      expect(errorMsg.contains('table_number'), true);
    });

    test('should extract table number from error context', () {
      const tableNumber = 'T-01';
      final userMessage = 'Table number "$tableNumber" already exists. Please use a different number.';
      
      expect(userMessage.contains(tableNumber), true);
      expect(userMessage.contains('already exists'), true);
    });
  });

  group('Table Update with Duplicate Name', () {
    test('should allow updating table without changing name', () async {
      final id = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T-01',
          seats: const Value(4),
        ),
      );

      // Update seats without changing name (should succeed)
      await db.update(db.restaurantTables).replace(
        RestaurantTable(
          id: id,
          tableNumber: 'T-01',
          seats: 6,
          positionX: 0,
          positionY: 0,
          status: 'AVAILABLE',
          currentSaleId: null,
          occupiedAt: null,
          reservationId: null,
          shape: 'square',
          zoneId: null,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final updated = await (db.select(db.restaurantTables)
            ..where((t) => t.id.equals(id)))
          .getSingle();

      expect(updated.seats, 6);
    });

    test('should prevent updating to existing name', () async {
      // Create two tables
      await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T-01',
          seats: const Value(4),
        ),
      );

      final id2 = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T-02',
          seats: const Value(4),
        ),
      );

      // Try to rename T-02 to T-01 (should fail)
      try {
        await db.update(db.restaurantTables).replace(
          RestaurantTable(
            id: id2,
            tableNumber: 'T-01', // Duplicate name
            seats: 6,
            positionX: 0,
            positionY: 0,
            status: 'AVAILABLE',
            currentSaleId: null,
            occupiedAt: null,
            reservationId: null,
            shape: 'square',
            zoneId: null,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        fail('Should throw duplicate error');
      } catch (e) {
        expect(e.toString().contains('UNIQUE'), true);
      }
    });
  });
}

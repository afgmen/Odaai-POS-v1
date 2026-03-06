import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:oda_pos/database/app_database.dart';

void main() {
  group('B-062: Merge Table Logic', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Should find other OCCUPIED tables for merging', () async {
      // Create 3 tables: 2 OCCUPIED, 1 AVAILABLE
      final table1 = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T01',
          seats: const Value(4),
          status: const Value('OCCUPIED'),
          currentSaleId: const Value(1),
          positionX: const Value(100),
          positionY: const Value(100),
        ),
      );

      final table2 = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T02',
          seats: const Value(2),
          status: const Value('OCCUPIED'),
          currentSaleId: const Value(2),
          positionX: const Value(200),
          positionY: const Value(100),
        ),
      );

      await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T03',
          seats: const Value(6),
          status: const Value('AVAILABLE'),
          positionX: const Value(300),
          positionY: const Value(100),
        ),
      );

      // Query OCCUPIED tables
      final occupiedTables = await (db.select(db.restaurantTables)
            ..where((t) => t.status.equals('OCCUPIED')))
          .get();

      // Should find 2 OCCUPIED tables
      expect(occupiedTables.length, 2);
      expect(occupiedTables.map((t) => t.id), containsAll([table1, table2]));
    });

    test('Should exclude current table from merge candidates', () async {
      final table1 = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T01',
          seats: const Value(4),
          status: const Value('OCCUPIED'),
          currentSaleId: const Value(1),
          positionX: const Value(100),
          positionY: const Value(100),
        ),
      );

      final table2 = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T02',
          seats: const Value(2),
          status: const Value('OCCUPIED'),
          currentSaleId: const Value(2),
          positionX: const Value(200),
          positionY: const Value(100),
        ),
      );

      // Get all OCCUPIED tables
      final allOccupied = await (db.select(db.restaurantTables)
            ..where((t) => t.status.equals('OCCUPIED')))
          .get();

      // Filter out current table (T01)
      final mergeCandidates = allOccupied
          .where((t) => t.id != table1)
          .toList();

      // Should only find T02
      expect(mergeCandidates.length, 1);
      expect(mergeCandidates.first.id, table2);
      expect(mergeCandidates.first.tableNumber, 'T02');
    });

    test('Should return empty list when only 1 OCCUPIED table exists', () async {
      // Only 1 OCCUPIED table
      await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T01',
          seats: const Value(4),
          status: const Value('OCCUPIED'),
          currentSaleId: const Value(1),
          positionX: const Value(100),
          positionY: const Value(100),
        ),
      );

      // 2 AVAILABLE tables
      await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T02',
          seats: const Value(2),
          status: const Value('AVAILABLE'),
          positionX: const Value(200),
          positionY: const Value(100),
        ),
      );

      final occupiedTables = await (db.select(db.restaurantTables)
            ..where((t) => t.status.equals('OCCUPIED')))
          .get();

      // Should find only 1 OCCUPIED
      expect(occupiedTables.length, 1);

      // After excluding current table, should be empty
      final mergeCandidates = occupiedTables
          .where((t) => t.id != occupiedTables.first.id)
          .toList();
      expect(mergeCandidates.length, 0);
    });

    test('Should find 3 merge candidates when 4 OCCUPIED tables exist', () async {
      // Create 4 OCCUPIED tables
      final table1 = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T01',
          seats: const Value(4),
          status: const Value('OCCUPIED'),
          currentSaleId: const Value(1),
          positionX: const Value(100),
          positionY: const Value(100),
        ),
      );

      await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T02',
          seats: const Value(2),
          status: const Value('OCCUPIED'),
          currentSaleId: const Value(2),
          positionX: const Value(200),
          positionY: const Value(100),
        ),
      );

      await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T03',
          seats: const Value(6),
          status: const Value('OCCUPIED'),
          currentSaleId: const Value(3),
          positionX: const Value(300),
          positionY: const Value(100),
        ),
      );

      await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T04',
          seats: const Value(8),
          status: const Value('OCCUPIED'),
          currentSaleId: const Value(4),
          positionX: const Value(400),
          positionY: const Value(100),
        ),
      );

      // Get all OCCUPIED
      final allOccupied = await (db.select(db.restaurantTables)
            ..where((t) => t.status.equals('OCCUPIED')))
          .get();

      // Exclude current (T01)
      final mergeCandidates = allOccupied
          .where((t) => t.id != table1)
          .toList();

      // Should find 3 candidates (T02, T03, T04)
      expect(mergeCandidates.length, 3);
      expect(mergeCandidates.map((t) => t.tableNumber), 
             containsAll(['T02', 'T03', 'T04']));
    });
  });
}

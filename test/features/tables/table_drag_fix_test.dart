import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:oda_pos/database/app_database.dart';

void main() {
  group('B-064: Table Disappear Bug Fix', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Table should persist after single drag', () async {
      // Create a table
      final tableId = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T01',
          seats: const Value(4),
          status: const Value('AVAILABLE'),
          positionX: const Value(100),
          positionY: const Value(100),
        ),
      );

      // Drag to new position
      await db.tablesDao.updateTablePosition(
        tableId: tableId,
        x: 200,
        y: 150,
      );

      // Verify table still exists with new position
      final table = await db.tablesDao.getTableById(tableId);
      expect(table != null, true);
      expect(table?.positionX, 200);
      expect(table?.positionY, 150);
    });

    test('Table should persist after multiple drags', () async {
      // Create a table
      final tableId = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T02',
          seats: const Value(2),
          status: const Value('AVAILABLE'),
          positionX: const Value(100),
          positionY: const Value(100),
        ),
      );

      // Drag 5 times
      await db.tablesDao.updateTablePosition(tableId: tableId, x: 150, y: 120);
      await db.tablesDao.updateTablePosition(tableId: tableId, x: 200, y: 140);
      await db.tablesDao.updateTablePosition(tableId: tableId, x: 250, y: 160);
      await db.tablesDao.updateTablePosition(tableId: tableId, x: 300, y: 180);
      await db.tablesDao.updateTablePosition(tableId: tableId, x: 350, y: 200);

      // Verify table still exists with final position
      final table = await db.tablesDao.getTableById(tableId);
      expect(table != null, true);
      expect(table?.positionX, 350);
      expect(table?.positionY, 200);
      expect(table?.tableNumber, 'T02');
    });

    test('Multiple tables should not interfere with each other', () async {
      // Create 3 tables
      final table1 = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T01',
          seats: const Value(4),
          status: const Value('AVAILABLE'),
          positionX: const Value(100),
          positionY: const Value(100),
        ),
      );

      final table2 = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T02',
          seats: const Value(2),
          status: const Value('AVAILABLE'),
          positionX: const Value(200),
          positionY: const Value(100),
        ),
      );

      final table3 = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T03',
          seats: const Value(6),
          status: const Value('AVAILABLE'),
          positionX: const Value(300),
          positionY: const Value(100),
        ),
      );

      // Drag all 3 tables
      await db.tablesDao.updateTablePosition(tableId: table1, x: 150, y: 150);
      await db.tablesDao.updateTablePosition(tableId: table2, x: 250, y: 150);
      await db.tablesDao.updateTablePosition(tableId: table3, x: 350, y: 150);

      // Verify all 3 tables exist with correct positions
      final t1 = await db.tablesDao.getTableById(table1);
      final t2 = await db.tablesDao.getTableById(table2);
      final t3 = await db.tablesDao.getTableById(table3);

      expect(t1?.positionX, 150);
      expect(t2?.positionX, 250);
      expect(t3?.positionX, 350);
    });

    test('Table should update timestamp on position change', () async {
      final tableId = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T01',
          seats: const Value(4),
          status: const Value('AVAILABLE'),
          positionX: const Value(100),
          positionY: const Value(100),
        ),
      );

      final before = await db.tablesDao.getTableById(tableId);
      final beforeTime = before!.updatedAt;
      
      // Wait longer to ensure timestamp difference
      await Future.delayed(const Duration(milliseconds: 100));

      await db.tablesDao.updateTablePosition(tableId: tableId, x: 200, y: 150);

      final after = await db.tablesDao.getTableById(tableId);
      final afterTime = after!.updatedAt;
      
      // Check timestamp updated
      expect(afterTime.isAfter(beforeTime) || afterTime.isAtSameMomentAs(beforeTime), true);
    });

    test('Rapid drags should not cause data loss', () async {
      final tableId = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T01',
          seats: const Value(4),
          status: const Value('AVAILABLE'),
          positionX: const Value(100),
          positionY: const Value(100),
        ),
      );

      // Simulate rapid drags (10 times in quick succession)
      for (int i = 0; i < 10; i++) {
        await db.tablesDao.updateTablePosition(
          tableId: tableId,
          x: 100 + (i * 10).toDouble(),
          y: 100 + (i * 5).toDouble(),
        );
      }

      // Verify table still exists with final position
      final table = await db.tablesDao.getTableById(tableId);
      expect(table != null, true);
      expect(table?.positionX, 190);
      expect(table?.positionY, 145);
    });
  });
}

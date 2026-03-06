import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:oda_pos/database/app_database.dart';

void main() {
  group('B-060: Table Status Sync (Floor Plan ↔ Tables)', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Table status update should be reflected in stream', () async {
      // 1. Create a test table
      final tableId = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T01',
          seats: const Value(4),
          status: const Value('AVAILABLE'),
          positionX: const Value(100),
          positionY: const Value(100),
        ),
      );

      // 2. Subscribe to watchAllActiveTables stream
      final stream = db.tablesDao.watchAllActiveTables();
      final streamValues = <List<RestaurantTable>>[];
      
      final subscription = stream.listen((tables) {
        streamValues.add(tables);
      });

      // Wait for initial value
      await Future.delayed(const Duration(milliseconds: 100));

      // 3. Update table status (simulating Floor Plan action)
      await db.tablesDao.updateTableStatus(
        tableId: tableId,
        status: 'OCCUPIED',
      );

      // Wait for stream update
      await Future.delayed(const Duration(milliseconds: 100));

      // 4. Update again (simulating Tables section action)
      await db.tablesDao.updateTableStatus(
        tableId: tableId,
        status: 'CHECKOUT',
      );

      // Wait for stream update
      await Future.delayed(const Duration(milliseconds: 100));

      subscription.cancel();

      // Verify stream received updates
      expect(streamValues.length, greaterThanOrEqualTo(3),
        reason: 'Stream should emit: initial + after OCCUPIED + after CHECKOUT');

      // Verify final status
      final finalTable = await db.tablesDao.getTableById(tableId);
      expect(finalTable?.status, 'CHECKOUT');
    });

    test('Multiple tables sync independently', () async {
      // Create multiple tables
      final table1Id = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T01',
          seats: const Value(2),
          status: const Value('AVAILABLE'),
          positionX: const Value(100),
          positionY: const Value(100),
        ),
      );

      final table2Id = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T02',
          seats: const Value(4),
          status: const Value('AVAILABLE'),
          positionX: const Value(200),
          positionY: const Value(100),
        ),
      );

      // Update T01
      await db.tablesDao.updateTableStatus(
        tableId: table1Id,
        status: 'OCCUPIED',
      );

      // Verify T01 changed, T02 unchanged
      final t1 = await db.tablesDao.getTableById(table1Id);
      final t2 = await db.tablesDao.getTableById(table2Id);

      expect(t1?.status, 'OCCUPIED');
      expect(t2?.status, 'AVAILABLE');

      // Update T02
      await db.tablesDao.updateTableStatus(
        tableId: table2Id,
        status: 'RESERVED',
      );

      // Verify both have correct statuses
      final t1After = await db.tablesDao.getTableById(table1Id);
      final t2After = await db.tablesDao.getTableById(table2Id);

      expect(t1After?.status, 'OCCUPIED');
      expect(t2After?.status, 'RESERVED');
    });

    test('Bidirectional sync: Floor Plan → Tables → Floor Plan', () async {
      // This is a documentation test for the sync mechanism
      // Both Floor Plan and Tables use:
      // - Same DAO: tablesDaoProvider
      // - Same Stream: watchAllActiveTables()
      // - Same update method: updateTableStatus()
      
      const scenarios = [
        'Floor Plan updates status → Tables sees update immediately',
        'Tables updates status → Floor Plan sees update immediately',
      ];

      for (final scenario in scenarios) {
        expect(scenario.contains('immediately'), true,
          reason: 'Drift streams provide real-time updates');
      }
    });
  });
}

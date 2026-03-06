import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:oda_pos/database/app_database.dart';
import 'dart:async';

void main() {
  group('B-060-v2: Edge Cases & Deep Investigation', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Edge Case 1: Concurrent updates on same table', () async {
      // Create test table
      final tableId = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T01',
          seats: const Value(4),
          status: const Value('AVAILABLE'),
          positionX: const Value(100),
          positionY: const Value(100),
        ),
      );

      // Simulate concurrent updates from Floor Plan and Tables
      final futures = <Future>[];
      
      // Update 1: Floor Plan tries to set ORDERING
      futures.add(db.tablesDao.updateTableStatus(
        tableId: tableId,
        status: 'ORDERING',
      ));

      // Update 2: Tables tries to set OCCUPIED (happens almost simultaneously)
      futures.add(db.tablesDao.updateTableStatus(
        tableId: tableId,
        status: 'OCCUPIED',
      ));

      await Future.wait(futures);

      // Check final state (last write wins)
      final table = await db.tablesDao.getTableById(tableId);
      
      // Either ORDERING or OCCUPIED is acceptable (race condition)
      expect(['ORDERING', 'OCCUPIED'].contains(table?.status), true,
        reason: 'Concurrent updates: last write wins');
    });

    test('Edge Case 2: Rapid sequential changes', () async {
      // Create test table
      final tableId = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T02',
          seats: const Value(2),
          status: const Value('AVAILABLE'),
          positionX: const Value(200),
          positionY: const Value(100),
        ),
      );

      // Subscribe to stream
      final streamValues = <List<RestaurantTable>>[];
      final stream = db.tablesDao.watchAllActiveTables();
      final subscription = stream.listen((tables) {
        streamValues.add(tables);
        print('[Stream] Emitted ${tables.length} tables, T02 status: ${tables.firstWhere((t) => t.id == tableId).status}');
      });

      await Future.delayed(const Duration(milliseconds: 50));

      // Rapid changes: AVAILABLE → ORDERING → CHECKOUT (within 1 second)
      final startTime = DateTime.now();
      
      await db.tablesDao.updateTableStatus(tableId: tableId, status: 'ORDERING');
      print('[Update] T02: AVAILABLE → ORDERING at ${DateTime.now().difference(startTime).inMilliseconds}ms');
      
      await Future.delayed(const Duration(milliseconds: 200));
      
      await db.tablesDao.updateTableStatus(tableId: tableId, status: 'OCCUPIED');
      print('[Update] T02: ORDERING → OCCUPIED at ${DateTime.now().difference(startTime).inMilliseconds}ms');
      
      await Future.delayed(const Duration(milliseconds: 200));
      
      await db.tablesDao.updateTableStatus(tableId: tableId, status: 'CHECKOUT');
      print('[Update] T02: OCCUPIED → CHECKOUT at ${DateTime.now().difference(startTime).inMilliseconds}ms');
      
      await Future.delayed(const Duration(milliseconds: 200));

      subscription.cancel();

      // Verify final state
      final table = await db.tablesDao.getTableById(tableId);
      expect(table?.status, 'CHECKOUT');

      // Stream should have emitted multiple times
      print('[Stream] Total emissions: ${streamValues.length}');
      expect(streamValues.length, greaterThan(1),
        reason: 'Stream should emit on each status change');
    });

    test('Edge Case 3: Large table count (100+ tables)', () async {
      final startTime = DateTime.now();
      
      // Create 100 tables
      final tableIds = <int>[];
      for (int i = 1; i <= 100; i++) {
        final id = await db.tablesDao.createTable(
          RestaurantTablesCompanion.insert(
            tableNumber: 'T${i.toString().padLeft(3, '0')}',
            seats: Value(i % 8 + 2), // 2-10 seats
            status: const Value('AVAILABLE'),
            positionX: Value((i % 10) * 100.0),
            positionY: Value((i ~/ 10) * 100.0),
          ),
        );
        tableIds.add(id);
      }

      final createTime = DateTime.now().difference(startTime);
      print('[Perf] Created 100 tables in ${createTime.inMilliseconds}ms');

      // Subscribe to stream
      final stream = db.tablesDao.watchAllActiveTables();
      final completer = Completer<void>();
      
      stream.listen((tables) {
        print('[Stream] Emitted ${tables.length} tables');
        if (!completer.isCompleted) completer.complete();
      });

      await completer.future;

      // Update random table
      final updateStart = DateTime.now();
      await db.tablesDao.updateTableStatus(
        tableId: tableIds[50],
        status: 'OCCUPIED',
      );
      final updateTime = DateTime.now().difference(updateStart);
      print('[Perf] Updated 1 table (out of 100) in ${updateTime.inMilliseconds}ms');

      // Verify update
      final table = await db.tablesDao.getTableById(tableIds[50]);
      expect(table?.status, 'OCCUPIED');

      // Performance check: update should be fast even with 100 tables
      expect(updateTime.inMilliseconds, lessThan(100),
        reason: 'Update should complete within 100ms even with 100 tables');
    });

    test('Edge Case 4: Network delay simulation', () async {
      // Create test table
      final tableId = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T03',
          seats: const Value(4),
          status: const Value('AVAILABLE'),
          positionX: const Value(300),
          positionY: const Value(100),
        ),
      );

      // Subscribe to stream
      final streamEmissions = <String>[];
      final stream = db.tablesDao.watchAllActiveTables();
      final subscription = stream.listen((tables) {
        final table = tables.firstWhere((t) => t.id == tableId);
        streamEmissions.add(table.status);
        print('[Stream] T03 status: ${table.status}');
      });

      await Future.delayed(const Duration(milliseconds: 50));

      // Simulate slow update (network delay)
      print('[Update] Starting slow update...');
      await db.tablesDao.updateTableStatus(tableId: tableId, status: 'ORDERING');
      
      // Artificial delay (simulating network latency)
      await Future.delayed(const Duration(milliseconds: 500));
      print('[Update] Slow update complete');

      // Another quick update
      await db.tablesDao.updateTableStatus(tableId: tableId, status: 'OCCUPIED');
      
      await Future.delayed(const Duration(milliseconds: 200));

      subscription.cancel();

      // Verify final state
      final table = await db.tablesDao.getTableById(tableId);
      expect(table?.status, 'OCCUPIED');

      // Stream should have captured both states
      print('[Stream] Captured states: $streamEmissions');
      expect(streamEmissions.contains('ORDERING'), true);
      expect(streamEmissions.contains('OCCUPIED'), true);
    });
  });
}

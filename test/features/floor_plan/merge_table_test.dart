import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:oda_pos/database/app_database.dart';

/// B-091: Merge Table - active status filter
/// OCCUPIED was never used in production; real statuses are
/// ORDERING / PREPARING / SERVED / CHECKOUT.
void main() {
  const activeStatuses = ['ORDERING', 'PREPARING', 'SERVED', 'CHECKOUT'];

  group('B-091: Merge Table — active-status filter', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    // ── helper ──────────────────────────────────────────────────────────
    Future<int> makeTable(String number, String status, {int? saleId}) =>
        db.tablesDao.createTable(
          RestaurantTablesCompanion.insert(
            tableNumber: number,
            seats: const Value(4),
            status: Value(status),
            currentSaleId: Value(saleId),
            positionX: const Value(100),
            positionY: const Value(100),
          ),
        );

    // ── B-091 core fix: OCCUPIED tables are no longer visible ──────────
    test('OCCUPIED status returns 0 active tables (old bug reproduced)', () async {
      await makeTable('T01', 'OCCUPIED', saleId: 1);
      await makeTable('T02', 'OCCUPIED', saleId: 2);

      final active = await (db.select(db.restaurantTables)
            ..where((t) => t.status.isIn(activeStatuses)))
          .get();

      // With old code (.equals('OCCUPIED')) this would return 2;
      // with new code it returns 0 because real tables use ORDERING/etc.
      expect(active.length, 0,
          reason: 'OCCUPIED is not a valid production status');
    });

    test('ORDERING tables are found as active', () async {
      final id1 = await makeTable('T01', 'ORDERING', saleId: 1);
      final id2 = await makeTable('T02', 'PREPARING', saleId: 2);
      await makeTable('T03', 'AVAILABLE');

      final active = await (db.select(db.restaurantTables)
            ..where((t) => t.status.isIn(activeStatuses)))
          .get();

      expect(active.length, 2);
      expect(active.map((t) => t.id), containsAll([id1, id2]));
    });

    test('All four active statuses are found', () async {
      for (var i = 0; i < activeStatuses.length; i++) {
        await makeTable('T0${i + 1}', activeStatuses[i], saleId: i + 1);
      }
      await makeTable('T05', 'AVAILABLE'); // should NOT appear

      final active = await (db.select(db.restaurantTables)
            ..where((t) => t.status.isIn(activeStatuses)))
          .get();

      expect(active.length, 4);
    });

    test('Current table excluded from merge candidates', () async {
      final current = await makeTable('T01', 'ORDERING', saleId: 1);
      final other = await makeTable('T02', 'SERVED', saleId: 2);

      final allActive = await (db.select(db.restaurantTables)
            ..where((t) => t.status.isIn(activeStatuses)))
          .get();

      final candidates = allActive.where((t) => t.id != current).toList();

      expect(candidates.length, 1);
      expect(candidates.first.id, other);
    });

    test('Returns empty list when only current table is active', () async {
      final current = await makeTable('T01', 'CHECKOUT', saleId: 1);
      await makeTable('T02', 'AVAILABLE');

      final allActive = await (db.select(db.restaurantTables)
            ..where((t) => t.status.isIn(activeStatuses)))
          .get();

      final candidates = allActive.where((t) => t.id != current).toList();

      expect(candidates.length, 0);
    });

    test('Finds 3 candidates when 4 active tables exist', () async {
      final current = await makeTable('T01', 'ORDERING', saleId: 1);
      await makeTable('T02', 'PREPARING', saleId: 2);
      await makeTable('T03', 'SERVED', saleId: 3);
      await makeTable('T04', 'CHECKOUT', saleId: 4);

      final allActive = await (db.select(db.restaurantTables)
            ..where((t) => t.status.isIn(activeStatuses)))
          .get();

      final candidates = allActive.where((t) => t.id != current).toList();

      expect(candidates.length, 3);
      expect(candidates.map((t) => t.tableNumber),
          containsAll(['T02', 'T03', 'T04']));
    });

    test('AVAILABLE / CLEANING tables are NOT merge candidates', () async {
      await makeTable('T01', 'AVAILABLE');
      await makeTable('T02', 'CLEANING');

      final active = await (db.select(db.restaurantTables)
            ..where((t) => t.status.isIn(activeStatuses)))
          .get();

      expect(active.length, 0);
    });
  });
}

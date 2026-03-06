import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:oda_pos/database/app_database.dart';

void main() {
  group('B-061: Checkout Table Status Reset', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Table status should reset to AVAILABLE after checkout', () async {
      final tableId = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T01',
          seats: const Value(4),
          status: const Value('AVAILABLE'),
          positionX: const Value(100),
          positionY: const Value(100),
        ),
      );

      await db.tablesDao.updateTableStatus(
        tableId: tableId,
        status: 'OCCUPIED',
        currentSaleId: 1,
        occupiedAt: DateTime.now(),
      );

      var table = await db.tablesDao.getTableById(tableId);
      expect(table?.status, 'OCCUPIED');

      await db.tablesDao.updateTableStatus(
        tableId: tableId,
        status: 'AVAILABLE',
        currentSaleId: null,
        occupiedAt: null,
      );

      table = await db.tablesDao.getTableById(tableId);
      expect(table?.status, 'AVAILABLE');
      expect(table?.currentSaleId, null);
    });

    test('Dine-in full lifecycle', () async {
      final tableId = await db.tablesDao.createTable(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T02',
          seats: const Value(2),
          status: const Value('AVAILABLE'),
          positionX: const Value(200),
          positionY: const Value(100),
        ),
      );

      await db.tablesDao.updateTableStatus(tableId: tableId, status: 'ORDERING');
      await db.tablesDao.updateTableStatus(tableId: tableId, status: 'OCCUPIED', currentSaleId: 123);
      await db.tablesDao.updateTableStatus(tableId: tableId, status: 'CHECKOUT');
      await db.tablesDao.updateTableStatus(tableId: tableId, status: 'AVAILABLE', currentSaleId: null);

      final table = await db.tablesDao.getTableById(tableId);
      expect(table?.status, 'AVAILABLE');
    });
  });
}

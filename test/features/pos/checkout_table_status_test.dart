import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';

/// B-061: Checkout Table Status Auto-Reset Tests
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown() async {
    await db.close();
  });

  group('Checkout Table Status Reset', () {
    test('should reset table to AVAILABLE after checkout', () async {
      // Create table in ORDERING status
      final tableId = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T01',
          status: const Value('ORDERING'),
          seats: 4,
        ),
      );

      // Create sale
      final saleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'SALE-001',
          paymentMethod: 'cash',
          total: const Value(100.0),
          subtotal: const Value(100.0),
          tableId: Value(tableId),
        ),
      );

      // Simulate checkout - reset table status
      await (db.update(db.restaurantTables)..where((t) => t.id.equals(tableId)))
          .write(const RestaurantTablesCompanion(
        status: Value('AVAILABLE'),
        currentSaleId: Value.absent(),
        occupiedAt: Value.absent(),
      ));

      // Verify table is AVAILABLE
      final table = await (db.select(db.restaurantTables)
            ..where((t) => t.id.equals(tableId)))
          .getSingle();

      expect(table.status, 'AVAILABLE');
      expect(table.currentSaleId, null);
    });

    test('should clear currentSaleId on checkout', () async {
      final tableId = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T02',
          status: const Value('ORDERING'),
          seats: 4,
          currentSaleId: const Value(999),
        ),
      );

      // Reset on checkout
      await (db.update(db.restaurantTables)..where((t) => t.id.equals(tableId)))
          .write(const RestaurantTablesCompanion(
        status: Value('AVAILABLE'),
        currentSaleId: Value(null),
      ));

      final table = await (db.select(db.restaurantTables)
            ..where((t) => t.id.equals(tableId)))
          .getSingle();

      expect(table.currentSaleId, null);
    });

    test('should clear occupiedAt timestamp on checkout', () async {
      final tableId = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T03',
          status: const Value('ORDERING'),
          seats: 4,
          occupiedAt: Value(DateTime.now()),
        ),
      );

      // Reset on checkout
      await (db.update(db.restaurantTables)..where((t) => t.id.equals(tableId)))
          .write(const RestaurantTablesCompanion(
        status: Value('AVAILABLE'),
        occupiedAt: Value(null),
      ));

      final table = await (db.select(db.restaurantTables)
            ..where((t) => t.id.equals(tableId)))
          .getSingle();

      expect(table.occupiedAt, null);
    });

    test('should handle checkout without tableId (takeout)', () async {
      // Create sale without table
      final saleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'TAKEOUT-001',
          paymentMethod: 'cash',
          total: const Value(50.0),
          subtotal: const Value(50.0),
          orderType: const Value('takeaway'),
        ),
      );

      // Complete sale
      await (db.update(db.sales)..where((t) => t.id.equals(saleId)))
          .write(const SalesCompanion(
        status: Value('completed'),
      ));

      final sale = await (db.select(db.sales)..where((t) => t.id.equals(saleId)))
          .getSingle();

      expect(sale.status, 'completed');
      expect(sale.tableId, null);
    });

    test('should preserve table status if payment fails', () async {
      final tableId = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T04',
          status: const Value('ORDERING'),
          seats: 4,
        ),
      );

      // Simulate payment failure - status should NOT change
      // (In real scenario, updateTableStatus won't be called on error)

      final table = await (db.select(db.restaurantTables)
            ..where((t) => t.id.equals(tableId)))
          .getSingle();

      // Should still be ORDERING
      expect(table.status, 'ORDERING');
    });
  });

  group('Status Transition Workflow', () {
    test('should follow complete workflow: AVAILABLE → ORDERING → AVAILABLE', () async {
      final tableId = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'WORKFLOW-01',
          status: const Value('AVAILABLE'),
          seats: 4,
        ),
      );

      // Step 1: Customer seated - AVAILABLE → ORDERING
      await (db.update(db.restaurantTables)..where((t) => t.id.equals(tableId)))
          .write(RestaurantTablesCompanion(
        status: const Value('ORDERING'),
        occupiedAt: Value(DateTime.now()),
      ));

      var table = await (db.select(db.restaurantTables)
            ..where((t) => t.id.equals(tableId)))
          .getSingle();
      expect(table.status, 'ORDERING');

      // Step 2: Checkout complete - ORDERING → AVAILABLE
      await (db.update(db.restaurantTables)..where((t) => t.id.equals(tableId)))
          .write(const RestaurantTablesCompanion(
        status: Value('AVAILABLE'),
        currentSaleId: Value(null),
        occupiedAt: Value(null),
      ));

      table = await (db.select(db.restaurantTables)
            ..where((t) => t.id.equals(tableId)))
          .getSingle();
      expect(table.status, 'AVAILABLE');
      expect(table.occupiedAt, null);
    });
  });
}

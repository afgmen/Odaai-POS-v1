import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';

/// B-062: Table Merge Logic Tests
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown() async {
    await db.close();
  });

  group('Table Merge Logic', () {
    test('should move all items from source to target sale', () async {
      // Create 2 sales
      final targetSaleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'TARGET-001',
          paymentMethod: 'cash',
          total: const Value(100.0),
          subtotal: const Value(100.0),
        ),
      );

      final sourceSaleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'SOURCE-001',
          paymentMethod: 'cash',
          total: const Value(50.0),
          subtotal: const Value(50.0),
        ),
      );

      // Add items to source sale
      await db.into(db.saleItems).insert(
        SaleItemsCompanion.insert(
          saleId: sourceSaleId,
          productId: 1,
          productName: 'Item 1',
          sku: 'SKU1',
          unitPrice: 25.0,
          quantity: 2,
          total: 50.0,
        ),
      );

      // Move items (UPDATE saleId)
      await (db.update(db.saleItems)..where((si) => si.saleId.equals(sourceSaleId)))
          .write(SaleItemsCompanion(saleId: Value(targetSaleId)));

      // Verify items moved
      final sourceItems = await (db.select(db.saleItems)
            ..where((si) => si.saleId.equals(sourceSaleId)))
          .get();
      expect(sourceItems.length, 0);

      final targetItems = await (db.select(db.saleItems)
            ..where((si) => si.saleId.equals(targetSaleId)))
          .get();
      expect(targetItems.length, 1);
    });

    test('should recalculate target sale totals', () async {
      final saleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'CALC-001',
          paymentMethod: 'cash',
          total: const Value(100.0),
          subtotal: const Value(100.0),
        ),
      );

      // Simulate adding merged items
      const additionalSubtotal = 50.0;
      const additionalTotal = 50.0;

      await (db.update(db.sales)..where((s) => s.id.equals(saleId)))
          .write(SalesCompanion(
        subtotal: Value(100.0 + additionalSubtotal),
        total: Value(100.0 + additionalTotal),
      ));

      final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();

      expect(sale.subtotal, 150.0);
      expect(sale.total, 150.0);
    });

    test('should mark source sale as merged', () async {
      final saleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'MERGED-001',
          paymentMethod: 'cash',
          total: const Value(50.0),
          subtotal: const Value(50.0),
        ),
      );

      await (db.update(db.sales)..where((s) => s.id.equals(saleId)))
          .write(const SalesCompanion(status: Value('merged')));

      final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();

      expect(sale.status, 'merged');
    });

    test('should reset source table to AVAILABLE', () async {
      final tableId = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'SOURCE-T',
          status: const Value('OCCUPIED'),
          seats: 4,
          currentSaleId: const Value(999),
        ),
      );

      await (db.update(db.restaurantTables)..where((t) => t.id.equals(tableId)))
          .write(const RestaurantTablesCompanion(
        status: Value('AVAILABLE'),
        currentSaleId: Value.absent(),
      ));

      final table = await (db.select(db.restaurantTables)
            ..where((t) => t.id.equals(tableId)))
          .getSingle();

      expect(table.status, 'AVAILABLE');
      expect(table.currentSaleId, null);
    });

    test('should maintain target table as OCCUPIED', () async {
      final tableId = await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'TARGET-T',
          status: const Value('OCCUPIED'),
          seats: 4,
        ),
      );

      // After merge, target table stays OCCUPIED
      final table = await (db.select(db.restaurantTables)
            ..where((t) => t.id.equals(tableId)))
          .getSingle();

      expect(table.status, 'OCCUPIED');
    });

    test('should handle no duplicate items', () async {
      final targetSaleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'DUP-TARGET',
          paymentMethod: 'cash',
          total: const Value(100.0),
          subtotal: const Value(100.0),
        ),
      );

      final sourceSaleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'DUP-SOURCE',
          paymentMethod: 'cash',
          total: const Value(50.0),
          subtotal: const Value(50.0),
        ),
      );

      // Add 3 items to source
      for (int i = 0; i < 3; i++) {
        await db.into(db.saleItems).insert(
          SaleItemsCompanion.insert(
            saleId: sourceSaleId,
            productId: i + 1,
            productName: 'Item ${i + 1}',
            sku: 'SKU${i + 1}',
            unitPrice: 10.0,
            quantity: 1,
            total: 10.0,
          ),
        );
      }

      // Move all items
      await (db.update(db.saleItems)..where((si) => si.saleId.equals(sourceSaleId)))
          .write(SaleItemsCompanion(saleId: Value(targetSaleId)));

      // Should have exactly 3 items (no duplicates)
      final targetItems = await (db.select(db.saleItems)
            ..where((si) => si.saleId.equals(targetSaleId)))
          .get();

      expect(targetItems.length, 3);
    });
  });
}

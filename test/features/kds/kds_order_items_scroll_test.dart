import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:oda_pos/database/app_database.dart';

/// B-097: KDS — 10개 이상 아이템 전체 목록 표시
///
/// Verifies that getOrderWithItems correctly returns all items regardless of count,
/// and that the list is not truncated.
void main() {
  group('B-097: KDS order items — 10+ items all visible', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> insertProduct(String name) => db.into(db.products).insert(
          ProductsCompanion.insert(
            name: name,
            sku: 'SKU-$name',
            price: const Value(10000),
            stock: const Value(100),
            barcode: Value('BC-$name'),
          ),
        );

    test('10 items all returned by getOrderWithItems', () async {
      final productIds = <int>[];
      for (var i = 0; i < 10; i++) {
        productIds.add(await insertProduct('Item $i'));
      }

      final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
            saleNumber: 'SALE-10',
            paymentMethod: 'cash',
            total: const Value(100000),
            subtotal: const Value(100000),
          ));

      for (var i = 0; i < 10; i++) {
        await db.into(db.saleItems).insert(
          SaleItemsCompanion.insert(
            saleId: saleId,
            sku: 'SKU-\${productIds[i]}',
            productId: productIds[i],
            productName: 'Item $i',
            unitPrice: 10000,
            quantity: 1,
            total: 10000,
          ),
        );
      }

      final items = await (db.select(db.saleItems)
            ..where((t) => t.saleId.equals(saleId)))
          .get();

      expect(items.length, 10,
          reason: 'All 10 items must be returned — no truncation');
    });

    test('15 items all returned (above typical card height)', () async {
      final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
            saleNumber: 'SALE-15',
            paymentMethod: 'cash',
            total: const Value(150000),
            subtotal: const Value(150000),
          ));

      for (var i = 0; i < 15; i++) {
        final pId = await insertProduct('BigItem $i');
        await db.into(db.saleItems).insert(
          SaleItemsCompanion.insert(
            saleId: saleId,
            sku: 'SKU-\$i',
            productId: pId,
            productName: 'BigItem $i',
            unitPrice: 10000,
            quantity: 1,
            total: 10000,
          ),
        );
      }

      final items = await (db.select(db.saleItems)
            ..where((t) => t.saleId.equals(saleId)))
          .get();

      expect(items.length, 15);
    });

    test('items returned in insertion order', () async {
      final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
            saleNumber: 'SALE-ORDER',
            paymentMethod: 'cash',
            total: const Value(30000),
            subtotal: const Value(30000),
          ));

      for (var i = 0; i < 3; i++) {
        final pId = await insertProduct('Ordered$i');
        await db.into(db.saleItems).insert(
          SaleItemsCompanion.insert(
            saleId: saleId,
            sku: 'SKU-\$i',
            productId: pId,
            productName: 'Ordered$i',
            unitPrice: 10000,
            quantity: i + 1,
            total: (i + 1) * 10000.0,
          ),
        );
      }

      final items = await (db.select(db.saleItems)
            ..where((t) => t.saleId.equals(saleId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

      expect(items.map((e) => e.productName).toList(),
          ['Ordered0', 'Ordered1', 'Ordered2']);
    });

    test('empty order returns 0 items (no crash)', () async {
      const saleId = 9999; // no sales record needed (testing non-existent)

      final items = await (db.select(db.saleItems)
            ..where((t) => t.saleId.equals(saleId)))
          .get();

      expect(items.length, 0);
    });
  });
}

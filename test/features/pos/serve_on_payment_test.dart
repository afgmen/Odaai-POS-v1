import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';

// ---------------------------------------------------------------------------
// U-23: serveOrdersBySaleId — mark all kitchen orders SERVED on payment
// ---------------------------------------------------------------------------

AppDatabase _openDb() => AppDatabase.forTesting(NativeDatabase.memory());

int _saleCounter = 0;

Future<int> _insertProduct(AppDatabase db, {int id = 1}) async {
  await db.customStatement(
    'INSERT OR REPLACE INTO products '
    '(id, sku, name, price, cost, stock, min_stock, is_active, needs_sync, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, 100, 5, 1, 0, ?, ?)',
    [
      id,
      'SKU-$id',
      'Product-$id',
      10000.0,
      5000.0,
      DateTime.now().millisecondsSinceEpoch,
      DateTime.now().millisecondsSinceEpoch,
    ],
  );
  return id;
}

Future<Sale> _insertSale(
  AppDatabase db, {
  required int productId,
  bool createKitchenOrder = true,
}) async {
  return db.salesDao.createSale(
    sale: SalesCompanion.insert(
      saleNumber: 'SN-${++_saleCounter}',
      total: const Value(10000),
      paymentMethod: 'CASH',
      status: const Value('completed'),
    ),
    items: [
      SaleItemsCompanion.insert(
        saleId: 0,
        productId: productId,
        productName: 'Product-$productId',
        sku: 'SKU-$productId',
        unitPrice: 10000,
        quantity: 1,
        total: 10000,
      ),
    ],
    createKitchenOrder: createKitchenOrder,
  );
}

void main() {
  group('U-23: serveOrdersBySaleId', () {
    // ── test 1: kitchen order starts PENDING, then becomes SERVED ──────
    test('kitchen order starts as PENDING and is marked SERVED after serveOrdersBySaleId', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db);
      final sale = await _insertSale(db, productId: 1);

      final before = await db.kitchenOrdersDao.getOrderBySaleId(sale.id);
      expect(before, isNotNull);
      expect(before!.status, 'PENDING');
      expect(before.servedAt, isNull);

      final servedBefore = DateTime.now().subtract(const Duration(seconds: 1));
      await db.kitchenOrdersDao.serveOrdersBySaleId(sale.id);

      final after = await db.kitchenOrdersDao.getOrderBySaleId(sale.id);
      expect(after, isNotNull);
      expect(after!.status, 'SERVED');
      expect(after.servedAt, isNotNull);
      expect(after.servedAt!.isAfter(servedBefore), isTrue);
    });

    // ── test 2: CANCELLED orders are NOT changed ──────────────────────
    test('CANCELLED orders are not changed by serveOrdersBySaleId', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db);
      final sale = await _insertSale(db, productId: 1);

      final kdsOrder = await db.kitchenOrdersDao.getOrderBySaleId(sale.id);
      expect(kdsOrder, isNotNull);

      // Cancel the kitchen order first
      await db.kitchenOrdersDao.cancelOrder(kdsOrder!.id);

      final cancelled = await db.kitchenOrdersDao.getOrderById(kdsOrder.id);
      expect(cancelled!.status, 'CANCELLED');

      // Now call serveOrdersBySaleId — should NOT change CANCELLED orders
      await db.kitchenOrdersDao.serveOrdersBySaleId(sale.id);

      final stillCancelled = await db.kitchenOrdersDao.getOrderById(kdsOrder.id);
      expect(stillCancelled!.status, 'CANCELLED',
          reason: 'CANCELLED orders must not be changed to SERVED');
    });

    // ── test 3: only orders for the given saleId are affected ─────────
    test('only orders for the given saleId are changed; other sales stay PENDING', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db, id: 1);
      await _insertProduct(db, id: 2);

      final saleA = await _insertSale(db, productId: 1);
      final saleB = await _insertSale(db, productId: 2);

      // Verify both start PENDING
      final kdsA = await db.kitchenOrdersDao.getOrderBySaleId(saleA.id);
      final kdsB = await db.kitchenOrdersDao.getOrderBySaleId(saleB.id);
      expect(kdsA!.status, 'PENDING');
      expect(kdsB!.status, 'PENDING');

      // Serve only saleA
      await db.kitchenOrdersDao.serveOrdersBySaleId(saleA.id);

      final afterA = await db.kitchenOrdersDao.getOrderBySaleId(saleA.id);
      final afterB = await db.kitchenOrdersDao.getOrderBySaleId(saleB.id);

      expect(afterA!.status, 'SERVED',
          reason: 'saleA kitchen order should be SERVED');
      expect(afterB!.status, 'PENDING',
          reason: 'saleB kitchen order must remain PENDING');
    });

    // ── test 4: already SERVED orders remain SERVED (idempotent) ──────
    test('calling serveOrdersBySaleId on already SERVED order is a no-op', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db);
      final sale = await _insertSale(db, productId: 1);

      await db.kitchenOrdersDao.serveOrdersBySaleId(sale.id);
      final firstServed = await db.kitchenOrdersDao.getOrderBySaleId(sale.id);
      expect(firstServed!.status, 'SERVED');
      final firstServedAt = firstServed.servedAt;

      // Call again — should not throw, servedAt should not change
      await db.kitchenOrdersDao.serveOrdersBySaleId(sale.id);
      final secondServed = await db.kitchenOrdersDao.getOrderBySaleId(sale.id);
      expect(secondServed!.status, 'SERVED');
      expect(secondServed.servedAt, equals(firstServedAt),
          reason: 'servedAt timestamp should not be updated on second call');
    });
  });
}

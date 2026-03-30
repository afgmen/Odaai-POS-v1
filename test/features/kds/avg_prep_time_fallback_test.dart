import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';

// ---------------------------------------------------------------------------
// T-9: calculateAveragePrepTime — fallback to createdAt→servedAt when
//       startedAt/readyAt are not set (auto-serve / U-23 flow).
// ---------------------------------------------------------------------------

AppDatabase _openDb() => AppDatabase.forTesting(NativeDatabase.memory());

int _saleCounter = 0;

/// Insert a minimal product then create a sale, returning the sale id.
Future<int> _insertSaleId(AppDatabase db) async {
  final id = ++_saleCounter;
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
  final sale = await db.salesDao.createSale(
    sale: SalesCompanion.insert(
      saleNumber: 'SN-AVG-$id',
      total: const Value(10000),
      paymentMethod: 'CASH',
      status: const Value('completed'),
    ),
    items: [
      SaleItemsCompanion.insert(
        saleId: 0,
        productId: id,
        productName: 'Product-$id',
        sku: 'SKU-$id',
        unitPrice: 10000,
        quantity: 1,
        total: 10000,
      ),
    ],
    createKitchenOrder: false,
  );
  return sale.id;
}

/// Insert a kitchen order with explicit timestamps (today).
Future<void> _insertKitchenOrder(
  AppDatabase db, {
  required int saleId,
  required String status,
  required DateTime createdAt,
  DateTime? startedAt,
  DateTime? readyAt,
  DateTime? servedAt,
}) async {
  await db.into(db.kitchenOrders).insert(
    KitchenOrdersCompanion.insert(
      saleId: saleId,
      status: Value(status),
      createdAt: Value(createdAt),
      startedAt: Value(startedAt),
      readyAt: Value(readyAt),
      servedAt: Value(servedAt),
    ),
  );
}

void main() {
  group('T-9: calculateAveragePrepTime fallback', () {
    // ── Test A: preferred path — startedAt → readyAt ──────────────────
    test('A: uses startedAt→readyAt when both are set', () async {
      final db = _openDb();
      addTearDown(db.close);

      final today = DateTime.now();
      final saleId = await _insertSaleId(db);

      final started = DateTime(today.year, today.month, today.day, 10, 0, 0);
      final ready = DateTime(today.year, today.month, today.day, 10, 5, 0); // 300s

      await _insertKitchenOrder(
        db,
        saleId: saleId,
        status: 'SERVED',
        createdAt: started,
        startedAt: started,
        readyAt: ready,
        servedAt: ready.add(const Duration(minutes: 2)),
      );

      final avg = await db.kitchenOrdersDao.calculateAveragePrepTime();
      expect(avg, closeTo(300, 1),
          reason: 'Expected 300s (5 min) from startedAt→readyAt');
    });

    // ── Test B: fallback path — createdAt → servedAt ──────────────────
    test('B: falls back to createdAt→servedAt when startedAt/readyAt are null', () async {
      final db = _openDb();
      addTearDown(db.close);

      final today = DateTime.now();
      final saleId = await _insertSaleId(db);

      final created = DateTime(today.year, today.month, today.day, 11, 0, 0);
      final served = DateTime(today.year, today.month, today.day, 11, 8, 0); // 480s

      await _insertKitchenOrder(
        db,
        saleId: saleId,
        status: 'SERVED',
        createdAt: created,
        startedAt: null,
        readyAt: null,
        servedAt: served,
      );

      final avg = await db.kitchenOrdersDao.calculateAveragePrepTime();
      expect(avg, closeTo(480, 1),
          reason: 'Expected 480s (8 min) from createdAt→servedAt fallback');
    });

    // ── Test C: no valid timestamps → returns 0 ───────────────────────
    test('C: orders with no valid timestamps are not counted (returns 0)', () async {
      final db = _openDb();
      addTearDown(db.close);

      final today = DateTime.now();
      final saleId = await _insertSaleId(db);

      final created = DateTime(today.year, today.month, today.day, 12, 0, 0);

      // SERVED but no startedAt, no readyAt, and no servedAt
      await _insertKitchenOrder(
        db,
        saleId: saleId,
        status: 'SERVED',
        createdAt: created,
        startedAt: null,
        readyAt: null,
        servedAt: null,
      );

      final avg = await db.kitchenOrdersDao.calculateAveragePrepTime();
      expect(avg, 0.0,
          reason: 'Orders without any valid timestamps must not be counted');
    });

    // ── Test D: mix of preferred and fallback orders ───────────────────
    test('D: mix of preferred-path and fallback-path orders averaged correctly', () async {
      final db = _openDb();
      addTearDown(db.close);

      final today = DateTime.now();

      // Order 1 — preferred: startedAt→readyAt = 300s
      final saleId1 = await _insertSaleId(db);
      final started1 = DateTime(today.year, today.month, today.day, 9, 0, 0);
      final ready1 = DateTime(today.year, today.month, today.day, 9, 5, 0);
      await _insertKitchenOrder(
        db,
        saleId: saleId1,
        status: 'SERVED',
        createdAt: started1,
        startedAt: started1,
        readyAt: ready1,
        servedAt: ready1.add(const Duration(minutes: 1)),
      );

      // Order 2 — fallback: createdAt→servedAt = 420s (7 min)
      final saleId2 = await _insertSaleId(db);
      final created2 = DateTime(today.year, today.month, today.day, 10, 0, 0);
      final served2 = DateTime(today.year, today.month, today.day, 10, 7, 0);
      await _insertKitchenOrder(
        db,
        saleId: saleId2,
        status: 'SERVED',
        createdAt: created2,
        startedAt: null,
        readyAt: null,
        servedAt: served2,
      );

      // Average = (300 + 420) / 2 = 360s
      final avg = await db.kitchenOrdersDao.calculateAveragePrepTime();
      expect(avg, closeTo(360, 1),
          reason: 'Average of 300s and 420s should be 360s');
    });

    // ── Test E: non-SERVED orders are excluded ────────────────────────
    test('E: non-SERVED orders are excluded from the average', () async {
      final db = _openDb();
      addTearDown(db.close);

      final today = DateTime.now();

      // Only PENDING order — should not be counted
      final saleId = await _insertSaleId(db);
      final created = DateTime(today.year, today.month, today.day, 8, 0, 0);
      await _insertKitchenOrder(
        db,
        saleId: saleId,
        status: 'PENDING',
        createdAt: created,
        startedAt: created,
        readyAt: created.add(const Duration(minutes: 5)),
        servedAt: null,
      );

      final avg = await db.kitchenOrdersDao.calculateAveragePrepTime();
      expect(avg, 0.0,
          reason: 'PENDING orders must not be included in prep time average');
    });

    // ── Test F: no orders at all → returns 0 ─────────────────────────
    test('F: returns 0.0 when there are no orders', () async {
      final db = _openDb();
      addTearDown(db.close);

      final avg = await db.kitchenOrdersDao.calculateAveragePrepTime();
      expect(avg, 0.0);
    });
  });
}

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';
import 'package:oda_pos/database/daos/sales_dao.dart';
import 'package:oda_pos/features/daily_closing/data/daily_closing_dao.dart';

// ---------------------------------------------------------------------------
// Section A: POS → KDS → Daily Closing full cycle integration tests.
//
// All tests use an in-memory SQLite database (AppDatabase.forTesting) so
// they are self-contained, fast, and require no network / Flutter binding.
// ---------------------------------------------------------------------------

/// Open a fresh in-memory database for each test.
AppDatabase _openDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Monotonically increasing counter for unique sale numbers across tests.
int _saleCounter = 0;

/// Minimal product row inserted directly into the products table.
Future<int> _insertProduct(AppDatabase db, {
  int id = 1,
  String name = 'Pho Bo',
  double price = 15000,
}) async {
  await db.customStatement(
    'INSERT OR REPLACE INTO products '
    '(id, sku, name, price, cost, stock, min_stock, is_active, needs_sync, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, 100, 5, 1, 0, ?, ?)',
    [
      id,
      'SKU-$id',
      name,
      price,
      price * 0.5,
      DateTime.now().millisecondsSinceEpoch,
      DateTime.now().millisecondsSinceEpoch,
    ],
  );
  return id;
}

/// Insert a completed sale and its items, returning the new Sale row.
Future<Sale> _insertSale(
  AppDatabase db, {
  required int productId,
  required String productName,
  required double unitPrice,
  int quantity = 1,
  String paymentMethod = 'CASH',
  DateTime? saleDate,
}) async {
  final date = saleDate ?? DateTime.now();
  final total = unitPrice * quantity;

  return db.salesDao.createSale(
    sale: SalesCompanion.insert(
      saleNumber: 'SN-${++_saleCounter}',
      saleDate: Value(date),
      subtotal: Value(total),
      total: Value(total),
      paymentMethod: paymentMethod,
      status: const Value('completed'),
    ),
    items: [
      SaleItemsCompanion.insert(
        saleId: 0, // placeholder; overwritten by createSale via copyWith
        productId: productId,
        productName: productName,
        sku: 'SKU-$productId',
        unitPrice: unitPrice,
        quantity: quantity,
        total: total,
      ),
    ],
    createKitchenOrder: true,
  );
}

void main() {
  // ── A-1  POS → KDS: order appears immediately after sale ─────────────────
  group('A — POS → KDS → Closing full cycle', () {
    test('A-1: completing a sale creates a KDS order in PENDING status', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db);
      final sale = await _insertSale(db, productId: 1, productName: 'Pho Bo', unitPrice: 15000);

      final kdsOrder = await db.kitchenOrdersDao.getOrderBySaleId(sale.id);
      expect(kdsOrder, isNotNull);
      expect(kdsOrder!.status, 'PENDING');
      expect(kdsOrder.saleId, sale.id);
    });

    // ── A-2  PREPARING: startedAt timestamp recorded ──────────────────────
    test('A-2: marking order as PREPARING records startedAt timestamp', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db);
      final sale = await _insertSale(db, productId: 1, productName: 'Pho Bo', unitPrice: 15000);
      final kds = await db.kitchenOrdersDao.getOrderBySaleId(sale.id);
      expect(kds, isNotNull);

      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final success = await db.kitchenOrdersDao.startPreparing(kds!.id);
      expect(success, isTrue);

      final updated = await db.kitchenOrdersDao.getOrderById(kds.id);
      expect(updated!.status, 'PREPARING');
      expect(updated.startedAt, isNotNull);
      expect(updated.startedAt!.isAfter(before), isTrue);
    });

    // ── A-3  READY: readyAt timestamp recorded ────────────────────────────
    test('A-3: marking order as READY records readyAt timestamp', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db);
      final sale = await _insertSale(db, productId: 1, productName: 'Pho Bo', unitPrice: 15000);
      final kds = await db.kitchenOrdersDao.getOrderBySaleId(sale.id);

      await db.kitchenOrdersDao.startPreparing(kds!.id);

      final before = DateTime.now().subtract(const Duration(seconds: 1));
      await db.kitchenOrdersDao.markAsReady(kds.id);

      final updated = await db.kitchenOrdersDao.getOrderById(kds.id);
      expect(updated!.status, 'READY');
      expect(updated.readyAt, isNotNull);
      expect(updated.readyAt!.isAfter(before), isTrue);
    });

    // ── A-4  SERVED: order disappears from active list ────────────────────
    test('A-4: marking order as SERVED removes it from active orders', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db);
      final sale = await _insertSale(db, productId: 1, productName: 'Pho Bo', unitPrice: 15000);
      final kds = await db.kitchenOrdersDao.getOrderBySaleId(sale.id);

      await db.kitchenOrdersDao.startPreparing(kds!.id);
      await db.kitchenOrdersDao.markAsReady(kds.id);
      await db.kitchenOrdersDao.markAsServed(kds.id);

      final activeOrders = await db.kitchenOrdersDao.getActiveOrders();
      expect(activeOrders.where((o) => o.id == kds.id), isEmpty);

      // servedAt timestamp also recorded
      final served = await db.kitchenOrdersDao.getOrderById(kds.id);
      expect(served!.servedAt, isNotNull);
    });

    // ── A-5  Daily Closing includes the sale ─────────────────────────────
    test('A-5: daily closing aggregates the sale amount correctly', () async {
      final db = _openDb();
      addTearDown(db.close);

      final today = DateTime.now();
      await _insertProduct(db, price: 20000);
      await _insertSale(db,
        productId: 1,
        productName: 'Pho Bo',
        unitPrice: 20000,
        paymentMethod: 'CASH',
        saleDate: today,
      );

      final agg = await db.dailyClosingDao.aggregateSalesForDate(today);
      expect(agg, isNotNull);
      expect(agg!.totalTransactions, 1);
      expect(agg.totalSales, closeTo(20000, 0.01));
      expect(agg.cashSales, closeTo(20000, 0.01));
    });

    // ── Full lifecycle: PENDING → PREPARING → READY → SERVED in sequence ──
    test('A-6: full lifecycle status sequence is correct', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db);
      final sale = await _insertSale(db, productId: 1, productName: 'Pho Bo', unitPrice: 15000);
      final kds = await db.kitchenOrdersDao.getOrderBySaleId(sale.id);
      expect(kds!.status, 'PENDING');

      await db.kitchenOrdersDao.startPreparing(kds.id);
      expect((await db.kitchenOrdersDao.getOrderById(kds.id))!.status, 'PREPARING');

      await db.kitchenOrdersDao.markAsReady(kds.id);
      expect((await db.kitchenOrdersDao.getOrderById(kds.id))!.status, 'READY');

      await db.kitchenOrdersDao.markAsServed(kds.id);
      expect((await db.kitchenOrdersDao.getOrderById(kds.id))!.status, 'SERVED');
    });

    // ── Multiple sales → closing sums all ────────────────────────────────
    test('A-7: daily closing sums multiple sales correctly', () async {
      final db = _openDb();
      addTearDown(db.close);

      final today = DateTime.now();
      await _insertProduct(db, id: 1, price: 15000);
      await _insertProduct(db, id: 2, name: 'Bun Bo', price: 13000);

      await _insertSale(db, productId: 1, productName: 'Pho Bo', unitPrice: 15000, paymentMethod: 'CASH', saleDate: today);
      await _insertSale(db, productId: 2, productName: 'Bun Bo', unitPrice: 13000, paymentMethod: 'CARD', saleDate: today);

      final agg = await db.dailyClosingDao.aggregateSalesForDate(today);
      expect(agg!.totalTransactions, 2);
      expect(agg.totalSales, closeTo(28000, 0.01));
      expect(agg.cashSales, closeTo(15000, 0.01));
      expect(agg.cardSales, closeTo(13000, 0.01));
    });

    // ── createKitchenOrder=false skips KDS ────────────────────────────────
    test('A-8: sale with createKitchenOrder=false does not create a KDS order', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db);
      final sale = await db.salesDao.createSale(
        sale: SalesCompanion.insert(
          saleNumber: 'SN-NOKDS',
          total: const Value(10000),
          paymentMethod: 'CASH',
          status: const Value('completed'),
        ),
        items: [
          SaleItemsCompanion.insert(
            saleId: 0, // placeholder; overwritten by createSale via copyWith
            productId: 1,
            productName: 'Pho Bo',
            sku: 'SKU-1',
            unitPrice: 10000,
            quantity: 1,
            total: 10000,
          ),
        ],
        createKitchenOrder: false,
      );

      final kds = await db.kitchenOrdersDao.getOrderBySaleId(sale.id);
      expect(kds, isNull);
    });
  });
}

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';
import 'package:oda_pos/database/daos/sales_dao.dart';
import 'package:oda_pos/features/kds/data/models/kitchen_order_with_items.dart';
import 'package:oda_pos/features/kds/data/models/menu_item_summary.dart';

// ---------------------------------------------------------------------------
// Section C: KDS Menu Summary aggregation integration tests.
//
// The menuItemSummaryProvider logic is replicated here as a pure function
// (same algorithm, no Riverpod / DB streams) so we can test it against a
// real in-memory database without triggering Flutter bindings.
//
// Scenarios tested:
//   C-9   Three orders sharing the same menu → quantities summed correctly
//   C-10  Order status change → summary reflects new status breakdown
//   C-11  Order cancelled → that order's items removed from summary
// ---------------------------------------------------------------------------

AppDatabase _openDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Monotonically increasing counter for unique sale numbers within a test run.
int _saleCounter = 0;

// ── Mirror of menuItemSummaryProvider aggregation logic ──────────────────
// (Extracted from kds_screen_provider.dart so we can unit-test it without
//  Riverpod / async* / StreamProvider plumbing.)

List<MenuItemSummary> _buildSummary(List<KitchenOrderWithItems> ordersWithItems) {
  final Map<String, _Acc> acc = {};

  for (final owi in ordersWithItems) {
    final status = owi.order.status; // 'PENDING' | 'PREPARING' | 'READY' | ...

    for (final item in owi.items) {
      final name = item.productName;
      acc.putIfAbsent(name, () => _Acc(name));

      acc[name]!.total += item.quantity;
      acc[name]!.orderIds.add(owi.order.id);

      switch (status) {
        case 'PENDING':
          acc[name]!.pending += item.quantity;
          break;
        case 'PREPARING':
          acc[name]!.preparing += item.quantity;
          break;
        case 'READY':
          acc[name]!.ready += item.quantity;
          break;
      }
    }
  }

  return acc.values
      .map((a) => MenuItemSummary(
            productName: a.name,
            totalQuantity: a.total,
            pendingQuantity: a.pending,
            preparingQuantity: a.preparing,
            readyQuantity: a.ready,
            orderCount: a.orderIds.length,
          ))
      .toList()
    ..sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));
}

class _Acc {
  final String name;
  int total = 0, pending = 0, preparing = 0, ready = 0;
  final Set<int> orderIds = {};
  _Acc(this.name);
}
// ─────────────────────────────────────────────────────────────────────────

/// Insert a minimal product row.
Future<void> _insertProduct(AppDatabase db, {int id = 1, String name = 'Coffee', double price = 5000}) async {
  await db.customStatement(
    'INSERT OR REPLACE INTO products '
    '(id, sku, name, price, cost, stock, min_stock, is_active, needs_sync, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, 100, 5, 1, 0, ?, ?)',
    [
      id, 'SKU-$id', name, price, price * 0.5,
      DateTime.now().millisecondsSinceEpoch,
      DateTime.now().millisecondsSinceEpoch,
    ],
  );
}

/// Create a sale + KDS order and return the pair.
Future<({Sale sale, int kdsId})> _createSaleWithKds(
  AppDatabase db, {
  required int productId,
  required String productName,
  required double unitPrice,
  int quantity = 1,
}) async {
  final total = unitPrice * quantity;
  final sale = await db.salesDao.createSale(
    sale: SalesCompanion.insert(
      saleNumber: 'SN-${++_saleCounter}',
      total: Value(total),
      subtotal: Value(total),
      paymentMethod: 'CASH',
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

  final kds = await db.kitchenOrdersDao.getOrderBySaleId(sale.id);
  return (sale: sale, kdsId: kds!.id);
}

void main() {
  group('C — KDS MenuSummary aggregation', () {
    // ── C-9  Three orders with same menu → quantities summed ──────────────
    test('C-9: three orders containing the same menu item sum quantities correctly', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db, id: 1, name: 'Pho Bo', price: 15000);

      // Create 3 separate orders each with qty=1 of 'Pho Bo'
      await _createSaleWithKds(db, productId: 1, productName: 'Pho Bo', unitPrice: 15000);
      await _createSaleWithKds(db, productId: 1, productName: 'Pho Bo', unitPrice: 15000);
      await _createSaleWithKds(db, productId: 1, productName: 'Pho Bo', unitPrice: 15000);

      final activeOrders = await db.kitchenOrdersDao.getActiveOrdersWithItems();
      final summaries = _buildSummary(activeOrders);

      expect(summaries.length, 1);
      final pho = summaries.first;
      expect(pho.productName, 'Pho Bo');
      expect(pho.totalQuantity, 3);        // 3 × 1
      expect(pho.pendingQuantity, 3);      // all still PENDING
      expect(pho.orderCount, 3);           // 3 distinct orders
    });

    test('C-9b: orders with qty>1 are summed per-item quantity', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db, id: 1, name: 'Coffee', price: 5000);

      await _createSaleWithKds(db, productId: 1, productName: 'Coffee', unitPrice: 5000, quantity: 2);
      await _createSaleWithKds(db, productId: 1, productName: 'Coffee', unitPrice: 5000, quantity: 3);

      final summaries = _buildSummary(
        await db.kitchenOrdersDao.getActiveOrdersWithItems(),
      );

      expect(summaries.first.totalQuantity, 5);   // 2 + 3
      expect(summaries.first.orderCount, 2);
    });

    test('C-9c: two different menu items appear as separate summary entries', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db, id: 1, name: 'Pho Bo', price: 15000);
      await _insertProduct(db, id: 2, name: 'Bun Bo', price: 13000);

      await _createSaleWithKds(db, productId: 1, productName: 'Pho Bo', unitPrice: 15000);
      await _createSaleWithKds(db, productId: 2, productName: 'Bun Bo', unitPrice: 13000);

      final summaries = _buildSummary(
        await db.kitchenOrdersDao.getActiveOrdersWithItems(),
      );

      expect(summaries.length, 2);
      final names = summaries.map((s) => s.productName).toSet();
      expect(names, containsAll(['Pho Bo', 'Bun Bo']));
    });

    // ── C-10  Status change → summary updates breakdown ───────────────────
    test('C-10: when order moves to PREPARING, pendingQty decreases and preparingQty increases', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db, id: 1, name: 'Latte', price: 6000);

      final r1 = await _createSaleWithKds(db, productId: 1, productName: 'Latte', unitPrice: 6000, quantity: 2);
      final r2 = await _createSaleWithKds(db, productId: 1, productName: 'Latte', unitPrice: 6000, quantity: 1);

      // Before: both PENDING
      final before = _buildSummary(await db.kitchenOrdersDao.getActiveOrdersWithItems());
      expect(before.first.pendingQuantity, 3);
      expect(before.first.preparingQuantity, 0);

      // Move first order to PREPARING
      await db.kitchenOrdersDao.startPreparing(r1.kdsId);

      final after = _buildSummary(await db.kitchenOrdersDao.getActiveOrdersWithItems());
      expect(after.first.totalQuantity, 3);        // unchanged
      expect(after.first.pendingQuantity, 1);       // only r2 still pending
      expect(after.first.preparingQuantity, 2);     // r1 now preparing
    });

    test('C-10b: when order moves to READY, breakdown shifts accordingly', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db, id: 1, name: 'Tea', price: 3000);

      final r = await _createSaleWithKds(db, productId: 1, productName: 'Tea', unitPrice: 3000, quantity: 4);

      await db.kitchenOrdersDao.startPreparing(r.kdsId);
      await db.kitchenOrdersDao.markAsReady(r.kdsId);

      final summaries = _buildSummary(await db.kitchenOrdersDao.getActiveOrdersWithItems());
      expect(summaries.first.readyQuantity, 4);
      expect(summaries.first.preparingQuantity, 0);
      expect(summaries.first.pendingQuantity, 0);
    });

    // ── C-11  Cancel order → items removed from summary ──────────────────
    test('C-11: cancelled order is excluded from active order summary', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db, id: 1, name: 'Juice', price: 7000);

      final r1 = await _createSaleWithKds(db, productId: 1, productName: 'Juice', unitPrice: 7000, quantity: 2);
      final r2 = await _createSaleWithKds(db, productId: 1, productName: 'Juice', unitPrice: 7000, quantity: 1);

      // Before cancel: total = 3
      final before = _buildSummary(await db.kitchenOrdersDao.getActiveOrdersWithItems());
      expect(before.first.totalQuantity, 3);

      // Cancel r1
      await db.kitchenOrdersDao.cancelOrder(r1.kdsId);

      // After cancel: only r2 remains (qty=1)
      final after = _buildSummary(await db.kitchenOrdersDao.getActiveOrdersWithItems());
      expect(after.first.totalQuantity, 1);
      expect(after.first.orderCount, 1);
    });

    test('C-11b: cancelling the only order for a menu item removes it from summary entirely', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db, id: 1, name: 'Smoothie', price: 8000);
      final r = await _createSaleWithKds(db, productId: 1, productName: 'Smoothie', unitPrice: 8000);

      await db.kitchenOrdersDao.cancelOrder(r.kdsId);

      final summaries = _buildSummary(await db.kitchenOrdersDao.getActiveOrdersWithItems());
      expect(summaries.where((s) => s.productName == 'Smoothie'), isEmpty);
    });

    // ── C-12  Sort order: highest total quantity first ────────────────────
    test('C-12: summary is sorted by totalQuantity descending', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db, id: 1, name: 'Coffee', price: 5000);
      await _insertProduct(db, id: 2, name: 'Tea', price: 3000);

      // Coffee: qty 1, Tea: qty 3
      await _createSaleWithKds(db, productId: 1, productName: 'Coffee', unitPrice: 5000, quantity: 1);
      await _createSaleWithKds(db, productId: 2, productName: 'Tea', unitPrice: 3000, quantity: 3);

      final summaries = _buildSummary(await db.kitchenOrdersDao.getActiveOrdersWithItems());
      expect(summaries.first.productName, 'Tea');   // highest qty first
      expect(summaries.last.productName, 'Coffee');
    });

    // ── C-13  SERVED order not in active list ─────────────────────────────
    test('C-13: SERVED order is excluded from active orders summary', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db, id: 1, name: 'Espresso', price: 4000);

      final r = await _createSaleWithKds(db, productId: 1, productName: 'Espresso', unitPrice: 4000, quantity: 2);
      await db.kitchenOrdersDao.startPreparing(r.kdsId);
      await db.kitchenOrdersDao.markAsReady(r.kdsId);
      await db.kitchenOrdersDao.markAsServed(r.kdsId);

      final summaries = _buildSummary(await db.kitchenOrdersDao.getActiveOrdersWithItems());
      expect(summaries.where((s) => s.productName == 'Espresso'), isEmpty);
    });
  });
}

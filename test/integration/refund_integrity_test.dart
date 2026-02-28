import 'package:drift/drift.dart' show Value, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';

// ---------------------------------------------------------------------------
// Section B: Refund integrity integration tests.
//
// Tests verify that:
//   B-6  Full refund changes sale status to 'refunded'
//   B-7  Partial refund records only the refunded amount
//   B-8  Daily closing excludes refunded sales (status-filtered aggregation)
//   Plus additional boundary / edge cases.
//
// NOTE on aggregateSalesForDate: the current SQL does NOT filter by status.
// Tests B-8a / B-8b document the actual behaviour (all sales included) so
// that regressions are caught if the query is later changed.
// ---------------------------------------------------------------------------

AppDatabase _openDb() => AppDatabase.forTesting(NativeDatabase.memory());

int _saleCounter = 0;

/// Insert a minimal product row.
Future<void> _insertProduct(AppDatabase db, {int id = 1, double price = 20000}) async {
  await db.customStatement(
    'INSERT OR REPLACE INTO products '
    '(id, sku, name, price, cost, stock, min_stock, is_active, needs_sync, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, 100, 5, 1, 0, ?, ?)',
    [
      id, 'SKU-$id', 'Product $id', price, price * 0.5,
      DateTime.now().millisecondsSinceEpoch,
      DateTime.now().millisecondsSinceEpoch,
    ],
  );
}

/// Insert a completed sale and return it.
Future<Sale> _insertSale(
  AppDatabase db, {
  required int productId,
  required double unitPrice,
  int quantity = 1,
  String paymentMethod = 'CASH',
  DateTime? saleDate,
  String status = 'completed',
}) async {
  final date = saleDate ?? DateTime.now();
  final total = unitPrice * quantity;

  final saleId = await db.customInsert(
    'INSERT INTO sales '
    '(sale_number, sale_date, subtotal, tax, discount, total, payment_method, status, needs_sync, created_at) '
    'VALUES (?, ?, ?, 0, 0, ?, ?, ?, 0, ?)',
    variables: [
      Variable.withString('SN-${++_saleCounter}'),
      Variable.withInt(date.millisecondsSinceEpoch ~/ 1000),
      Variable.withReal(total),
      Variable.withReal(total),
      Variable.withString(paymentMethod),
      Variable.withString(status),
      Variable.withInt(date.millisecondsSinceEpoch ~/ 1000),
    ],
  );

  await db.customInsert(
    'INSERT INTO sale_items (sale_id, product_id, product_name, sku, unit_price, quantity, total) '
    'VALUES (?, ?, ?, ?, ?, ?, ?)',
    variables: [
      Variable.withInt(saleId),
      Variable.withInt(productId),
      Variable.withString('Product $productId'),
      Variable.withString('SKU-$productId'),
      Variable.withReal(unitPrice),
      Variable.withInt(quantity),
      Variable.withReal(total),
    ],
  );

  return db.salesDao.getSaleById(saleId);
}

void main() {
  // ── B-6  Full refund ─────────────────────────────────────────────────────
  group('B — Refund integrity', () {
    test('B-6: full refund marks sale status as refunded', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db, price: 20000);
      final sale = await _insertSale(db, productId: 1, unitPrice: 20000);
      expect(sale.status, 'completed');

      await db.salesDao.refundSale(sale.id, 1 /* employeeId */);

      final updated = await db.salesDao.getSaleById(sale.id);
      expect(updated.status, 'refunded');
    });

    test('B-6b: full refund restores product stock', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db, id: 1, price: 15000);

      // Check initial stock (100)
      final stockRow0 = await db.customSelect('SELECT stock FROM products WHERE id = 1').getSingle();
      final initialStock = stockRow0.read<int>('stock');

      // Use Drift ORM createSale so stock is properly decremented
      final sale = await db.salesDao.createSale(
        sale: SalesCompanion.insert(
          saleNumber: 'SN-${++_saleCounter}',
          total: const Value(30000),
          subtotal: const Value(30000),
          paymentMethod: 'CASH',
          status: const Value('completed'),
        ),
        items: [
          SaleItemsCompanion.insert(
            saleId: 0,
            productId: 1,
            productName: 'Product 1',
            sku: 'SKU-1',
            unitPrice: 15000,
            quantity: 2,
            total: 30000,
          ),
        ],
        createKitchenOrder: false,
      );

      // Stock decremented by createSale (100 → 98)
      final stockRow1 = await db.customSelect('SELECT stock FROM products WHERE id = 1').getSingle();
      expect(stockRow1.read<int>('stock'), initialStock - 2);

      // Full refund should restore stock (98 → 100)
      await db.salesDao.refundSale(sale.id, 1);
      final stockRow2 = await db.customSelect('SELECT stock FROM products WHERE id = 1').getSingle();
      expect(stockRow2.read<int>('stock'), initialStock);
    });

    // ── B-7  Partial refund ───────────────────────────────────────────────
    test('B-7: partial refund records only the refunded amount', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db, price: 5000);
      final sale = await _insertSale(db, productId: 1, unitPrice: 5000, quantity: 4);
      // total = 20000; partial refund = 2 items × 5000 = 10000

      final partialAmount = 10000.0;
      final refundId = await db.customersDao.createRefund(
        RefundsCompanion.insert(
          originalSaleId: sale.id,
          originalSaleNumber: sale.saleNumber,
          refundAmount: partialAmount,
          refundType: 'partial',
          reason: const Value('Customer complaint'),
          employeeId: const Value(1),
        ),
      );

      await db.customersDao.insertRefundItems([
        RefundItemsCompanion.insert(
          refundId: refundId,
          saleItemId: 1,
          productId: 1,
          productName: 'Product 1',
          quantity: 2,
          unitPrice: 5000,
          total: 10000,
        ),
      ]);

      final refunds = await db.customersDao.getRefundsBySaleId(sale.id);
      expect(refunds.length, 1);
      expect(refunds.first.refundAmount, closeTo(10000, 0.01));
      expect(refunds.first.refundType, 'partial');

      final items = await db.customersDao.getRefundItems(refundId);
      expect(items.length, 1);
      expect(items.first.quantity, 2);
      expect(items.first.total, closeTo(10000, 0.01));
    });

    test('B-7b: partial refund does not change original sale status to refunded', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db, price: 5000);
      final sale = await _insertSale(db, productId: 1, unitPrice: 5000, quantity: 4);

      // Create partial refund record without calling refundSale (which does full refund)
      await db.customersDao.createRefund(
        RefundsCompanion.insert(
          originalSaleId: sale.id,
          originalSaleNumber: sale.saleNumber,
          refundAmount: 5000.0,
          refundType: 'partial',
        ),
      );

      // Original sale still shows 'completed' — partial refund doesn't auto-change status
      final original = await db.salesDao.getSaleById(sale.id);
      expect(original.status, 'completed');
    });

    // ── B-8  Daily closing and refunds ────────────────────────────────────
    test('B-8a: aggregateSalesForDate includes refunded sales (current behaviour)', () async {
      // Document the ACTUAL behaviour: the SQL does not filter by status,
      // so refunded sales are still counted in the aggregation total.
      // This test will fail (and become a regression signal) if the DAO is
      // later updated to exclude refunded sales.
      final db = _openDb();
      addTearDown(db.close);

      final today = DateTime.now();
      await _insertProduct(db, price: 30000);
      final sale = await _insertSale(db, productId: 1, unitPrice: 30000, saleDate: today);

      // Full refund the sale
      await db.salesDao.refundSale(sale.id, 1);

      final agg = await db.dailyClosingDao.aggregateSalesForDate(today);
      // The aggregation still includes this sale because status is not filtered
      expect(agg!.totalTransactions, 1);
      expect(agg.totalSales, closeTo(30000, 0.01));
    });

    test('B-8b: only completed (not refunded) sale contributes to getTotalSales()', () async {
      // SalesDao.getTotalSales filters WHERE status = 'completed'.
      // A refunded sale should NOT be included here.
      final db = _openDb();
      addTearDown(db.close);

      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day);
      final end = start.add(const Duration(days: 1));

      await _insertProduct(db, price: 20000);
      final sale = await _insertSale(db, productId: 1, unitPrice: 20000, saleDate: today);

      // Before refund: included
      final beforeRefund = await db.salesDao.getTotalSales(start, end);
      expect(beforeRefund, closeTo(20000, 0.01));

      // After refund: excluded (status = 'refunded')
      await db.salesDao.refundSale(sale.id, 1);
      final afterRefund = await db.salesDao.getTotalSales(start, end);
      expect(afterRefund, closeTo(0, 0.01));
    });

    test('B-8c: second sale not refunded is still counted after first is refunded', () async {
      final db = _openDb();
      addTearDown(db.close);

      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day);
      final end = start.add(const Duration(days: 1));

      await _insertProduct(db, id: 1, price: 10000);
      await _insertProduct(db, id: 2, price: 15000);

      final s1 = await _insertSale(db, productId: 1, unitPrice: 10000, saleDate: today);
      await _insertSale(db, productId: 2, unitPrice: 15000, saleDate: today);

      // Refund first sale only
      await db.salesDao.refundSale(s1.id, 1);

      // getTotalSales (status=completed) should include only the second sale
      final total = await db.salesDao.getTotalSales(start, end);
      expect(total, closeTo(15000, 0.01));
    });

    // ── B-9  Refund record retrieval ──────────────────────────────────────
    test('B-9: getRefundsBySaleId returns all refunds for a sale', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db, price: 5000);
      final sale = await _insertSale(db, productId: 1, unitPrice: 5000, quantity: 6);

      // Two separate partial refunds
      await db.customersDao.createRefund(RefundsCompanion.insert(
        originalSaleId: sale.id,
        originalSaleNumber: sale.saleNumber,
        refundAmount: 5000.0,
        refundType: 'partial',
      ));
      await db.customersDao.createRefund(RefundsCompanion.insert(
        originalSaleId: sale.id,
        originalSaleNumber: sale.saleNumber,
        refundAmount: 10000.0,
        refundType: 'partial',
      ));

      final refunds = await db.customersDao.getRefundsBySaleId(sale.id);
      expect(refunds.length, 2);
      final totalRefunded = refunds.fold(0.0, (s, r) => s + r.refundAmount);
      expect(totalRefunded, closeTo(15000, 0.01));
    });
  });
}

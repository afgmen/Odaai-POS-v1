import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';

// ---------------------------------------------------------------------------
// T-2: Table merge discount logic
// When two sales are merged, the UI chooses which discount to keep.
// This test verifies that updating the current sale's discount to
// chosenDiscount produces the correct totals.
// ---------------------------------------------------------------------------

AppDatabase _openDb() => AppDatabase.forTesting(NativeDatabase.memory());

int _saleCounter = 0;

Future<int> _insertProduct(AppDatabase db, {int id = 1, double price = 10000}) async {
  await db.customStatement(
    'INSERT OR REPLACE INTO products '
    '(id, sku, name, price, cost, stock, min_stock, is_active, needs_sync, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, 100, 5, 1, 0, ?, ?)',
    [
      id,
      'SKU-$id',
      'Product-$id',
      price,
      price * 0.5,
      DateTime.now().millisecondsSinceEpoch,
      DateTime.now().millisecondsSinceEpoch,
    ],
  );
  return id;
}

/// Creates a sale with the given subtotal, tax, and discount.
/// total = subtotal - discount + tax.
Future<Sale> _insertSale(
  AppDatabase db, {
  required double subtotal,
  double tax = 0,
  double discount = 0,
}) async {
  final total = subtotal - discount + tax;
  final sale = await db.salesDao.createSale(
    sale: SalesCompanion.insert(
      saleNumber: 'SN-MERGE-${++_saleCounter}',
      subtotal: Value(subtotal),
      tax: Value(tax),
      discount: Value(discount),
      total: Value(total),
      paymentMethod: 'CASH',
      status: const Value('open'),
    ),
    items: [],
    createKitchenOrder: false,
  );
  return sale;
}

/// Simulate the merge by applying chosenDiscount to currentSale and
/// returning the updated sale row.
Future<Sale> _applyMergeDiscount(
  AppDatabase db, {
  required Sale currentSale,
  required Sale targetSale,
  required double chosenDiscount,
}) async {
  final newSubtotal = currentSale.subtotal + targetSale.subtotal;
  final newTax = currentSale.tax + targetSale.tax;
  final newTotal = newSubtotal - chosenDiscount + newTax;

  await (db.update(db.sales)..where((s) => s.id.equals(currentSale.id))).write(
    SalesCompanion(
      subtotal: Value(newSubtotal),
      tax: Value(newTax),
      discount: Value(chosenDiscount),
      total: Value(newTotal),
    ),
  );

  return (db.select(db.sales)..where((s) => s.id.equals(currentSale.id)))
      .getSingle();
}

void main() {
  group('T-2: Table merge discount logic', () {
    // ── Test A: both have discounts, choose currentDiscount ──────────
    test('A: both sales have discounts — choose currentDiscount', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db);
      final current = await _insertSale(db, subtotal: 50000, discount: 5000);
      final target = await _insertSale(db, subtotal: 40000, discount: 4000);

      final chosenDiscount = current.discount; // 5000
      final merged = await _applyMergeDiscount(
        db,
        currentSale: current,
        targetSale: target,
        chosenDiscount: chosenDiscount,
      );

      expect(merged.discount, closeTo(5000, 0.01));
      expect(merged.subtotal, closeTo(90000, 0.01));
      // total = 90000 - 5000 + 0 = 85000
      expect(merged.total,
          closeTo(merged.subtotal - merged.discount + merged.tax, 0.01));
    });

    // ── Test B: both have discounts, choose targetDiscount ───────────
    test('B: both sales have discounts — choose targetDiscount', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db);
      final current = await _insertSale(db, subtotal: 50000, discount: 5000);
      final target = await _insertSale(db, subtotal: 40000, discount: 4000);

      final chosenDiscount = target.discount; // 4000
      final merged = await _applyMergeDiscount(
        db,
        currentSale: current,
        targetSale: target,
        chosenDiscount: chosenDiscount,
      );

      expect(merged.discount, closeTo(4000, 0.01));
      expect(merged.subtotal, closeTo(90000, 0.01));
      expect(merged.total,
          closeTo(merged.subtotal - merged.discount + merged.tax, 0.01));
    });

    // ── Test C: both have discounts, choose 0 (no promo) ────────────
    test('C: both sales have discounts — choose 0 (no promo)', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db);
      final current = await _insertSale(db, subtotal: 50000, discount: 5000);
      final target = await _insertSale(db, subtotal: 40000, discount: 4000);

      const chosenDiscount = 0.0;
      final merged = await _applyMergeDiscount(
        db,
        currentSale: current,
        targetSale: target,
        chosenDiscount: chosenDiscount,
      );

      expect(merged.discount, closeTo(0, 0.01));
      expect(merged.subtotal, closeTo(90000, 0.01));
      // total = 90000 - 0 + 0 = 90000
      expect(merged.total, closeTo(90000, 0.01));
      expect(merged.total,
          closeTo(merged.subtotal - merged.discount + merged.tax, 0.01));
    });

    // ── Test D: only one sale has a discount ─────────────────────────
    test('D: only current sale has a discount — merged sale keeps that discount', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db);
      final current = await _insertSale(db, subtotal: 60000, discount: 6000);
      final target = await _insertSale(db, subtotal: 30000, discount: 0);

      // The UI would present the only non-zero discount as the chosen one
      final chosenDiscount = current.discount; // 6000
      final merged = await _applyMergeDiscount(
        db,
        currentSale: current,
        targetSale: target,
        chosenDiscount: chosenDiscount,
      );

      expect(merged.discount, closeTo(6000, 0.01));
      expect(merged.subtotal, closeTo(90000, 0.01));
      expect(merged.total,
          closeTo(merged.subtotal - merged.discount + merged.tax, 0.01));
    });

    // ── Test E: neither sale has a discount ──────────────────────────
    test('E: neither sale has a discount — merged sale discount is 0', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db);
      final current = await _insertSale(db, subtotal: 45000, discount: 0);
      final target = await _insertSale(db, subtotal: 35000, discount: 0);

      const chosenDiscount = 0.0;
      final merged = await _applyMergeDiscount(
        db,
        currentSale: current,
        targetSale: target,
        chosenDiscount: chosenDiscount,
      );

      expect(merged.discount, closeTo(0, 0.01));
      expect(merged.subtotal, closeTo(80000, 0.01));
      expect(merged.total, closeTo(80000, 0.01));
      expect(merged.total,
          closeTo(merged.subtotal - merged.discount + merged.tax, 0.01));
    });

    // ── Test F: total formula holds with non-zero tax ─────────────────
    test('F: total formula newTotal = newSubtotal - chosenDiscount + newTax holds with tax', () async {
      final db = _openDb();
      addTearDown(db.close);

      await _insertProduct(db);
      final current = await _insertSale(db, subtotal: 50000, tax: 5000, discount: 5000);
      final target = await _insertSale(db, subtotal: 30000, tax: 3000, discount: 0);

      final chosenDiscount = current.discount; // 5000
      final merged = await _applyMergeDiscount(
        db,
        currentSale: current,
        targetSale: target,
        chosenDiscount: chosenDiscount,
      );

      // newSubtotal=80000, newTax=8000, chosenDiscount=5000
      // newTotal = 80000 - 5000 + 8000 = 83000
      expect(merged.subtotal, closeTo(80000, 0.01));
      expect(merged.tax, closeTo(8000, 0.01));
      expect(merged.discount, closeTo(5000, 0.01));
      expect(merged.total, closeTo(83000, 0.01));
      expect(
        merged.total,
        closeTo(merged.subtotal - merged.discount + merged.tax, 0.01),
        reason: 'total must equal subtotal - discount + tax',
      );
    });
  });
}

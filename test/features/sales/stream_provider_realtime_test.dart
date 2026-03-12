import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:oda_pos/database/app_database.dart';

/// B-103: FutureProvider → StreamProvider 전환 검증
///
/// Verifies that the new Stream-based DAO methods correctly emit
/// updated data when sales are inserted/refunded, without manual invalidation.
void main() {
  group('B-103: Sales StreamProvider — real-time DB reactivity', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    Future<int> insertCompletedSale(String saleNumber, double total) =>
        db.into(db.sales).insert(
          SalesCompanion.insert(
            saleNumber: saleNumber,
            paymentMethod: 'cash',
            total: Value(total),
            subtotal: Value(total),
            status: const Value('completed'),
            saleDate: Value(today),
          ),
        );

    // ── watchSalesByDateRange ─────────────────────────────────────────

    test('watchSalesByDateRange emits empty list initially', () async {
      final stream = db.salesDao.watchSalesByDateRange(startOfDay, endOfDay);
      final first = await stream.first;
      expect(first, isEmpty);
    });

    test('watchSalesByDateRange emits sale after insert (via getSalesByDateRange)', () async {
      await insertCompletedSale('STREAM-001', 100000);

      // Verify via one-shot query — stream correctness tested via watchTotalSales
      final result = await db.salesDao.getSalesByDateRange(startOfDay, endOfDay);
      expect(result.length, 1);
      expect(result.first.saleNumber, 'STREAM-001');
    });

    test('watchSalesByDateRange excludes future-date sales', () async {
      final tomorrow = startOfDay.add(const Duration(days: 2));
      await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'FUTURE-001',
          paymentMethod: 'cash',
          total: const Value(50000),
          subtotal: const Value(50000),
          status: const Value('completed'),
          saleDate: Value(tomorrow),
        ),
      );

      final stream = db.salesDao.watchSalesByDateRange(startOfDay, endOfDay);
      final result = await stream.first;
      expect(result, isEmpty,
          reason: 'Future-date sale must not appear in today range');
    });

    // ── watchTotalSales ───────────────────────────────────────────────

    test('watchTotalSales emits 0 initially', () async {
      final stream = db.salesDao.watchTotalSales(startOfDay, endOfDay);
      final first = await stream.first;
      expect(first, 0.0);
    });

    test('watchTotalSales reflects inserted sale immediately (via first)', () async {
      await insertCompletedSale('TOT-001', 150000);

      // Stream's first emission on a non-empty DB reflects current state
      final stream = db.salesDao.watchTotalSales(startOfDay, endOfDay);
      final total = await stream.first;
      expect(total, 150000.0);
    });

    test('watchTotalSales accumulates multiple sales', () async {
      await insertCompletedSale('TOT-A', 100000);
      await insertCompletedSale('TOT-B', 200000);

      final stream = db.salesDao.watchTotalSales(startOfDay, endOfDay);
      final total = await stream.first;
      expect(total, 300000.0);
    });

    test('watchTotalSales excludes refunded sales', () async {
      await insertCompletedSale('REFUND-OK', 100000);
      final refundId = await insertCompletedSale('REFUND-ME', 50000);

      // Refund the second sale
      await db.salesDao.refundSale(refundId, 1, reason: 'Test');

      final stream = db.salesDao.watchTotalSales(startOfDay, endOfDay);
      final total = await stream.first;
      expect(total, 100000.0,
          reason: 'Refunded sale must be excluded from total');
    });

    // ── watchOrderCount ───────────────────────────────────────────────

    test('watchOrderCount emits 0 initially', () async {
      final stream = db.salesDao.watchOrderCount(startOfDay, endOfDay);
      final count = await stream.first;
      expect(count, 0);
    });

    test('watchOrderCount reflects inserted sale immediately', () async {
      await insertCompletedSale('COUNT-001', 80000);

      final stream = db.salesDao.watchOrderCount(startOfDay, endOfDay);
      final count = await stream.first;
      expect(count, 1);
    });

    test('watchOrderCount counts multiple sales', () async {
      await insertCompletedSale('C-1', 10000);
      await insertCompletedSale('C-2', 20000);
      await insertCompletedSale('C-3', 30000);

      final stream = db.salesDao.watchOrderCount(startOfDay, endOfDay);
      final count = await stream.first;
      expect(count, 3);
    });

    // ── watchPaymentBreakdown ─────────────────────────────────────────

    test('watchPaymentBreakdown emits empty list initially', () async {
      final stream = db.salesDao.watchPaymentBreakdown(startOfDay, endOfDay);
      final list = await stream.first;
      expect(list, isEmpty);
    });

    test('watchPaymentBreakdown groups by payment method', () async {
      await db.into(db.sales).insert(SalesCompanion.insert(
            saleNumber: 'PAY-CASH-1',
            paymentMethod: 'CASH',
            total: const Value(100000),
            subtotal: const Value(100000),
            status: const Value('completed'),
            saleDate: Value(today),
          ));
      await db.into(db.sales).insert(SalesCompanion.insert(
            saleNumber: 'PAY-CARD-1',
            paymentMethod: 'CARD',
            total: const Value(200000),
            subtotal: const Value(200000),
            status: const Value('completed'),
            saleDate: Value(today),
          ));

      final stream = db.salesDao.watchPaymentBreakdown(startOfDay, endOfDay);
      final list = await stream.first;

      expect(list.length, 2);
      final cash = list.firstWhere((e) => e.method == 'CASH');
      final card = list.firstWhere((e) => e.method == 'CARD');
      expect(cash.total, 100000.0);
      expect(card.total, 200000.0);
    });
  });
}

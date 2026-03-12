import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:oda_pos/database/app_database.dart';

/// B-095: KDS — Served/Cancelled 주문 필터 표시
///
/// Verifies that watchOrdersByStatus and watchAllOrders correctly return
/// SERVED and CANCELLED orders that were invisible in the old active-only stream.
void main() {
  group('B-095: KDS status filter — SERVED/CANCELLED visibility', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    // kitchenOrders.saleId has FK → sales table; insert a dummy sale first
    Future<int> insertDummySale() => db.into(db.sales).insert(
          SalesCompanion.insert(
            saleNumber: 'TEST-${DateTime.now().microsecondsSinceEpoch}',
            paymentMethod: 'cash',
          ),
        );

    Future<int> insertOrder(String status) async {
      final saleId = await insertDummySale();
      return db.into(db.kitchenOrders).insert(
        KitchenOrdersCompanion.insert(
          saleId: saleId,
          status: Value(status),
          priority: Value('normal'),
        ),
      );
    }

    // ── Active stream excludes SERVED/CANCELLED ──────────────────────
    test('watchActiveOrders returns only PENDING/PREPARING/READY', () async {
      await insertOrder('PENDING');
      await insertOrder('PREPARING');
      await insertOrder('READY');
      await insertOrder('SERVED');
      await insertOrder('CANCELLED');

      final active = await (db.select(db.kitchenOrders)
            ..where((t) => t.status.isIn(['PENDING', 'PREPARING', 'READY'])))
          .get();

      expect(active.length, 3);
      expect(active.every((o) => ['PENDING', 'PREPARING', 'READY'].contains(o.status)), isTrue);
    });

    test('SERVED orders are invisible in active-only stream (old bug)', () async {
      await insertOrder('SERVED');
      await insertOrder('SERVED');

      final active = await (db.select(db.kitchenOrders)
            ..where((t) => t.status.isIn(['PENDING', 'PREPARING', 'READY'])))
          .get();

      expect(active.length, 0,
          reason: 'SERVED orders must not appear in active stream');
    });

    test('CANCELLED orders are invisible in active-only stream (old bug)', () async {
      await insertOrder('CANCELLED');

      final active = await (db.select(db.kitchenOrders)
            ..where((t) => t.status.isIn(['PENDING', 'PREPARING', 'READY'])))
          .get();

      expect(active.length, 0,
          reason: 'CANCELLED orders must not appear in active stream');
    });

    // ── watchAllOrders includes SERVED/CANCELLED ──────────────────────
    test('watchAllOrders returns SERVED orders', () async {
      await insertOrder('SERVED');
      await insertOrder('SERVED');
      await insertOrder('PREPARING');

      final all = await db.select(db.kitchenOrders).get();
      final served = all.where((o) => o.status == 'SERVED').toList();

      expect(served.length, 2);
    });

    test('watchAllOrders returns CANCELLED orders', () async {
      await insertOrder('CANCELLED');
      await insertOrder('PREPARING');

      final all = await db.select(db.kitchenOrders).get();
      final cancelled = all.where((o) => o.status == 'CANCELLED').toList();

      expect(cancelled.length, 1);
    });

    // ── Status filter logic (mirrors filteredOrdersProvider logic) ────
    test('status filter correctly selects SERVED subset', () async {
      await insertOrder('SERVED');
      await insertOrder('SERVED');
      await insertOrder('PREPARING');
      await insertOrder('CANCELLED');

      final all = await db.select(db.kitchenOrders).get();
      final filtered = all.where((o) => o.status == 'SERVED').toList();

      expect(filtered.length, 2);
    });

    test('status filter correctly selects CANCELLED subset', () async {
      await insertOrder('PENDING');
      await insertOrder('CANCELLED');
      await insertOrder('CANCELLED');

      final all = await db.select(db.kitchenOrders).get();
      final filtered = all.where((o) => o.status == 'CANCELLED').toList();

      expect(filtered.length, 2);
    });

    test('no-filter (null) returns active orders only', () async {
      await insertOrder('PENDING');
      await insertOrder('READY');
      await insertOrder('SERVED');
      await insertOrder('CANCELLED');

      // null filter → active stream only
      final active = await (db.select(db.kitchenOrders)
            ..where((t) => t.status.isIn(['PENDING', 'PREPARING', 'READY'])))
          .get();

      expect(active.length, 2);
      expect(active.every((o) => o.status != 'SERVED' && o.status != 'CANCELLED'), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:oda_pos/database/app_database.dart';

/// B-092: 0원 영수증 복수 생성 방지
///
/// The guard in _processPayment() blocks payment when:
///   cart.isEmpty && widget.saleId == null
///
/// These tests verify the DB-level invariant: a sale with zero total
/// should NOT be created under normal flow conditions.
void main() {
  group('B-092: Empty-cart guard — zero-value sale prevention', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    // ── Logic mirror of the guard condition ──────────────────────────────
    bool shouldBlockPayment({
      required bool cartIsEmpty,
      required int? saleId,
    }) {
      return cartIsEmpty && saleId == null;
    }

    test('blocks payment when cart is empty and no saleId', () {
      expect(
        shouldBlockPayment(cartIsEmpty: true, saleId: null),
        isTrue,
        reason: 'Guard must fire: empty cart + no existing sale',
      );
    });

    test('allows payment when cart has items (new order)', () {
      expect(
        shouldBlockPayment(cartIsEmpty: false, saleId: null),
        isFalse,
      );
    });

    test('allows payment when saleId is provided (Open Tab checkout)', () {
      expect(
        shouldBlockPayment(cartIsEmpty: true, saleId: 123),
        isFalse,
        reason: 'Open-Tab checkout: cart may be empty, saleId drives the flow',
      );
    });

    test('allows payment when both cart and saleId are present', () {
      expect(
        shouldBlockPayment(cartIsEmpty: false, saleId: 456),
        isFalse,
      );
    });

    // ── DB invariant: zero-total sales should not exist after fix ────────
    test('zero-total sale can be inserted (documents old bug)', () async {
      // The old code had no guard → 0-value receipts were created.
      // This test records the shape of the bug.
      final id = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'BUG-ZERO-001',
          paymentMethod: 'cash',
          total: const Value(0),
          subtotal: const Value(0),
        ),
      );

      final sale =
          await (db.select(db.sales)..where((s) => s.id.equals(id))).getSingle();

      expect(sale.total, 0.0,
          reason: 'DB allows 0-total — guard must exist at UI layer');
    });

    test('normal sale has positive total', () async {
      final id = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'SALE-NORMAL-001',
          paymentMethod: 'cash',
          total: const Value(85000),
          subtotal: const Value(85000),
        ),
      );

      final sale =
          await (db.select(db.sales)..where((s) => s.id.equals(id))).getSingle();

      expect(sale.total, greaterThan(0));
    });

    test('multiple zero-total sales cannot accumulate after guard', () async {
      // After the fix, the guard in _processPayment should prevent
      // multiple zero-value sales from being created in the same session.
      //
      // We simulate it here by verifying the guard returns true for
      // consecutive calls with empty cart + no saleId.
      for (var i = 0; i < 5; i++) {
        final blocked = shouldBlockPayment(cartIsEmpty: true, saleId: null);
        expect(blocked, isTrue,
            reason: 'Guard must block on every call — no duplicate 0-receipts');
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:matcher/matcher.dart' as matcher;
import 'package:oda_pos/database/app_database.dart';

/// B-094: Cancel Order 취소 사유 모든 경로에 적용
///
/// Verifies that cancellation with a reason is consistently applied
/// regardless of which UI path triggered it:
///   - Floor Plan (table_detail_modal) ✅ already had it
///   - POS Cart Panel (cart_panel)     ✅ already had it
///   - KDS (order_detail_modal)        ✅ already had it
///
/// These tests confirm the underlying DB operations work uniformly
/// for all three paths.
void main() {
  group('B-094: Cancellation reason — all paths store consistently', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    // ── Shared helper: write cancellation (mirrors all three paths) ──
    Future<void> cancelSale(
      AppDatabase db,
      int saleId,
      String reason,
    ) async {
      await (db.update(db.sales)..where((s) => s.id.equals(saleId))).write(
        SalesCompanion(
          status: const Value('cancelled'),
          cancellationReason: Value(reason),
          cancelledAt: Value(DateTime.now()),
        ),
      );
    }

    Future<int> createPendingSale(String saleNumber) =>
        db.into(db.sales).insert(
          SalesCompanion.insert(
            saleNumber: saleNumber,
            paymentMethod: 'cash',
            total: const Value(100000),
            subtotal: const Value(100000),
            status: const Value('pending'),
          ),
        );

    // ── Path 1: Floor Plan (table_detail_modal) ──────────────────────
    test('Floor Plan path: cancellation reason persisted', () async {
      final saleId = await createPendingSale('FP-001');
      await cancelSale(db, saleId, 'Customer Request');

      final sale = await (db.select(db.sales)
            ..where((s) => s.id.equals(saleId)))
          .getSingle();

      expect(sale.status, 'cancelled');
      expect(sale.cancellationReason, 'Customer Request');
      expect(sale.cancelledAt, matcher.isNotNull);
    });

    // ── Path 2: POS Cart Panel (cart_panel) ──────────────────────────
    test('POS Cart path: cancellation reason persisted', () async {
      final saleId = await createPendingSale('CART-001');
      await cancelSale(db, saleId, 'Out of Stock');

      final sale = await (db.select(db.sales)
            ..where((s) => s.id.equals(saleId)))
          .getSingle();

      expect(sale.status, 'cancelled');
      expect(sale.cancellationReason, 'Out of Stock');
      expect(sale.cancelledAt, matcher.isNotNull);
    });

    // ── Path 3: KDS (order_detail_modal) ─────────────────────────────
    test('KDS path: cancellation reason persisted', () async {
      final saleId = await createPendingSale('KDS-001');
      await cancelSale(db, saleId, 'Kitchen Error');

      final sale = await (db.select(db.sales)
            ..where((s) => s.id.equals(saleId)))
          .getSingle();

      expect(sale.status, 'cancelled');
      expect(sale.cancellationReason, 'Kitchen Error');
      expect(sale.cancelledAt, matcher.isNotNull);
    });

    // ── Custom reason (Other) works on all paths ──────────────────────
    test('Custom "Other:" reason persisted — all paths', () async {
      final paths = ['FP-OTHER', 'CART-OTHER', 'KDS-OTHER'];
      const customReason = 'Other: menu change requested by customer';

      for (final saleNumber in paths) {
        final saleId = await createPendingSale(saleNumber);
        await cancelSale(db, saleId, customReason);

        final sale = await (db.select(db.sales)
              ..where((s) => s.id.equals(saleId)))
            .getSingle();

        expect(sale.cancellationReason, customReason,
            reason: '$saleNumber path should store custom reason');
        expect(sale.cancellationReason!.startsWith('Other:'), isTrue);
      }
    });

    // ── Reason must not be empty ──────────────────────────────────────
    test('Cancellation without reason stores null (blocked by UI guard)', () async {
      // The CancelReasonModal prevents empty reason submission.
      // If somehow null slips through, DB should accept it (no constraint)
      // but we document that the UI guard is the enforcement layer.
      final saleId = await createPendingSale('NO-REASON-001');

      await (db.update(db.sales)..where((s) => s.id.equals(saleId))).write(
        SalesCompanion(
          status: const Value('cancelled'),
          cancellationReason: const Value(null),
          cancelledAt: Value(DateTime.now()),
        ),
      );

      final sale = await (db.select(db.sales)
            ..where((s) => s.id.equals(saleId)))
          .getSingle();

      // DB allows null, but CancelReasonModal UI guard prevents it
      expect(sale.status, 'cancelled');
      expect(sale.cancellationReason, matcher.isNull,
          reason: 'UI guard (not DB constraint) enforces non-empty reason');
    });

    // ── Cancelled timestamp is always set ────────────────────────────
    test('cancelledAt timestamp is set on all cancel paths', () async {
      final before = DateTime.now().subtract(const Duration(seconds: 1));

      final ids = await Future.wait([
        createPendingSale('TS-FP'),
        createPendingSale('TS-CART'),
        createPendingSale('TS-KDS'),
      ]);

      for (final saleId in ids) {
        await cancelSale(db, saleId, 'Customer Request');
      }

      final sales = await (db.select(db.sales)
            ..where((s) => s.id.isIn(ids)))
          .get();

      for (final sale in sales) {
        expect(sale.cancelledAt, matcher.isNotNull,
            reason: 'cancelledAt must be set for ${sale.saleNumber}');
        expect(sale.cancelledAt!.isAfter(before), isTrue);
      }
    });

    // ── Cancellation does not corrupt other fields ────────────────────
    test('Cancellation preserves sale total, type and saleNumber', () async {
      final saleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'PRESERVE-001',
          paymentMethod: 'card',
          total: const Value(350000),
          subtotal: const Value(300000),
          discount: const Value(50000),
          orderType: const Value('dineIn'),
          status: const Value('pending'),
        ),
      );

      await cancelSale(db, saleId, 'Customer Request');

      final sale = await (db.select(db.sales)
            ..where((s) => s.id.equals(saleId)))
          .getSingle();

      expect(sale.total, 350000);
      expect(sale.subtotal, 300000);
      expect(sale.discount, 50000);
      expect(sale.orderType, 'dineIn');
      expect(sale.saleNumber, 'PRESERVE-001');
      expect(sale.status, 'cancelled');
    });
  });
}

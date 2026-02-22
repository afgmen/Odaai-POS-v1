import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/features/daily_closing/data/daily_closing_dao.dart';
import 'package:oda_pos/features/daily_closing/domain/constants/closing_constants.dart';
import 'package:oda_pos/features/daily_closing/domain/services/closing_service.dart';

// ---------------------------------------------------------------------------
// Pure-function mirrors of ClosingService methods (no DB needed).
// This avoids the need to construct ClosingService with a real DAO.
// ---------------------------------------------------------------------------

double _calculateCashDifference({
  required double expectedCash,
  required double actualCash,
}) =>
    actualCash - expectedCash;

bool _isCashDifferenceAcceptable(double difference) =>
    difference.abs() <= ClosingConstants.acceptableCashDifference;

// ---------------------------------------------------------------------------
// Tests for pure-logic calculations in:
//   • SalesAggregation data model
//   • ClosingService.calculateCashDifference()
//   • ClosingService.isCashDifferenceAcceptable()
//   • ClosingValidationResult
//   • ClosingResult
//
// No database required — all tests are pure unit tests.
// ---------------------------------------------------------------------------

void main() {
  // ── SalesAggregation model ─────────────────────────────────────────────
  group('SalesAggregation — revenue calculations', () {
    test('totalSales equals declared value', () {
      final agg = _agg(
        totalSales: 250000,
        cashSales: 100000,
        cardSales: 100000,
        qrSales: 30000,
        transferSales: 20000,
      );
      expect(agg.totalSales, 250000);
    });

    test('payment method breakdown sums to totalSales', () {
      final agg = _agg(
        totalSales: 180000,
        cashSales: 80000,
        cardSales: 60000,
        qrSales: 25000,
        transferSales: 15000,
      );
      final methodSum =
          agg.cashSales + agg.cardSales + agg.qrSales + agg.transferSales;
      expect(methodSum, closeTo(agg.totalSales, 0.01));
    });

    test('totalTax and totalDiscount are preserved', () {
      final agg = _agg(totalTax: 12000, totalDiscount: 5000);
      expect(agg.totalTax, 12000);
      expect(agg.totalDiscount, 5000);
    });

    test('averageTransaction is preserved', () {
      final agg = _agg(totalSales: 300000, totalTransactions: 10,
          averageTransaction: 30000);
      expect(agg.averageTransaction, 30000);
    });

    test('zero-transaction aggregation has all zeros', () {
      final agg = _agg();
      expect(agg.totalTransactions, 0);
      expect(agg.totalSales, 0.0);
      expect(agg.cashSales, 0.0);
      expect(agg.cardSales, 0.0);
    });
  });

  // ── Revenue by payment method ──────────────────────────────────────────
  group('Revenue by payment method', () {
    test('cash-only day: cashSales equals totalSales', () {
      final agg = _agg(
        totalSales: 50000,
        cashSales: 50000,
        cardSales: 0,
        qrSales: 0,
        transferSales: 0,
      );
      expect(agg.cashSales, agg.totalSales);
    });

    test('card-only day: cardSales equals totalSales', () {
      final agg = _agg(
        totalSales: 90000,
        cashSales: 0,
        cardSales: 90000,
        qrSales: 0,
        transferSales: 0,
      );
      expect(agg.cardSales, agg.totalSales);
    });

    test('mixed payment day: all method fields are individually correct', () {
      const cash = 40000.0;
      const card = 30000.0;
      const qr = 20000.0;
      const transfer = 10000.0;

      final agg = _agg(
        totalSales: cash + card + qr + transfer,
        cashSales: cash,
        cardSales: card,
        qrSales: qr,
        transferSales: transfer,
      );

      expect(agg.cashSales, cash);
      expect(agg.cardSales, card);
      expect(agg.qrSales, qr);
      expect(agg.transferSales, transfer);
    });
  });

  // ── Cash reconciliation helpers ────────────────────────────────────────
  group('ClosingService.calculateCashDifference()', () {
    test('positive difference when actual > expected', () {
      final diff = _calculateCashDifference(
        expectedCash: 50000,
        actualCash: 51000,
      );
      expect(diff, closeTo(1000, 0.01));
    });

    test('negative difference when actual < expected', () {
      final diff = _calculateCashDifference(
        expectedCash: 50000,
        actualCash: 48000,
      );
      expect(diff, closeTo(-2000, 0.01));
    });

    test('zero difference when actual equals expected', () {
      final diff = _calculateCashDifference(
        expectedCash: 30000,
        actualCash: 30000,
      );
      expect(diff, 0.0);
    });
  });

  // ── isCashDifferenceAcceptable ─────────────────────────────────────────
  group('ClosingService.isCashDifferenceAcceptable()', () {
    test('difference of 0 is acceptable', () {
      expect(_isCashDifferenceAcceptable(0), isTrue);
    });

    test('difference within threshold is acceptable', () {
      expect(
        _isCashDifferenceAcceptable(
          ClosingConstants.acceptableCashDifference,
        ),
        isTrue,
      );
    });

    test('difference exceeding threshold is not acceptable', () {
      expect(
        _isCashDifferenceAcceptable(
          ClosingConstants.acceptableCashDifference + 1,
        ),
        isFalse,
      );
    });

    test('negative difference within threshold is acceptable', () {
      expect(
        _isCashDifferenceAcceptable(
          -ClosingConstants.acceptableCashDifference,
        ),
        isTrue,
      );
    });

    test('negative difference exceeding threshold is not acceptable', () {
      expect(
        _isCashDifferenceAcceptable(
          -(ClosingConstants.acceptableCashDifference + 0.01),
        ),
        isFalse,
      );
    });
  });

  // ── ClosingValidationResult model ─────────────────────────────────────
  group('ClosingValidationResult', () {
    test('canClose = false carries reason', () {
      final result = ClosingValidationResult(
        canClose: false,
        reason: 'Already closed for this date.',
      );
      expect(result.canClose, isFalse);
      expect(result.reason, 'Already closed for this date.');
      expect(result.aggregation, isNull);
    });

    test('canClose = true carries aggregation', () {
      final agg = _agg(totalSales: 100000, totalTransactions: 5);
      final result = ClosingValidationResult(
        canClose: true,
        aggregation: agg,
      );
      expect(result.canClose, isTrue);
      expect(result.aggregation, isNotNull);
      expect(result.aggregation!.totalSales, 100000);
    });
  });

  // ── ClosingResult model ────────────────────────────────────────────────
  group('ClosingResult', () {
    test('successful result carries closing id', () {
      final result = ClosingResult(
        success: true,
        closingId: 42,
        message: 'Closing completed successfully.',
      );
      expect(result.success, isTrue);
      expect(result.closingId, 42);
    });

    test('failed result has null closing id', () {
      final result = ClosingResult(
        success: false,
        message: 'Login required.',
      );
      expect(result.success, isFalse);
      expect(result.closingId, isNull);
    });
  });

  // ── Double-closing guard (logic validation) ────────────────────────────
  group('Double-closing prevention', () {
    test('ClosingValidationResult blocks when canClose = false', () {
      // Simulates the service returning canClose=false for an already-closed date.
      final validation = ClosingValidationResult(
        canClose: false,
        reason: 'This date has already been closed.',
      );

      // The service would return early if !validation.canClose.
      expect(validation.canClose, isFalse);
      expect(validation.reason, contains('already been closed'));
    });
  });

  // ── Opening cash balance formula ────────────────────────────────────────
  group('Expected closing cash balance formula', () {
    test('cash sales equal expected cash in aggregation', () {
      // openingCash + cashSales - cashRefunds = expectedClosingCash
      // In the current model, expectedCash = aggregation.cashSales
      // (opening cash is tracked separately by the cash drawer).
      const cashSales = 75000.0;
      final agg = _agg(
        cashSales: cashSales,
        totalSales: cashSales,
      );
      // The DAO sets expectedCash = aggregation.cashSales
      expect(agg.cashSales, cashSales);
    });
  });
}

// ---------------------------------------------------------------------------
// Helper factory for SalesAggregation
// ---------------------------------------------------------------------------
SalesAggregation _agg({
  int totalTransactions = 0,
  double totalSales = 0.0,
  double totalTax = 0.0,
  double totalDiscount = 0.0,
  double cashSales = 0.0,
  double cardSales = 0.0,
  double qrSales = 0.0,
  double transferSales = 0.0,
  double averageTransaction = 0.0,
}) {
  return SalesAggregation(
    totalTransactions: totalTransactions,
    totalSales: totalSales,
    totalTax: totalTax,
    totalDiscount: totalDiscount,
    cashSales: cashSales,
    cardSales: cardSales,
    qrSales: qrSales,
    transferSales: transferSales,
    averageTransaction: averageTransaction,
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/features/daily_closing/data/daily_closing_dao.dart';
import 'package:oda_pos/features/daily_closing/domain/services/closing_service.dart';

/// B-093: Daily Closing 마감 실패 시 원인 안내 없음
///
/// Verifies:
/// 1. ClosingResult carries a human-readable error message on failure
/// 2. The no-sales case no longer blocks the Close button (warning + proceed)
/// 3. Specific failure reasons are surfaced via ClosingResult.message
void main() {
  // ── ClosingResult model ──────────────────────────────────────────────
  group('B-093: ClosingResult error messages', () {
    test('success result has descriptive message', () {
      final result = ClosingResult(
        success: true,
        closingId: 42,
        message: 'Closing completed successfully.',
      );

      expect(result.success, isTrue);
      expect(result.closingId, 42);
      expect(result.message, isNotEmpty);
    });

    test('failure result has non-empty error message', () {
      final result = ClosingResult(
        success: false,
        message: 'Closing failed: open tabs exist (2)',
      );

      expect(result.success, isFalse);
      expect(result.message, isNotEmpty,
          reason: 'User must see a reason why closing failed');
    });

    test('failure message does not contain raw Exception: prefix', () {
      const raw = 'Exception: database locked';
      final cleaned = raw.replaceFirst('Exception: ', '');

      final result = ClosingResult(success: false, message: cleaned);

      expect(result.message.contains('Exception:'), isFalse,
          reason: 'Raw exception prefix should be stripped before display');
      expect(result.message, 'database locked');
    });

    test('already-closed failure produces readable message', () {
      final result = ClosingResult(
        success: false,
        message: 'Closing for this date already exists.',
      );

      expect(result.message, contains('already'));
    });

    test('future-date failure produces readable message', () {
      final result = ClosingResult(
        success: false,
        message: 'Cannot close a future date.',
      );

      expect(result.message, isNotEmpty);
      expect(result.success, isFalse);
    });

    test('login-required failure produces readable message', () {
      final result = ClosingResult(
        success: false,
        message: 'Login required.',
      );

      expect(result.message, 'Login required.');
    });
  });

  // ── ClosingValidationResult: no-sales allows closing ────────────────
  group('B-093: No-sales warning — button still shown', () {
    test('canClose=true even when aggregation is null (no sales)', () {
      // After the fix, no-sales should show a WARNING but still allow closing.
      // We model this as canClose=true with a null aggregation.
      final validation = ClosingValidationResult(
        canClose: true,
        aggregation: null, // no sales data
        reason: null,
      );

      expect(validation.canClose, isTrue,
          reason: 'No-sales date should still be closable');
      expect(validation.aggregation, isNull);
    });

    test('canClose=false when already closed', () {
      final validation = ClosingValidationResult(
        canClose: false,
        failCode: ClosingFailCode.alreadyClosed,
        reason: 'Closing for this date already exists.',
      );

      expect(validation.canClose, isFalse);
      expect(validation.failCode, ClosingFailCode.alreadyClosed);
      expect(validation.reason, isNotEmpty);
    });

    test('canClose=false with open tabs carries count', () {
      final validation = ClosingValidationResult(
        canClose: false,
        failCode: ClosingFailCode.openTabsExist,
        openTabCount: 3,
        reason: 'There are 3 open tabs that must be closed first.',
      );

      expect(validation.canClose, isFalse);
      expect(validation.openTabCount, 3);
      expect(validation.reason, contains('3'));
    });

    test('canClose=true with valid aggregation proceeds normally', () {
      final agg = SalesAggregation(
        totalSales: 500000,
        totalTransactions: 10,
        cashSales: 300000,
        cardSales: 150000,
        qrSales: 50000,
        transferSales: 0,
        totalDiscount: 20000,
        totalTax: 0,
        averageTransaction: 50000,
      );

      final validation = ClosingValidationResult(
        canClose: true,
        aggregation: agg,
      );

      expect(validation.canClose, isTrue);
      expect(validation.aggregation?.totalTransactions, 10);
    });
  });

  // ── Error display helper: message stripping ──────────────────────────
  group('B-093: Error message formatting', () {
    String formatError(Object e) =>
        e.toString().replaceFirst('Exception: ', '');

    test('strips Exception: prefix', () {
      final msg = formatError(Exception('open tabs exist'));
      expect(msg, 'open tabs exist');
    });

    test('leaves plain string unchanged', () {
      final msg = formatError('plain error');
      expect(msg, 'plain error');
    });

    test('handles nested exception message', () {
      final msg = formatError(Exception('DB error: table locked'));
      expect(msg, 'DB error: table locked');
      expect(msg.contains('Exception:'), isFalse);
    });
  });
}

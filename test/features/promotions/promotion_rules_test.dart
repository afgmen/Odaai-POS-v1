import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Tests for promotion rule logic, mirroring _calculatePromoDiscount() from
// auto_promotion_provider.dart and the time-gating / stacking logic from
// applicablePromotionsProvider.
//
// We replicate the formulas here to avoid pulling in Riverpod/DB in unit tests.
// ---------------------------------------------------------------------------

// ── Mirrored calculation logic ──────────────────────────────────────────────

/// Calculates the discount for a single promotion applied to a cart item.
/// Mirrors _calculatePromoDiscount() in auto_promotion_provider.dart.
double _calculatePromoDiscount({
  required String type,
  required double promoValue,  // percentage or fixed amount
  required int quantity,
  required double unitPrice,
}) {
  final subtotal = unitPrice * quantity;
  switch (type) {
    case 'buy1get1':
      return (quantity ~/ 2) * unitPrice;
    case 'buy2get1':
      return (quantity ~/ 3) * unitPrice;
    case 'percentOff':
      return subtotal * (promoValue / 100);
    case 'amountOff':
      return promoValue.clamp(0.0, subtotal);
    default:
      return 0.0;
  }
}

/// Returns true if [now] is within [startDate, endDate] (both inclusive / nullable).
bool _isPromoActive({
  required DateTime now,
  DateTime? startDate,
  DateTime? endDate,
}) {
  if (startDate != null && now.isBefore(startDate)) return false;
  if (endDate != null && now.isAfter(endDate)) return false;
  return true;
}

/// Selects the best (highest-discount) promotion from a list.
/// Mirrors the max-discount selection in autoPromotionDiscountProvider.
double _bestDiscount({
  required List<Map<String, dynamic>> promos,
  required int quantity,
  required double unitPrice,
}) {
  double best = 0.0;
  for (final p in promos) {
    final d = _calculatePromoDiscount(
      type: p['type'] as String,
      promoValue: (p['value'] as num).toDouble(),
      quantity: quantity,
      unitPrice: unitPrice,
    );
    if (d > best) best = d;
  }
  return best;
}

// ---------------------------------------------------------------------------

void main() {
  // ── Time-based promotions ────────────────────────────────────────────────
  group('Promotion — time gating', () {
    final startDate = DateTime(2024, 6, 1);
    final endDate = DateTime(2024, 6, 30, 23, 59, 59);

    test('promotion is active on the start date', () {
      expect(
        _isPromoActive(now: DateTime(2024, 6, 1), startDate: startDate, endDate: endDate),
        isTrue,
      );
    });

    test('promotion is active on the end date', () {
      expect(
        _isPromoActive(now: DateTime(2024, 6, 30), startDate: startDate, endDate: endDate),
        isTrue,
      );
    });

    test('promotion is active between start and end dates', () {
      expect(
        _isPromoActive(now: DateTime(2024, 6, 15), startDate: startDate, endDate: endDate),
        isTrue,
      );
    });

    test('promotion is NOT active before start date', () {
      expect(
        _isPromoActive(now: DateTime(2024, 5, 31), startDate: startDate, endDate: endDate),
        isFalse,
      );
    });

    test('promotion is NOT active after end date', () {
      expect(
        _isPromoActive(now: DateTime(2024, 7, 1), startDate: startDate, endDate: endDate),
        isFalse,
      );
    });

    test('promotion with no dates is always active', () {
      expect(
        _isPromoActive(now: DateTime(2000, 1, 1)),
        isTrue,
      );
      expect(
        _isPromoActive(now: DateTime(2099, 12, 31)),
        isTrue,
      );
    });

    test('promotion with only startDate is active after start', () {
      expect(
        _isPromoActive(now: DateTime(2024, 7, 1), startDate: startDate),
        isTrue,
      );
      expect(
        _isPromoActive(now: DateTime(2024, 5, 31), startDate: startDate),
        isFalse,
      );
    });
  });

  // ── buy1get1 ─────────────────────────────────────────────────────────────
  group('Promotion type: buy1get1', () {
    test('1 item → 0 free', () {
      expect(
        _calculatePromoDiscount(type: 'buy1get1', promoValue: 0, quantity: 1, unitPrice: 10000),
        0.0,
      );
    });

    test('2 items → 1 free', () {
      expect(
        _calculatePromoDiscount(type: 'buy1get1', promoValue: 0, quantity: 2, unitPrice: 10000),
        10000.0,
      );
    });

    test('3 items → 1 free', () {
      expect(
        _calculatePromoDiscount(type: 'buy1get1', promoValue: 0, quantity: 3, unitPrice: 10000),
        10000.0,
      );
    });

    test('4 items → 2 free', () {
      expect(
        _calculatePromoDiscount(type: 'buy1get1', promoValue: 0, quantity: 4, unitPrice: 10000),
        20000.0,
      );
    });
  });

  // ── buy2get1 ─────────────────────────────────────────────────────────────
  group('Promotion type: buy2get1', () {
    test('2 items → 0 free', () {
      expect(
        _calculatePromoDiscount(type: 'buy2get1', promoValue: 0, quantity: 2, unitPrice: 5000),
        0.0,
      );
    });

    test('3 items → 1 free', () {
      expect(
        _calculatePromoDiscount(type: 'buy2get1', promoValue: 0, quantity: 3, unitPrice: 5000),
        5000.0,
      );
    });

    test('6 items → 2 free', () {
      expect(
        _calculatePromoDiscount(type: 'buy2get1', promoValue: 0, quantity: 6, unitPrice: 5000),
        10000.0,
      );
    });
  });

  // ── percentOff ────────────────────────────────────────────────────────────
  group('Promotion type: percentOff', () {
    test('10% off on 20000 subtotal → 2000 discount', () {
      expect(
        _calculatePromoDiscount(type: 'percentOff', promoValue: 10, quantity: 2, unitPrice: 10000),
        closeTo(2000, 0.01),
      );
    });

    test('50% off on 10000 subtotal → 5000 discount', () {
      expect(
        _calculatePromoDiscount(type: 'percentOff', promoValue: 50, quantity: 1, unitPrice: 10000),
        closeTo(5000, 0.01),
      );
    });

    test('0% discount gives 0', () {
      expect(
        _calculatePromoDiscount(type: 'percentOff', promoValue: 0, quantity: 2, unitPrice: 5000),
        0.0,
      );
    });
  });

  // ── amountOff ─────────────────────────────────────────────────────────────
  group('Promotion type: amountOff', () {
    test('fixed 3000 discount on 10000 subtotal → 3000', () {
      expect(
        _calculatePromoDiscount(type: 'amountOff', promoValue: 3000, quantity: 2, unitPrice: 5000),
        3000.0,
      );
    });

    test('fixed discount capped at subtotal when discount > subtotal', () {
      // subtotal = 1 * 2000 = 2000; discount = 5000 → clamped to 2000
      expect(
        _calculatePromoDiscount(type: 'amountOff', promoValue: 5000, quantity: 1, unitPrice: 2000),
        2000.0,
      );
    });
  });

  // ── unknown type ─────────────────────────────────────────────────────────
  group('Promotion type: unknown', () {
    test('unknown type returns 0 discount', () {
      expect(
        _calculatePromoDiscount(type: 'freeShipping', promoValue: 0, quantity: 1, unitPrice: 5000),
        0.0,
      );
    });
  });

  // ── Category discount (filtering) ─────────────────────────────────────────
  group('Category-scoped promotions', () {
    test('promotion with matching productId applies discount', () {
      // Simulates applicablePromotionsProvider filtering: promoProductId == null
      // means applies to all; otherwise only to matching product.
      const targetProductId = 5;
      final int? promoProductId = 5; // matches

      final applies = promoProductId == null || promoProductId == targetProductId;
      expect(applies, isTrue);
    });

    test('promotion with different productId does not apply', () {
      const targetProductId = 5;
      final int? promoProductId = 7; // different product

      final applies = promoProductId == null || promoProductId == targetProductId;
      expect(applies, isFalse);
    });

    test('global promotion (null productId) applies to any product', () {
      const int? promoProductId = null;

      final appliesTo5 = promoProductId == null || promoProductId == 5;
      final appliesTo99 = promoProductId == null || promoProductId == 99;
      expect(appliesTo5, isTrue);
      expect(appliesTo99, isTrue);
    });
  });

  // ── Best promotion wins ────────────────────────────────────────────────
  group('Best promotion selection', () {
    test('highest discount promo wins when multiple promos qualify', () {
      final promos = [
        {'type': 'percentOff', 'value': 10},    // 10% → 2000
        {'type': 'amountOff', 'value': 5000},   // fixed → 5000
        {'type': 'buy1get1', 'value': 0},        // 1 free × 20000 = 20000
      ];

      // Item: qty=2, unitPrice=20000 → subtotal=40000
      final best = _bestDiscount(promos: promos, quantity: 2, unitPrice: 20000);
      // buy1get1: 1 free × 20000 = 20000 (best)
      expect(best, closeTo(20000, 0.01));
    });

    test('single matching promo always applied', () {
      final promos = [
        {'type': 'percentOff', 'value': 20},
      ];
      // qty=1, unitPrice=10000 → 20% of 10000 = 2000
      final best = _bestDiscount(promos: promos, quantity: 1, unitPrice: 10000);
      expect(best, closeTo(2000, 0.01));
    });

    test('no promos gives 0 discount', () {
      final best = _bestDiscount(promos: [], quantity: 5, unitPrice: 10000);
      expect(best, 0.0);
    });

    test('promos do not stack — only one (best) is applied', () {
      // Two promotions: 10% and 20% off
      // Only the better one should be applied, not both combined.
      final promos = [
        {'type': 'percentOff', 'value': 10},
        {'type': 'percentOff', 'value': 20},
      ];
      final best = _bestDiscount(promos: promos, quantity: 1, unitPrice: 10000);
      // Best is 20% → 2000; NOT 10% + 20% = 3000
      expect(best, closeTo(2000, 0.01));
      expect(best, isNot(closeTo(3000, 0.01)));
    });
  });
}

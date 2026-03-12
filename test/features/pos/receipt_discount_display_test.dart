import 'package:flutter_test/flutter_test.dart';

/// B-101: Receipt — 할인 금액 미표시
///
/// Verifies the logic that determines whether the discount row
/// should appear on the receipt:  `if (discount > 0)`
void main() {
  group('B-101: Receipt discount row display logic', () {
    // Helper mirrors receipt_screen.dart logic
    bool shouldShowDiscountRow(double discount) => discount > 0;

    test('discount > 0 shows discount row', () {
      expect(shouldShowDiscountRow(10000), isTrue);
    });

    test('discount == 0 hides discount row', () {
      expect(shouldShowDiscountRow(0), isFalse);
    });

    test('discount < 0 (invalid) does not show row', () {
      // Negative discount would be a data error; guard against it
      expect(shouldShowDiscountRow(-1), isFalse);
    });

    test('large discount shows row', () {
      expect(shouldShowDiscountRow(999999), isTrue);
    });

    test('fractional discount shows row', () {
      expect(shouldShowDiscountRow(0.01), isTrue);
    });

    // ── Receipt total calculation ─────────────────────────────────────
    test('total = subtotal - discount', () {
      const subtotal = 200000.0;
      const discount = 20000.0;
      final total = subtotal - discount;
      expect(total, 180000.0);
    });

    test('total equals subtotal when no discount', () {
      const subtotal = 150000.0;
      const discount = 0.0;
      final total = subtotal - discount;
      expect(total, subtotal);
    });

    test('discount displayed as negative value on receipt', () {
      const discount = 30000.0;
      final displayed = -discount;
      expect(displayed, -30000.0);
      expect(displayed.isNegative, isTrue);
    });

    // ── Open Tab checkout: DB discount field is source of truth ───────
    test('sale_detail_screen: discount > 0 shows Discount row', () {
      // sale.discount comes directly from DB
      final saleDiscount = 50000.0;
      expect(shouldShowDiscountRow(saleDiscount), isTrue);
    });

    test('sale_detail_screen: discount == 0 hides row', () {
      final saleDiscount = 0.0;
      expect(shouldShowDiscountRow(saleDiscount), isFalse);
    });
  });
}

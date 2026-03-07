import 'package:flutter_test/flutter_test.dart';

/// B-063: Change Calculation Tests
void main() {
  group('Change Calculation Logic', () {
    double calculateChange(double cashPaid, double total, String paymentMethod) {
      return paymentMethod == 'cash' ? (cashPaid - total) : 0.0;
    }

    test('should calculate correct change for cash payment', () {
      const cashPaid = 100000.0;
      const total = 75500.0;
      const expected = 24500.0;

      final change = calculateChange(cashPaid, total, 'cash');

      expect(change, expected);
    });

    test('should return zero change for card payment', () {
      const cashPaid = 100000.0;
      const total = 75500.0;

      final change = calculateChange(cashPaid, total, 'card');

      expect(change, 0.0);
    });

    test('should handle exact amount payment', () {
      const cashPaid = 75500.0;
      const total = 75500.0;

      final change = calculateChange(cashPaid, total, 'cash');

      expect(change, 0.0);
    });

    test('should handle insufficient payment (negative change)', () {
      const cashPaid = 70000.0;
      const total = 75500.0;

      final change = calculateChange(cashPaid, total, 'cash');

      expect(change, -5500.0);
      expect(change < 0, true);
    });

    test('should handle floating point precision', () {
      const cashPaid = 100.5;
      const total = 50.3;
      const expected = 50.2;

      final change = calculateChange(cashPaid, total, 'cash');

      expect((change - expected).abs() < 0.01, true);
    });

    test('should format VND correctly with commas', () {
      const value = 1234567;
      final formatted = value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );

      expect(formatted, '1,234,567');
    });
  });

  group('Payment Validation', () {
    bool isPaymentValid(double cashPaid, double total, String paymentMethod) {
      return paymentMethod != 'cash' || cashPaid >= total;
    }

    test('should validate sufficient cash payment', () {
      expect(isPaymentValid(100000, 75500, 'cash'), true);
    });

    test('should reject insufficient cash payment', () {
      expect(isPaymentValid(70000, 75500, 'cash'), false);
    });

    test('should accept any card payment amount', () {
      expect(isPaymentValid(0, 75500, 'card'), true);
    });

    test('should accept QR payment without validation', () {
      expect(isPaymentValid(0, 75500, 'qr'), true);
    });
  });
}

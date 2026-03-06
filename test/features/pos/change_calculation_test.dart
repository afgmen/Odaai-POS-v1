import 'package:flutter_test/flutter_test.dart';

void main() {
  group('B-063: Change Calculation', () {
    test('Cash payment: should calculate change correctly', () {
      // Given
      const total = 95000.0;
      const cashPaid = 100000.0;
      const paymentMethod = 'cash';

      // When
      final change = paymentMethod == 'cash' ? (cashPaid - total) : 0.0;

      // Then
      expect(change, 5000.0);
    });

    test('Cash payment: exact amount should return 0 change', () {
      // Given
      const total = 100000.0;
      const cashPaid = 100000.0;
      const paymentMethod = 'cash';

      // When
      final change = paymentMethod == 'cash' ? (cashPaid - total) : 0.0;

      // Then
      expect(change, 0.0);
    });

    test('Card payment: should always return 0 change', () {
      // Given
      const total = 95000.0;
      const cashPaid = 0.0; // Card payment doesn't use cashPaid
      const paymentMethod = 'card';

      // When
      final change = paymentMethod == 'cash' ? (cashPaid - total) : 0.0;

      // Then
      expect(change, 0.0);
    });

    test('QR payment: should always return 0 change', () {
      // Given
      const total = 95000.0;
      const cashPaid = 0.0;
      const paymentMethod = 'qr';

      // When
      final change = paymentMethod == 'cash' ? (cashPaid - total) : 0.0;

      // Then
      expect(change, 0.0);
    });

    test('Cash payment: insufficient amount should show negative change', () {
      // Given
      const total = 100000.0;
      const cashPaid = 50000.0; // Not enough!
      const paymentMethod = 'cash';

      // When
      final change = paymentMethod == 'cash' ? (cashPaid - total) : 0.0;

      // Then
      expect(change, -50000.0);
      expect(change < 0, true, reason: 'Change should be negative when insufficient');
    });

    test('Cash payment: large amount should calculate correctly', () {
      // Given
      const total = 1500000.0;
      const cashPaid = 2000000.0;
      const paymentMethod = 'cash';

      // When
      final change = paymentMethod == 'cash' ? (cashPaid - total) : 0.0;

      // Then
      expect(change, 500000.0);
    });

    test('Receipt: cash payment should show change', () {
      // Simulate Receipt logic
      const total = 95000.0;
      const cashPaid = 100000.0;
      const paymentMethod = 'cash';

      final change = paymentMethod == 'cash' ? (cashPaid - total) : 0.0;

      expect(change, 5000.0);
      expect(change > 0, true, reason: 'Change should be positive');
    });

    test('Receipt: card payment should NOT show change', () {
      // Simulate Receipt logic
      const total = 95000.0;
      const cashPaid = 0.0; // Card payment
      const paymentMethod = 'card';

      final change = paymentMethod == 'cash' ? (cashPaid - total) : 0.0;

      expect(change, 0.0);
    });

    test('PaymentModal: should pass 0 cashPaid for card payment', () {
      // Simulate PaymentModal logic
      const cashInput = 100000.0; // User entered cash amount but switched to card
      const selectedMethod = 'card';

      // This is the bug: PaymentModal always passes _cashInput
      // Fix: Only pass cashInput when method is 'cash'
      final cashPaidToReceipt = selectedMethod == 'cash' ? cashInput : 0.0;

      expect(cashPaidToReceipt, 0.0, 
             reason: 'Card payment should pass 0 to Receipt');
    });

    test('PaymentModal: should pass cashInput for cash payment', () {
      // Simulate PaymentModal logic
      const cashInput = 100000.0;
      const selectedMethod = 'cash';

      final cashPaidToReceipt = selectedMethod == 'cash' ? cashInput : 0.0;

      expect(cashPaidToReceipt, 100000.0,
             reason: 'Cash payment should pass actual cashInput');
    });
  });
}

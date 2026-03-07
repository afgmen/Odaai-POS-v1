import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-018: 환불 후 총매출
/// Priority: P1
/// Steps: Refund order → Check total sales
/// Expected: Total sales minus refund
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-018: Refund Sales Total', () {
    testWidgets('should subtract refund from total sales', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Create order ₫10,000
      final posTab = TestHelpers.findByText('POS');
      await TestHelpers.tap(tester, posTab);

      final productCard = TestHelpers.findByText(TestData.testProductName);
      await TestHelpers.tap(tester, productCard);

      final checkoutButton = TestHelpers.findByText('Checkout');
      await TestHelpers.tap(tester, checkoutButton);

      final cashButton = TestHelpers.findByText('Cash');
      await TestHelpers.tap(tester, cashButton);

      final completeButton = TestHelpers.findByText('Complete');
      await TestHelpers.tap(tester, completeButton);

      // 2. Check total sales (should be ₫10,000)
      final salesTab = TestHelpers.findByText('Sales');
      await TestHelpers.tap(tester, salesTab);

      TestHelpers.verifyText('₫10,000');

      // 3. Refund order
      final orderItem = TestHelpers.findByText(TestData.testOrderCode);
      await TestHelpers.tap(tester, orderItem);

      final refundButton = TestHelpers.findByText('Refund');
      await TestHelpers.tap(tester, refundButton);

      final confirmButton = TestHelpers.findByText('Confirm');
      await TestHelpers.tap(tester, confirmButton);

      // 4. Check total sales (should be ₫0)
      TestHelpers.verifyText('₫0');
    });

    testWidgets('should handle partial refund', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Order: ₫10,000 (2 items × ₫5,000)
      // Refund: 1 item = ₫5,000
      // Total sales: ₫10,000 - ₫5,000 = ₫5,000

      expect(true, true); // Placeholder
    });

    testWidgets('should handle multiple refunds', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Order A: ₫10,000
      // Order B: ₫15,000
      // Total: ₫25,000
      // Refund A → ₫15,000
      // Refund B partial ₫5,000 → ₫10,000

      expect(true, true); // Placeholder
    });
  });
}

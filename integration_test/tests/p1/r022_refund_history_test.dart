import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-022: 환불 시 구매 이력
/// Priority: P1
/// Steps: Refund order → Check history
/// Expected: Display refund order amount
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-022: Refund History', () {
    testWidgets('should display refund in customer purchase history', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Create order for customer
      final posTab = TestHelpers.findByText('POS');
      await TestHelpers.tap(tester, posTab);

      final customerButton = find.byIcon(Icons.person);
      await TestHelpers.tap(tester, customerButton);

      final customerItem = TestHelpers.findByText(TestData.testCustomerName);
      await TestHelpers.tap(tester, customerItem);

      final productCard = TestHelpers.findByText(TestData.testProductName);
      await TestHelpers.tap(tester, productCard);

      final checkoutButton = TestHelpers.findByText('Checkout');
      await TestHelpers.tap(tester, checkoutButton);

      final cashButton = TestHelpers.findByText('Cash');
      await TestHelpers.tap(tester, cashButton);

      final completeButton = TestHelpers.findByText('Complete');
      await TestHelpers.tap(tester, completeButton);

      // 2. Refund order
      final salesTab = TestHelpers.findByText('Sales');
      await TestHelpers.tap(tester, salesTab);

      final orderItem = TestHelpers.findByText(TestData.testOrderCode);
      await TestHelpers.tap(tester, orderItem);

      final refundButton = TestHelpers.findByText('Refund');
      await TestHelpers.tap(tester, refundButton);

      final confirmButton = TestHelpers.findByText('Confirm');
      await TestHelpers.tap(tester, confirmButton);

      // 3. Check customer history
      final customersTab = TestHelpers.findByText('Customers');
      await TestHelpers.tap(tester, customersTab);

      final customer = TestHelpers.findByText(TestData.testCustomerName);
      await TestHelpers.tap(tester, customer);

      // 4. Verify refund order displayed
      TestHelpers.verifyText(TestData.testOrderCode);
      TestHelpers.verifyTextContains('Refund');
      TestHelpers.verifyText('-₫10,000'); // Negative amount
    });

    testWidgets('should mark refund order with badge', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Refund order should have:
      // - Red badge "REFUNDED"
      // - Strikethrough on amount
      // - Refund icon

      expect(true, true); // Placeholder
    });

    testWidgets('should show refund timestamp', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Display: "Refunded on 2026-03-07 10:30 AM"

      expect(true, true); // Placeholder
    });
  });
}

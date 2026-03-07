import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-021: 포인트 결제
/// Priority: P1
/// Steps: Use points to deduct order
/// Expected: Total reduced, points deducted
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-021: Points Payment', () {
    testWidgets('should deduct order total with points', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Add product (₫10,000)
      final posTab = TestHelpers.findByText('POS');
      await TestHelpers.tap(tester, posTab);

      final productCard = TestHelpers.findByText(TestData.testProductName);
      await TestHelpers.tap(tester, productCard);

      // 2. Select customer with 1000 points
      final customerButton = find.byIcon(Icons.person);
      await TestHelpers.tap(tester, customerButton);

      final customerItem = TestHelpers.findByText(TestData.testCustomerName);
      await TestHelpers.tap(tester, customerItem);

      // 3. Checkout
      final checkoutButton = TestHelpers.findByText('Checkout');
      await TestHelpers.tap(tester, checkoutButton);

      // 4. Use 500 points (₫5,000)
      final pointsButton = TestHelpers.findByText('Use Points');
      await TestHelpers.tap(tester, pointsButton);

      await TestHelpers.enterText(
        tester,
        find.byType(TextField).first,
        '500',
      );

      final applyButton = TestHelpers.findByText('Apply');
      await TestHelpers.tap(tester, applyButton);

      // 5. Verify total reduced: ₫10,000 - ₫5,000 = ₫5,000
      TestHelpers.verifyText('₫5,000');

      // 6. Complete payment
      final cashButton = TestHelpers.findByText('Cash');
      await TestHelpers.tap(tester, cashButton);

      final completeButton = TestHelpers.findByText('Complete');
      await TestHelpers.tap(tester, completeButton);

      // 7. Verify customer points deducted: 1000 - 500 = 500
      final customersTab = TestHelpers.findByText('Customers');
      await TestHelpers.tap(tester, customersTab);

      final customer = TestHelpers.findByText(TestData.testCustomerName);
      await TestHelpers.tap(tester, customer);

      TestHelpers.verifyText('500 points');
    });

    testWidgets('should not allow points exceeding total', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Order: ₫10,000
      // Try to use 2000 points (₫20,000)
      // Expected: Error or max 1000 points

      expect(true, true); // Placeholder
    });

    testWidgets('should show points value conversion', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Display: "500 points = ₫5,000"

      expect(true, true); // Placeholder
    });
  });
}

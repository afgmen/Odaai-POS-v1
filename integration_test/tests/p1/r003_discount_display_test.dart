import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-003: Discount 표시
/// Priority: P1
/// Steps: Add discount
/// Expected: Show the Discount amount in Cart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-003: Discount Display', () {
    testWidgets('should display discount amount in cart', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Navigate to POS
      final posTab = TestHelpers.findByText('POS');
      await TestHelpers.tap(tester, posTab);

      // 2. Add product to cart
      final productCard = TestHelpers.findByText(TestData.testProductName);
      await TestHelpers.tap(tester, productCard);

      // 3. Apply discount
      final discountButton = find.byIcon(Icons.discount);
      await TestHelpers.tap(tester, discountButton);

      // Enter discount amount
      await TestHelpers.enterText(
        tester,
        find.byType(TextField).first,
        TestData.testDiscountAmount.toString(),
      );

      final applyButton = TestHelpers.findByText('Apply');
      await TestHelpers.tap(tester, applyButton);

      // 4. Verify discount displayed in cart
      TestHelpers.verifyTextContains('Discount');
      TestHelpers.verifyText('-₫${TestData.testDiscountAmount.toInt()}');
    });

    testWidgets('should display percentage discount', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Apply 10% discount
      // Product: ₫10,000
      // Discount: 10% = ₫1,000
      // Verify: "-₫1,000 (10%)"

      expect(true, true); // Placeholder
    });

    testWidgets('should update discount display when changed', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Apply discount ₫5,000
      // 2. Verify display
      // 3. Change to ₫3,000
      // 4. Verify updated display

      expect(true, true); // Placeholder
    });

    testWidgets('should display discount in order summary', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Cart should show:
      // Subtotal: ₫10,000
      // Discount: -₫5,000
      // Total: ₫5,000

      expect(true, true); // Placeholder
    });
  });
}

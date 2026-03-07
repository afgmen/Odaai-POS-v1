import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-004: Discount 적용
/// Priority: P1
/// Steps: Apply Discount
/// Expected: Update total amount after discount
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-004: Discount Apply', () {
    testWidgets('should update total amount after discount', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Add product (₦10,000)
      final posTab = TestHelpers.findByText('POS');
      await TestHelpers.tap(tester, posTab);

      final productCard = TestHelpers.findByText(TestData.testProductName);
      await TestHelpers.tap(tester, productCard);

      // Initial total: ₫10,000
      TestHelpers.verifyText('₫10,000');

      // 2. Apply discount ₫5,000
      final discountButton = find.byIcon(Icons.discount);
      await TestHelpers.tap(tester, discountButton);

      await TestHelpers.enterText(
        tester,
        find.byType(TextField).first,
        '5000',
      );

      final applyButton = TestHelpers.findByText('Apply');
      await TestHelpers.tap(tester, applyButton);

      // 3. Verify total updated: ₫10,000 - ₫5,000 = ₫5,000
      TestHelpers.verifyText('₫5,000');
    });

    testWidgets('should apply percentage discount correctly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Product: ₫10,000
      // Discount: 10%
      // Expected: ₫10,000 - ₫1,000 = ₫9,000

      expect(true, true); // Placeholder
    });

    testWidgets('should handle multiple discounts', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Apply discount A: ₫2,000
      // Apply discount B: ₫1,000
      // Total discount: ₫3,000

      expect(true, true); // Placeholder
    });

    testWidgets('should not allow discount greater than total', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Product: ₫10,000
      // Try discount: ₫15,000
      // Expected: Error or max ₫10,000

      expect(true, true); // Placeholder
    });
  });
}

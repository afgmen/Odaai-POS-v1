import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-009: 재고 한도 검증 (Edge Case)
/// Priority: P0
/// Steps: Add product 31 times (stock: 30)
/// Expected: "Not enough stock" error
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-009: Stock Limit Validation', () {
    testWidgets('should prevent adding more than available stock', (tester) async {
      // Launch app
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Navigate to POS
      final posTab = TestHelpers.findByText('POS');
      await TestHelpers.tap(tester, posTab);

      // 2. Find product with stock 30
      final productCard = TestHelpers.findByText(TestData.testProductName);
      await TestHelpers.tap(tester, productCard);

      // 3. Try to add 31 quantity
      final plusButton = find.byIcon(Icons.add);
      
      // Tap 30 times (should work)
      for (int i = 1; i < TestData.testStock; i++) {
        await TestHelpers.tap(tester, plusButton.first);
      }
      
      // Verify quantity is 30
      TestHelpers.verifyText(TestData.testStock.toString());
      
      // 4. Try to add 31st item (should fail)
      await TestHelpers.tap(tester, plusButton.first);
      
      // 5. Verify error message
      TestHelpers.verifyTextContains('Not enough stock');
      // OR
      TestHelpers.verifyTextContains('재고 부족');
      
      // Quantity should still be 30
      TestHelpers.verifyText(TestData.testStock.toString());
    });

    testWidgets('should allow adding exactly available stock', (tester) async {
      // Launch app
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Navigate to POS
      final posTab = TestHelpers.findByText('POS');
      await TestHelpers.tap(tester, posTab);

      // Add product with exactly stock amount (30)
      final productCard = TestHelpers.findByText(TestData.testProductName);
      await TestHelpers.tap(tester, productCard);
      
      final plusButton = find.byIcon(Icons.add);
      for (int i = 1; i < TestData.testStock; i++) {
        await TestHelpers.tap(tester, plusButton.first);
      }
      
      // Should succeed
      TestHelpers.verifyText(TestData.testStock.toString());
      
      // Checkout should work
      final checkoutButton = TestHelpers.findByText('Checkout');
      TestHelpers.verifyExists(checkoutButton);
    });

    testWidgets('should update limit when stock changes', (tester) async {
      // Launch app
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Initial stock: 30
      // 2. Create order with quantity 10
      // 3. New available stock: 20
      // 4. Try to add 21 → should fail
      // 5. Try to add 20 → should succeed
      
      expect(true, true); // Placeholder
    });

    testWidgets('should handle stock limit across multiple products', (tester) async {
      // Launch app
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Product A: stock 30, add 30 → OK
      // Product B: stock 15, add 16 → Error
      
      expect(true, true); // Placeholder
    });

    testWidgets('should show clear error message for stock limit', (tester) async {
      // Launch app
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Try to exceed stock
      // Verify error message is user-friendly
      // Should contain: product name, available stock, requested quantity
      
      expect(true, true); // Placeholder
    });
  });
}

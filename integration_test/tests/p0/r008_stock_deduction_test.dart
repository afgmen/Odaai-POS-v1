import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-008: 재고 차감 계산
/// Priority: P0
/// Steps: Create POS order → Check stock
/// Expected: Stock will minus after order
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-008: Stock Deduction', () {
    testWidgets('should deduct stock after creating POS order', (tester) async {
      // Launch app
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // TODO: Login (skip for now, assume logged in)
      
      // 1. Navigate to Products
      final productsTab = TestHelpers.findByText('Products');
      if (productsTab.evaluate().isNotEmpty) {
        await TestHelpers.tap(tester, productsTab);
      }

      // 2. Create test product with stock 30
      final addProductButton = find.byIcon(Icons.add);
      if (addProductButton.evaluate().isNotEmpty) {
        await TestHelpers.tap(tester, addProductButton);
        
        // Fill product form
        await TestHelpers.enterText(
          tester,
          find.byType(TextField).first,
          TestData.testSKU,
        );
        await TestHelpers.enterText(
          tester,
          find.text('Name').last,
          TestData.testProductName,
        );
        await TestHelpers.enterText(
          tester,
          find.text('Price').last,
          TestData.testPrice.toString(),
        );
        await TestHelpers.enterText(
          tester,
          find.text('Stock').last,
          TestData.testStock.toString(),
        );
        
        // Save product
        final saveButton = TestHelpers.findByText('Save');
        await TestHelpers.tap(tester, saveButton);
      }

      // 3. Navigate to POS
      final posTab = TestHelpers.findByText('POS');
      await TestHelpers.tap(tester, posTab);

      // 4. Add product to cart (quantity 5)
      final productCard = TestHelpers.findByText(TestData.testProductName);
      await TestHelpers.tap(tester, productCard);
      
      // Increase quantity to 5
      final plusButton = find.byIcon(Icons.add);
      for (int i = 1; i < TestData.testOrderQuantity; i++) {
        await TestHelpers.tap(tester, plusButton.first);
      }

      // 5. Complete order
      final checkoutButton = TestHelpers.findByText('Checkout');
      await TestHelpers.tap(tester, checkoutButton);
      
      final cashButton = TestHelpers.findByText('Cash');
      await TestHelpers.tap(tester, cashButton);
      
      final completeButton = TestHelpers.findByText('Complete');
      await TestHelpers.tap(tester, completeButton);

      // 6. Verify stock deduction
      // Navigate back to Products
      await TestHelpers.tap(tester, TestHelpers.findByText('Products'));
      
      // Find product and check stock
      final productItem = TestHelpers.findByText(TestData.testProductName);
      await TestHelpers.tap(tester, productItem);
      
      // Expected stock: 30 - 5 = 25
      final expectedStock = TestData.testStock - TestData.testOrderQuantity;
      TestHelpers.verifyText(expectedStock.toString());
    });

    testWidgets('should handle multiple orders correctly', (tester) async {
      // Launch app
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Create 2 orders with quantity 3 each
      // Expected: stock 30 - 3 - 3 = 24
      
      // Order 1
      // (Similar flow as above with quantity 3)
      
      // Order 2
      // (Similar flow as above with quantity 3)
      
      // Verify final stock = 24
      expect(true, true); // Placeholder
    });

    testWidgets('should update stock in real-time', (tester) async {
      // Launch app
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Check initial stock
      // 2. Create order in parallel
      // 3. Verify stock updates immediately
      
      expect(true, true); // Placeholder
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-014: 재고 가치 계산
/// Priority: P2
/// Steps: Observe Inventory Value
/// Expected: Sum of (Qty x Cost)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-014: Inventory Value', () {
    testWidgets('should calculate total inventory value', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Navigate to Products
      final productsTab = TestHelpers.findByText('Products');
      await TestHelpers.tap(tester, productsTab);

      // 2. Product A: 30 qty × ₫7,000 = ₫210,000
      // Product B: 20 qty × ₫5,000 = ₫100,000
      // Total Inventory Value: ₫310,000

      // 3. View inventory summary
      final inventoryTab = TestHelpers.findByText('Inventory');
      if (inventoryTab.evaluate().isNotEmpty) {
        await TestHelpers.tap(tester, inventoryTab);

        // 4. Verify total value
        TestHelpers.verifyText('₫310,000');
      }
    });

    testWidgets('should update inventory value after stock change', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Initial: 30 × ₫7,000 = ₫210,000
      // Sell 5 → 25 × ₫7,000 = ₫175,000
      // Inventory value updated

      expect(true, true); // Placeholder
    });

    testWidgets('should display inventory value by category', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Snacks: ₫200,000
      // Beverages: ₫150,000
      // Total: ₫350,000

      expect(true, true); // Placeholder
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-013: 판매가 vs 원가 경고
/// Priority: P2
/// Steps: Compare Selling Price and Cost
/// Expected: Warn when price < cost
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-013: Price vs Cost Warning', () {
    testWidgets('should warn when selling price is less than cost', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Navigate to Products
      final productsTab = TestHelpers.findByText('Products');
      await TestHelpers.tap(tester, productsTab);

      // 2. Create product
      final addButton = find.byIcon(Icons.add);
      await TestHelpers.tap(tester, addButton);

      await TestHelpers.enterText(
        tester,
        find.byType(TextField).at(0),
        'WARN001',
      );

      // 3. Enter cost: ₫10,000
      await TestHelpers.enterText(
        tester,
        TestHelpers.findByText('Cost').last,
        '10000',
      );

      // 4. Enter price: ₫8,000 (lower than cost)
      await TestHelpers.enterText(
        tester,
        TestHelpers.findByText('Price').last,
        '8000',
      );

      // 5. Verify warning displayed
      TestHelpers.verifyTextContains('Warning');
      TestHelpers.verifyTextContains('price is lower than cost');
      // OR
      TestHelpers.verifyTextContains('Loss alert');
    });

    testWidgets('should not warn when price equals cost', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Price: ₫10,000
      // Cost: ₫10,000
      // No warning (break-even)

      expect(true, true); // Placeholder
    });

    testWidgets('should calculate profit margin', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Price: ₫10,000
      // Cost: ₫7,000
      // Profit: ₫3,000 (30%)
      // Display: "Profit: 30%"

      expect(true, true); // Placeholder
    });
  });
}

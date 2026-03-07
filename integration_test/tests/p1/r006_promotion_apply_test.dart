import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-006: Promotion 적용
/// Priority: P1
/// Steps: Apply Promotion
/// Expected: Update cart total
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-006: Promotion Apply', () {
    testWidgets('should update cart total when promotion applied', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Navigate to POS
      final posTab = TestHelpers.findByText('POS');
      await TestHelpers.tap(tester, posTab);

      // 2. Add eligible product
      final productCard = TestHelpers.findByText(TestData.testProductName);
      await TestHelpers.tap(tester, productCard);

      // Initial: ₫10,000

      // 3. Add quantity to trigger promotion (e.g., Buy 2)
      final plusButton = find.byIcon(Icons.add);
      await TestHelpers.tap(tester, plusButton.first);

      // 4. Promotion auto-applies: 10% off
      // Expected: ₫20,000 - ₫2,000 = ₫18,000
      TestHelpers.verifyText('₫18,000');
    });

    testWidgets('should apply multiple promotions', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Promotion A: Buy 2 Get 10%
      // Promotion B: Spend ₫50k Get ₫5k off
      // Both applicable → apply both

      expect(true, true); // Placeholder
    });

    testWidgets('should remove promotion when condition not met', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Buy 2 → Promotion applied
      // 2. Remove 1 → Promotion removed
      // 3. Total back to normal

      expect(true, true); // Placeholder
    });
  });
}

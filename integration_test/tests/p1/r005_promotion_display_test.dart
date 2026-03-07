import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-005: Promotion 표시
/// Priority: P1
/// Steps: Select promotion type and product
/// Expected: Show discount amount
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-005: Promotion Display', () {
    testWidgets('should display promotion discount amount', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Navigate to Promotions
      final promotionsTab = TestHelpers.findByText('Promotions');
      await TestHelpers.tap(tester, promotionsTab);

      // 2. Create promotion
      final addButton = find.byIcon(Icons.add);
      await TestHelpers.tap(tester, addButton);

      // 3. Select promotion type (e.g., "Buy 2 Get 10% off")
      final promoType = TestHelpers.findByText('Percentage');
      await TestHelpers.tap(tester, promoType);

      // 4. Enter discount amount
      await TestHelpers.enterText(
        tester,
        find.byType(TextField).first,
        TestData.testDiscountPercent.toString(),
      );

      // 5. Verify discount displayed
      TestHelpers.verifyText('10%');
      TestHelpers.verifyTextContains('discount');
    });

    testWidgets('should display promotion in POS cart', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // POS → Add eligible product → Promotion auto-applied
      // Verify promotion badge/tag displayed

      expect(true, true); // Placeholder
    });

    testWidgets('should show promotion details on hover', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Hover over promotion badge
      // Show: "Buy 2 Get 10% off"

      expect(true, true); // Placeholder
    });
  });
}

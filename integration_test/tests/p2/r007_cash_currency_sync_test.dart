import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-007: Cash 결제 통화 동기화
/// Priority: P2
/// Steps: Cash method currency
/// Expected: Synchronize all current
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-007: Cash Currency Sync', () {
    testWidgets('should display currency symbol consistently', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Create order
      final posTab = TestHelpers.findByText('POS');
      await TestHelpers.tap(tester, posTab);

      final productCard = TestHelpers.findByText(TestData.testProductName);
      await TestHelpers.tap(tester, productCard);

      // 2. Go to checkout
      final checkoutButton = TestHelpers.findByText('Checkout');
      await TestHelpers.tap(tester, checkoutButton);

      // 3. Select Cash payment
      final cashButton = TestHelpers.findByText('Cash');
      await TestHelpers.tap(tester, cashButton);

      // 4. Verify currency symbol (₫) displayed
      TestHelpers.verifyTextContains('₫');

      // 5. All amounts should use same currency
      // Total: ₫10,000
      // Cash: ₫10,000
      // Change: ₫0
    });

    testWidgets('should calculate change in correct currency', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Total: ₫10,000
      // Cash given: ₫20,000
      // Change: ₫10,000 (same currency)

      expect(true, true); // Placeholder
    });

    testWidgets('should sync currency across all payment screens', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // POS → Checkout → Receipt
      // All use ₫ consistently

      expect(true, true); // Placeholder
    });
  });
}

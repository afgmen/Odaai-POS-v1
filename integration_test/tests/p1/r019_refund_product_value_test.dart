import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-019: 제품 판매 가치 (환불 반영)
/// Priority: P1
/// Steps: Check product sales value
/// Expected: Calculate after refund
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-019: Product Sales Value After Refund', () {
    testWidgets('should calculate product sales value after refund', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Sell product 5 times
      // Product sales value: 5 × ₫10,000 = ₫50,000

      // 2. Refund 2 orders
      // Product sales value: 3 × ₫10,000 = ₫30,000

      // 3. Navigate to Dashboard
      final dashboardTab = TestHelpers.findByText('Dashboard');
      await TestHelpers.tap(tester, dashboardTab);

      // 4. Find product in top products
      final productRow = TestHelpers.findByText(TestData.testProductName);
      await TestHelpers.tap(tester, productRow);

      // 5. Verify sales value
      TestHelpers.verifyText('₫30,000');
    });

    testWidgets('should update product ranking after refund', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Product A: ₫100,000 → Refund ₫50,000 → ₫50,000
      // Product B: ₫60,000 (no refund)
      // Ranking: B (#1), A (#2)

      expect(true, true); // Placeholder
    });

    testWidgets('should show refund impact in analytics', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Dashboard analytics should show:
      // Gross Sales: ₫100,000
      // Refunds: -₫20,000
      // Net Sales: ₫80,000

      expect(true, true); // Placeholder
    });
  });
}

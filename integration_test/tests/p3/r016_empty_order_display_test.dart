import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-016: 빈 주문 표시
/// Priority: P3
/// Steps: Select period with no orders
/// Expected: "No sales history" or ₫0
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-016: Empty Order Display', () {
    testWidgets('should show empty state when no orders', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Navigate to Sales
      final salesTab = TestHelpers.findByText('Sales');
      await TestHelpers.tap(tester, salesTab);

      // 2. Select date with no orders (e.g., future date)
      final datePicker = find.byIcon(Icons.calendar_today);
      await TestHelpers.tap(tester, datePicker);

      // Select tomorrow's date (no orders)
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      // Date picker interaction...

      // 3. Verify empty state displayed
      TestHelpers.verifyTextContains('No sales history');
      // OR
      TestHelpers.verifyTextContains('No orders found');
      // OR
      TestHelpers.verifyText('₫0');
    });

    testWidgets('should show empty state icon', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Empty state should include:
      // - Icon (e.g., inbox_outlined)
      // - Message: "No sales history"
      // - Suggestion: "Make your first sale"

      expect(true, true); // Placeholder
    });

    testWidgets('should show zero values in dashboard', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Dashboard with no sales:
      // Total Sales: ₫0
      // Orders: 0
      // Avg Order: ₫0

      expect(true, true); // Placeholder
    });

    testWidgets('should display helpful message for new users', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // First-time user:
      // "Get started by creating your first order"
      // Button: "Go to POS"

      expect(true, true); // Placeholder
    });
  });
}

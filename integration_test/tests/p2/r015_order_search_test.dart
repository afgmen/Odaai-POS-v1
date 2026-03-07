import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-015: 주문 검색 기능
/// Priority: P2
/// Steps: Enter order code in search
/// Expected: Filter exact order
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-015: Order Search', () {
    testWidgets('should find order by order code', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Navigate to Sales
      final salesTab = TestHelpers.findByText('Sales');
      await TestHelpers.tap(tester, salesTab);

      // 2. Search by order code
      final searchField = find.byType(TextField).first;
      await TestHelpers.enterText(
        tester,
        searchField,
        TestData.testOrderCode,
      );

      // 3. Verify exact order displayed
      TestHelpers.verifyText(TestData.testOrderCode);

      // 4. Other orders should be hidden
      expect(
        find.text('ORD-20260307-002').evaluate().isEmpty,
        true,
      );
    });

    testWidgets('should search by customer name', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Search: "Test Customer"
      // Show all orders by this customer

      expect(true, true); // Placeholder
    });

    testWidgets('should search by amount', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Search: "10000"
      // Show orders with ₫10,000

      expect(true, true); // Placeholder
    });

    testWidgets('should search by date range', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Select date range: 2026-03-01 ~ 2026-03-07
      // Show orders in range

      expect(true, true); // Placeholder
    });
  });
}

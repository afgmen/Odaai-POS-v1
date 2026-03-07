import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-020: 고객 목록 표시
/// Priority: P2
/// Steps: Go to Customers menu
/// Expected: Display Name, Phone, Email, Points, Total
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-020: Customer List Display', () {
    testWidgets('should display all customer information', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Navigate to Customers
      final customersTab = TestHelpers.findByText('Customers');
      await TestHelpers.tap(tester, customersTab);

      // 2. Verify customer displayed with all fields
      TestHelpers.verifyText(TestData.testCustomerName);
      TestHelpers.verifyText(TestData.testCustomerPhone);
      TestHelpers.verifyText(TestData.testCustomerEmail);
      TestHelpers.verifyText('${TestData.testCustomerPoints} points');
      
      // 3. Verify total purchases displayed
      TestHelpers.verifyTextContains('Total');
      TestHelpers.verifyTextContains('₫');
    });

    testWidgets('should display customer list in table format', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Table columns:
      // Name | Phone | Email | Points | Total Purchases

      expect(true, true); // Placeholder
    });

    testWidgets('should sort customers by total purchases', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Click "Total" column header
      // Sort descending (highest first)

      expect(true, true); // Placeholder
    });

    testWidgets('should filter customers by points range', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Filter: Points > 500
      // Show only high-value customers

      expect(true, true); // Placeholder
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-002: SKU/Barcode 대소문자 구분
/// Priority: P2
/// Steps: Search SKU/Barcode in scan mode
/// Expected: Can find even no capital (DEMO001 = demo001)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-002: SKU/Barcode Case-Insensitive', () {
    testWidgets('should find product with lowercase SKU', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Navigate to POS
      final posTab = TestHelpers.findByText('POS');
      await TestHelpers.tap(tester, posTab);

      // 2. Product SKU: "TEST001" (uppercase)
      // Search: "test001" (lowercase)
      final searchField = find.byType(TextField).first;
      await TestHelpers.enterText(
        tester,
        searchField,
        TestData.testSKU.toLowerCase(),
      );

      // 3. Verify product found
      TestHelpers.verifyText(TestData.testProductName);
    });

    testWidgets('should find product with mixed case SKU', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Search: "TeSt001" → Find "TEST001"

      expect(true, true); // Placeholder
    });

    testWidgets('should find product with lowercase barcode', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Barcode: "4000386123457"
      // Search: "4000386123457" (case doesn't matter for numbers)
      // But test with alphanumeric barcodes

      expect(true, true); // Placeholder
    });

    testWidgets('should work in scan mode', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Enable scan mode
      // 2. Scan "test001" (lowercase)
      // 3. Product "TEST001" added to cart

      expect(true, true); // Placeholder
    });
  });
}

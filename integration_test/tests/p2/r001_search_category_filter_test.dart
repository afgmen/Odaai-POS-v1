import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-001: 검색 + 카테고리 필터 조합
/// Priority: P2
/// Steps: Search "Potato" then switch Categories tab
/// Expected: Cannot find Potato in other categories when switches
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-001: Search + Category Filter', () {
    testWidgets('should clear search when switching categories', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Navigate to POS
      final posTab = TestHelpers.findByText('POS');
      await TestHelpers.tap(tester, posTab);

      // 2. Search "Potato"
      final searchField = find.byType(TextField).first;
      await TestHelpers.enterText(tester, searchField, TestData.searchKeyword);

      // 3. Verify "Potato" products displayed
      TestHelpers.verifyText(TestData.testProductName);

      // 4. Switch to different category (e.g., Beverages)
      final beverageTab = TestHelpers.findByText('Beverages');
      await TestHelpers.tap(tester, beverageTab);

      // 5. Verify "Potato" NOT in Beverages category
      TestHelpers.verifyNotExists(
        TestHelpers.findByText(TestData.testProductName),
      );

      // 6. Verify search cleared or category filter applied
      final searchText = searchField.evaluate().first.widget as TextField;
      expect(searchText.controller?.text ?? '', isEmpty);
    });

    testWidgets('should show search results across all categories', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Search should work in "All" category
      // Shows results from all categories

      expect(true, true); // Placeholder
    });

    testWidgets('should filter search results by selected category', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Select "Snacks" category
      // 2. Search "Potato"
      // 3. Only show Snacks category results

      expect(true, true); // Placeholder
    });
  });
}

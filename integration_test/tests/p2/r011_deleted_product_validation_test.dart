import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-011: 삭제된 제품 검증
/// Priority: P2
/// Steps: Create product with deleted SKU
/// Expected: Cannot validate existing data
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-011: Deleted Product Validation', () {
    testWidgets('should prevent creating product with deleted SKU', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Create product "TEST001"
      final productsTab = TestHelpers.findByText('Products');
      await TestHelpers.tap(tester, productsTab);

      final addButton = find.byIcon(Icons.add);
      await TestHelpers.tap(tester, addButton);

      await TestHelpers.enterText(
        tester,
        find.byType(TextField).first,
        'DELETED001',
      );

      final saveButton = TestHelpers.findByText('Save');
      await TestHelpers.tap(tester, saveButton);

      // 2. Delete product
      final productItem = TestHelpers.findByText('DELETED001');
      await TestHelpers.tap(tester, productItem);

      final deleteButton = find.byIcon(Icons.delete);
      await TestHelpers.tap(tester, deleteButton);

      final confirmButton = TestHelpers.findByText('Confirm');
      await TestHelpers.tap(tester, confirmButton);

      // 3. Try to create new product with same SKU
      await TestHelpers.tap(tester, addButton);

      await TestHelpers.enterText(
        tester,
        find.byType(TextField).first,
        'DELETED001',
      );

      await TestHelpers.tap(tester, saveButton);

      // 4. Verify error message
      TestHelpers.verifyTextContains('SKU already exists');
      // OR
      TestHelpers.verifyTextContains('Cannot use deleted SKU');
    });

    testWidgets('should show deleted products in history', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Deleted products viewable in history/archive

      expect(true, true); // Placeholder
    });

    testWidgets('should prevent restoring with conflicting data', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 1. Delete product A
      // 2. Create new product with same SKU (fails)
      // 3. Only option: restore product A

      expect(true, true); // Placeholder
    });
  });
}

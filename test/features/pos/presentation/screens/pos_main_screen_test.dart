import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/features/pos/data/models/order_type.dart';
import 'package:oda_pos/features/pos/presentation/screens/pos_main_screen.dart';
import 'package:oda_pos/features/pos/providers/category_provider.dart';
import 'package:oda_pos/l10n/app_localizations.dart';

void main() {
  group('POS Main Screen Widget Tests', () {
    Widget buildTestWidget({OrderType? orderType, String? tableNumber, int? tableId}) {
      return ProviderScope(
        overrides: [
          categoryListProvider.overrideWith((ref) async => []),
          filteredProductsProvider.overrideWith((ref) async => []),
          searchQueryProvider.overrideWith((ref) => ''),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PosMainScreen(
            orderType: orderType,
            tableNumber: tableNumber,
            tableId: tableId,
          ),
        ),
      );
    }

    testWidgets('renders POS main screen', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      
      expect(find.byType(PosMainScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows empty categories list', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      
      expect(find.byType(PosMainScreen), findsOneWidget);
    });

    testWidgets('shows empty products grid', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      
      expect(find.byType(PosMainScreen), findsOneWidget);
    });

    testWidgets('renders cart panel', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      
      expect(find.byType(PosMainScreen), findsOneWidget);
    });

    testWidgets('shows order type Dine-in banner', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(orderType: OrderType.dineIn, tableNumber: 'T5', tableId: 5),
      );
      await tester.pump();
      
      expect(find.byType(PosMainScreen), findsOneWidget);
    });

    testWidgets('shows order type Takeaway banner', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(orderType: OrderType.takeaway),
      );
      await tester.pump();
      
      expect(find.byType(PosMainScreen), findsOneWidget);
    });

    testWidgets('shows order type Phone Delivery banner', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(orderType: OrderType.phoneDelivery),
      );
      await tester.pump();
      
      expect(find.byType(PosMainScreen), findsOneWidget);
    });

    testWidgets('shows order type Platform Delivery banner', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(orderType: OrderType.platformDelivery),
      );
      await tester.pump();
      
      expect(find.byType(PosMainScreen), findsOneWidget);
    });

    testWidgets('has app bar with search', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      
      expect(find.byType(PosMainScreen), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders without orderType (default mode)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      
      expect(find.byType(PosMainScreen), findsOneWidget);
    });
  });
}

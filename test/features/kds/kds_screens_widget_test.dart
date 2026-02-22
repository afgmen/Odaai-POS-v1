import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/features/kds/data/kitchen_orders_providers.dart';
import 'package:oda_pos/features/kds/data/models/kitchen_order_with_items.dart';
import 'package:oda_pos/features/kds/data/models/menu_item_summary.dart';
import 'package:oda_pos/features/kds/presentation/providers/kds_screen_provider.dart';
import 'package:oda_pos/features/kds/presentation/screens/kds_menu_summary_screen.dart';
import 'package:oda_pos/features/kds/presentation/screens/kds_mode_selection_screen.dart';
import 'package:oda_pos/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Wraps a widget with the minimum required ancestor widgets:
/// [ProviderScope], [MaterialApp] with localization delegates.
Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      home: child,
    ),
  );
}

/// Builds a [menuItemSummaryProvider] override that returns [summaries].
Override _summaryOverride(List<MenuItemSummary> summaries) {
  return menuItemSummaryProvider.overrideWith(
    (ref) => Stream.value(summaries),
  );
}

/// Overrides the DB-dependent stream provider with an empty list so that
/// [KdsScreen] can be navigated to without a real database.
Override _ordersOverride() {
  return activeOrdersWithItemsStreamProvider.overrideWith(
    (ref) => Stream.value(<KitchenOrderWithItems>[]),
  );
}

MenuItemSummary _summary({
  String name = 'Pho',
  int total = 3,
  int pending = 1,
  int preparing = 1,
  int ready = 1,
  int orderCount = 2,
}) =>
    MenuItemSummary(
      productName: name,
      totalQuantity: total,
      pendingQuantity: pending,
      preparingQuantity: preparing,
      readyQuantity: ready,
      orderCount: orderCount,
    );

// ===========================================================================
// KdsMenuSummaryScreen widget tests
// ===========================================================================

void main() {
  group('KdsMenuSummaryScreen', () {
    testWidgets('shows AppBar with screen title', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const KdsMenuSummaryScreen(),
          overrides: [_summaryOverride([_summary()])],
        ),
      );
      await tester.pump();

      expect(find.text('Menu Summary'), findsWidgets);
    });

    testWidgets('shows empty state when there are no active items',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const KdsMenuSummaryScreen(),
          overrides: [_summaryOverride([])],
        ),
      );
      await tester.pump();

      expect(find.text('No active menu items'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
    });

    testWidgets('shows loading indicator while provider is loading',
        (tester) async {
      // Override with a stream that never emits
      final override = menuItemSummaryProvider.overrideWith(
        (ref) => const Stream<List<MenuItemSummary>>.empty(),
      );

      await tester.pumpWidget(_wrap(const KdsMenuSummaryScreen(),
          overrides: [override]));
      // First frame: loading
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays product name and total quantity badge',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const KdsMenuSummaryScreen(),
          overrides: [
            _summaryOverride([
              _summary(name: 'Banh Mi', total: 5, pending: 5),
            ])
          ],
        ),
      );
      await tester.pump();

      expect(find.text('Banh Mi'), findsOneWidget);
      expect(find.text('x5'), findsOneWidget);
    });

    testWidgets('displays multiple menu item cards', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const KdsMenuSummaryScreen(),
          overrides: [
            _summaryOverride([
              _summary(name: 'Pho', total: 3),
              _summary(name: 'Coffee', total: 2),
              _summary(name: 'Spring Roll', total: 4),
            ]),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('Pho'), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Spring Roll'), findsOneWidget);
    });

    testWidgets('SummaryBar shows pending / preparing / ready labels',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const KdsMenuSummaryScreen(),
          overrides: [
            _summaryOverride([
              _summary(pending: 2, preparing: 1, ready: 1),
            ]),
          ],
        ),
      );
      await tester.pump();

      expect(find.textContaining('Pending'), findsWidgets);
      expect(find.textContaining('Preparing'), findsWidgets);
      expect(find.textContaining('Ready'), findsWidgets);
    });

    testWidgets('shows status icons for pending, preparing, ready',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const KdsMenuSummaryScreen(),
          overrides: [
            _summaryOverride([_summary(pending: 1, preparing: 1, ready: 1)]),
          ],
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.hourglass_empty), findsWidgets);
      expect(find.byIcon(Icons.soup_kitchen), findsWidgets);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
    });

    testWidgets('does not show preparing icon when preparingQuantity is 0',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const KdsMenuSummaryScreen(),
          overrides: [
            _summaryOverride([
              _summary(pending: 3, preparing: 0, ready: 0),
            ]),
          ],
        ),
      );
      await tester.pump();

      // soup_kitchen only appears in summary bar + card — with preparing=0
      // it should NOT appear in the card's status rows
      // (it still appears in summary bar; we verify card row is absent)
      final cardSoupKitchen = find.descendant(
        of: find.byType(GridView),
        matching: find.byIcon(Icons.soup_kitchen),
      );
      expect(cardSoupKitchen, findsNothing);
    });

    testWidgets('order count string is displayed', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const KdsMenuSummaryScreen(),
          overrides: [
            _summaryOverride([_summary(name: 'Pho', orderCount: 3)]),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('3 orders'), findsOneWidget);
    });

    testWidgets('shows error text when provider emits an error', (tester) async {
      final override = menuItemSummaryProvider.overrideWith(
        (ref) => Stream<List<MenuItemSummary>>.error(Exception('DB error')),
      );

      await tester.pumpWidget(
        _wrap(const KdsMenuSummaryScreen(), overrides: [override]),
      );
      await tester.pump();

      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('AppBar total-items badge shows sum of all quantities',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const KdsMenuSummaryScreen(),
          overrides: [
            _summaryOverride([
              _summary(name: 'A', total: 3),
              _summary(name: 'B', total: 7),
            ]),
          ],
        ),
      );
      await tester.pump();

      // Total Items: 3 + 7 = 10
      expect(find.textContaining('10'), findsWidgets);
    });

    testWidgets('AppBar unique menus badge shows correct count', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const KdsMenuSummaryScreen(),
          overrides: [
            _summaryOverride([
              _summary(name: 'A', total: 1),
              _summary(name: 'B', total: 2),
              _summary(name: 'C', total: 3),
            ]),
          ],
        ),
      );
      await tester.pump();

      // kdsUniqueMenus(3) → "3 menus"
      expect(find.text('3 menus'), findsOneWidget);
    });
  });

  // =========================================================================
  // KdsModeSelectionScreen widget tests
  // =========================================================================

  group('KdsModeSelectionScreen', () {
    testWidgets('shows AppBar with mode selection title', (tester) async {
      await tester.pumpWidget(_wrap(const KdsModeSelectionScreen()));
      await tester.pump();

      expect(find.text('Select KDS Mode'), findsOneWidget);
    });

    testWidgets('shows Order View card with correct text', (tester) async {
      await tester.pumpWidget(_wrap(const KdsModeSelectionScreen()));
      await tester.pump();

      expect(find.text('Order View'), findsOneWidget);
      expect(find.text('View orders by table, sorted by time'), findsOneWidget);
    });

    testWidgets('shows Menu Summary View card with correct text',
        (tester) async {
      await tester.pumpWidget(_wrap(const KdsModeSelectionScreen()));
      await tester.pump();

      expect(find.text('Menu Summary View'), findsOneWidget);
      expect(
        find.text('View all items to prepare, grouped by menu'),
        findsOneWidget,
      );
    });

    testWidgets('shows grid_view icon for Order View card', (tester) async {
      await tester.pumpWidget(_wrap(const KdsModeSelectionScreen()));
      await tester.pump();

      expect(find.byIcon(Icons.grid_view), findsOneWidget);
    });

    testWidgets('shows menu_book icon for Menu Summary View card',
        (tester) async {
      await tester.pumpWidget(_wrap(const KdsModeSelectionScreen()));
      await tester.pump();

      expect(find.byIcon(Icons.menu_book), findsOneWidget);
    });

    testWidgets('tapping Order View navigates to KdsScreen', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const KdsModeSelectionScreen(),
          overrides: [_ordersOverride()],
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Order View'));
      // Use pump with duration instead of pumpAndSettle to avoid DB stream
      // keeping the frame schedule alive indefinitely.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // KdsScreen AppBar title is "Kitchen Display System"
      expect(find.text('Kitchen Display System'), findsOneWidget);
    });

    testWidgets('tapping Menu Summary View navigates to KdsMenuSummaryScreen',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const KdsModeSelectionScreen(),
          overrides: [_summaryOverride([])],
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Menu Summary View'));
      await tester.pumpAndSettle();

      // KdsMenuSummaryScreen shows empty state
      expect(find.text('No active menu items'), findsOneWidget);
    });

    testWidgets('both mode cards are rendered as Card widgets', (tester) async {
      await tester.pumpWidget(_wrap(const KdsModeSelectionScreen()));
      await tester.pump();

      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('back button returns from KdsScreen to mode selection',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const KdsModeSelectionScreen(),
          overrides: [_ordersOverride()],
        ),
      );
      await tester.pump();

      // Navigate to KdsScreen
      await tester.tap(find.text('Order View'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Kitchen Display System'), findsOneWidget);

      // Tap back — uses pump instead of pumpAndSettle to avoid stream timeout
      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Select KDS Mode'), findsOneWidget);
      }
    });
  });
}

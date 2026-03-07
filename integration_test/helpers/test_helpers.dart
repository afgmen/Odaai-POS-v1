import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Common test helpers for integration tests
class TestHelpers {
  /// Find widget by text
  static Finder findByText(String text) => find.text(text);

  /// Find widget by key
  static Finder findByKey(String key) => find.byKey(Key(key));

  /// Find widget by type
  static Finder findByType<T>() => find.byType(T);

  /// Tap on widget
  static Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Enter text
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Wait for widget to appear
  static Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await tester.pumpAndSettle(timeout);
    expect(finder, findsOneWidget);
  }

  /// Scroll until visible
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder,
    Finder scrollable, {
    double delta = 100.0,
  }) async {
    await tester.scrollUntilVisible(finder, delta, scrollable: scrollable);
    await tester.pumpAndSettle();
  }

  /// Verify text exists
  static void verifyText(String text) {
    expect(find.text(text), findsOneWidget);
  }

  /// Verify text contains
  static void verifyTextContains(String text) {
    expect(find.textContaining(text), findsWidgets);
  }

  /// Verify widget exists
  static void verifyExists(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verify widget not exists
  static void verifyNotExists(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Take screenshot
  static Future<void> takeScreenshot(
    WidgetTester tester,
    String name,
  ) async {
    // Screenshot functionality
    await tester.pumpAndSettle();
  }
}

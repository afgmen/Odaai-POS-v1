// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:oda_pos/main.dart';
import 'package:oda_pos/features/user_guide/presentation/providers/tutorial_preference_provider.dart';

void main() {
  testWidgets('OdaPosApp smoke test', (WidgetTester tester) async {
    // Mock SharedPreferences for CI/headless environments
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(
            await SharedPreferences.getInstance(),
          ),
        ],
        child: const OdaPosApp(),
      ),
    );

    // Allow async providers to settle
    await tester.pump();

    // App launches on PinLoginScreen — verify visible elements
    expect(find.text('Oda POS'), findsOneWidget);
    expect(find.byIcon(Icons.store), findsOneWidget);
  });
}

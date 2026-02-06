// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:oda_pos/main.dart';

void main() {
  testWidgets('OdaPosApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: OdaPosApp(),
      ),
    );

    // POS 메인 화면 기본 요소 확인
    expect(find.text('Oda POS'), findsOneWidget);
    expect(find.text('장바구니'), findsOneWidget);
  });
}

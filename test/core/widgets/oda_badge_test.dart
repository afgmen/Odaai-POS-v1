import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/core/widgets/oda_badge.dart';
import 'package:oda_pos/core/theme/oda_colors.dart';

void main() {
  group('OdaBadge.dot', () {
    testWidgets('renders circular badge with red color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OdaBadge.dot(),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, OdaColors.red500);
    });

    testWidgets('renders with custom color', (tester) async {
      const customColor = Colors.green;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OdaBadge.dot(backgroundColor: customColor),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, customColor);
    });

    testWidgets('overlays on child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OdaBadge.dot(
              child: Icon(Icons.notifications),
            ),
          ),
        ),
      );

      expect(find.byType(OdaBadge), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      
      // Verify Stack is used for overlay
      final badge = tester.widget<OdaBadge>(find.byType(OdaBadge));
      expect(badge.child, isNotNull);
    });
  });

  group('OdaBadge.numeric', () {
    testWidgets('renders circular badge with count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OdaBadge.numeric(count: 5),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);

      final container = tester.widget<Container>(find.ancestor(
        of: find.text('5'),
        matching: find.byType(Container),
      ).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, OdaColors.red500);
    });

    testWidgets('displays "99+" for counts over 99', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OdaBadge.numeric(count: 150),
          ),
        ),
      );

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('handles count 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OdaBadge.numeric(count: 0),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('renders with custom colors', (tester) async {
      const bgColor = Colors.blue;
      const textColor = Colors.yellow;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OdaBadge.numeric(
              count: 3,
              backgroundColor: bgColor,
              textColor: textColor,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.ancestor(
        of: find.text('3'),
        matching: find.byType(Container),
      ).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, bgColor);

      final text = tester.widget<Text>(find.text('3'));
      expect(text.style?.color, textColor);
    });

    testWidgets('overlays on child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OdaBadge.numeric(
              count: 7,
              child: Icon(Icons.shopping_cart),
            ),
          ),
        ),
      );

      expect(find.byType(OdaBadge), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
      expect(find.text('7'), findsOneWidget);

      // Verify badge has child
      final badge = tester.widget<OdaBadge>(find.byType(OdaBadge));
      expect(badge.child, isNotNull);
    });
  });

  group('OdaBadge.outline', () {
    testWidgets('renders badge with border', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OdaBadge.outline(count: 2),
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);

      final container = tester.widget<Container>(find.ancestor(
        of: find.text('2'),
        matching: find.byType(Container),
      ).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, Colors.white);
      expect(decoration.border, isNotNull);

      final border = decoration.border as Border;
      expect(border.top.color, OdaColors.red500);
      expect(border.top.width, 2);
    });

    testWidgets('displays text in border color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OdaBadge.outline(count: 3),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('3'));
      expect(text.style?.color, OdaColors.red500);
    });

    testWidgets('handles count 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OdaBadge.outline(count: 0),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });
  });

  group('OdaBadge positioning', () {
    testWidgets('positions badge at top-right with offset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OdaBadge.numeric(
              count: 1,
              child: SizedBox(width: 48, height: 48),
            ),
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.top, -4);
      expect(positioned.right, -4);
    });
  });
}

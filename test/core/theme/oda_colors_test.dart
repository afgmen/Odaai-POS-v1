import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/core/theme/oda_colors.dart';

void main() {
  group('OdaColors Green Palette', () {
    test('green50 has correct value', () {
      expect(OdaColors.green60, const Color(0xFFF0FAF3));
    });

    test('green500 has correct value', () {
      expect(OdaColors.green500, const Color(0xFF40B65F));
    });

    test('green600 has correct value', () {
      expect(OdaColors.green600, const Color(0xFF35974F));
    });

    test('green700 has correct value', () {
      expect(OdaColors.green700, const Color(0xFF2A793F));
    });
  });

  group('OdaColors Blue Palette', () {
    test('blue60 has correct value', () {
      expect(OdaColors.blue100, const Color(0xFF9ED1FA));
    });

    test('blue400 has correct value', () {
      expect(OdaColors.blue400, const Color(0xFF2196F3));
    });

    test('blue500 has correct value', () {
      expect(OdaColors.blue500, const Color(0xFF0C85E9));
    });
  });

  group('OdaColors Red Palette', () {
    test('red60 has correct value', () {
      expect(OdaColors.red60, const Color(0xFFFFF6F6));
    });

    test('red500 has correct value', () {
      expect(OdaColors.red500, const Color(0xFFEF2E2E));
    });

    test('red600 has correct value', () {
      expect(OdaColors.red600, const Color(0xFFE41111));
    });
  });

  group('OdaColors Orange Palette', () {
    test('orange500 has correct value', () {
      expect(OdaColors.orange500, const Color(0xFFE58435));
    });

    test('orange600 has correct value', () {
      expect(OdaColors.orange600, const Color(0xFFD9711C));
    });
  });

  group('OdaColors Neutral Palette', () {
    test('neutral05 has correct value', () {
      expect(OdaColors.neutral05, const Color(0xFFF9FAFC));
    });

    test('neutral100 has correct value', () {
      expect(OdaColors.neutral100, const Color(0xFF9F9DAA));
    });

    test('neutral500 has correct value', () {
      expect(OdaColors.neutral500, const Color(0xFF4E4C57));
    });

    test('neutral600 has correct value', () {
      expect(OdaColors.neutral600, const Color(0xFF373435));
    });
  });

  group('OdaColors Grey Palette', () {
    test('grey40 has correct value', () {
      expect(OdaColors.grey40, const Color(0xFFF5F5F5));
    });

    test('grey60 has correct value', () {
      expect(OdaColors.grey60, const Color(0xFFE0E0E0));
    });

    test('grey100 has correct value', () {
      expect(OdaColors.grey100, const Color(0xFFB8B8B8));
    });
  });

  group('OdaColors Monochrome', () {
    test('white has correct value', () {
      expect(OdaColors.white, const Color(0xFFFFFFFF));
    });

    test('black has correct value', () {
      expect(OdaColors.black, const Color(0xFF000000));
    });
  });

  group('OdaColors Color Validation', () {
    test('all primary colors are non-null', () {
      expect(OdaColors.green500, isNotNull);
      expect(OdaColors.blue400, isNotNull);
      expect(OdaColors.red500, isNotNull);
      expect(OdaColors.orange500, isNotNull);
      expect(OdaColors.neutral100, isNotNull);
      expect(OdaColors.grey40, isNotNull);
    });

    test('all colors are Color instances', () {
      expect(OdaColors.green600, isA<Color>());
      expect(OdaColors.blue500, isA<Color>());
      expect(OdaColors.red600, isA<Color>());
      expect(OdaColors.orange600, isA<Color>());
      expect(OdaColors.neutral500, isA<Color>());
      expect(OdaColors.grey100, isA<Color>());
    });
  });
}

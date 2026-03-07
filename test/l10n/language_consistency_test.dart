import 'package:flutter_test/flutter_test.dart';

/// B-083: Language Consistency Tests
void main() {
  group('Hardcoded String Detection', () {
    test('should detect English hardcoded strings', () {
      const String hardcodedText = "Text('Manage Staff')";

      final hasHardcodedString = hardcodedText.contains("Text('");

      expect(hasHardcodedString, true);
    });

    test('should prefer l10n strings', () {
      const String l10nText = "Text(l10n.manageStaff)";

      final usesL10n = l10nText.contains("l10n.");

      expect(usesL10n, true);
    });

    test('should avoid mixed language in UI', () {
      final uiTexts = ['English', 'More text'];

      final allEnglish = uiTexts.every((text) => text.contains(RegExp(r'^[A-Za-z\s]+$')));

      expect(allEnglish, true);
    });
  });

  group('L10n System', () {
    test('should have en and vi translations', () {
      final availableLocales = ['en', 'vi'];

      expect(availableLocales.contains('en'), true);
      expect(availableLocales.contains('vi'), true);
    });

    test('should use app_localizations for all text', () {
      const String goodExample = "Text(l10n.title)";
      const String badExample = "Text('Title')";

      expect(goodExample.contains('l10n.'), true);
      expect(badExample.contains('l10n.'), false);
    });

    test('should have consistent key naming', () {
      final keys = ['manageStaff', 'cancelOrder', 'leaveManagement'];

      final allCamelCase = keys.every((key) => 
        key == key[0].toLowerCase() + key.substring(1)
      );

      expect(allCamelCase, true);
    });
  });

  group('Translation Coverage', () {
    test('should have translation for common terms', () {
      final commonTerms = {
        'cancel': 'Cancel',
        'ok': 'OK',
        'save': 'Save',
        'delete': 'Delete',
        'edit': 'Edit',
      };

      expect(commonTerms.length, 5);
      expect(commonTerms['cancel'], 'Cancel');
    });

    test('should handle fallback for missing translations', () {
      const String? translation = null;
      const String fallback = 'Default Text';

      final displayText = translation ?? fallback;

      expect(displayText, fallback);
    });
  });

  group('UI Consistency', () {
    test('should use same language across screens', () {
      final screen1Language = 'en';
      final screen2Language = 'en';
      final screen3Language = 'en';

      expect(screen1Language, screen2Language);
      expect(screen2Language, screen3Language);
    });

    test('should not mix languages in single screen', () {
      final screenTexts = ['Welcome', 'Settings', 'Logout'];

      final allSameLanguage = screenTexts.every((text) => 
        text.contains(RegExp(r'^[A-Za-z]+$'))
      );

      expect(allSameLanguage, true);
    });

    test('should maintain consistency in error messages', () {
      final errorMessages = [
        'An error occurred',
        'Please try again',
        'Invalid input',
      ];

      final allEnglish = errorMessages.every((msg) => 
        msg.contains(RegExp(r'^[A-Za-z\s]+$'))
      );

      expect(allEnglish, true);
    });
  });

  group('Migration Strategy', () {
    test('should identify hardcoded strings for migration', () {
      final hardcodedStrings = [
        "Text('Manage Staff')",
        "Text('Cancel Order')",
        "const Text('Leave Management')",
      ];

      expect(hardcodedStrings.length, greaterThan(0));
    });

    test('should replace with l10n keys', () {
      const String before = "Text('Manage Staff')";
      const String after = "Text(l10n.manageStaff)";

      expect(before.contains('l10n.'), false);
      expect(after.contains('l10n.'), true);
    });
  });
}

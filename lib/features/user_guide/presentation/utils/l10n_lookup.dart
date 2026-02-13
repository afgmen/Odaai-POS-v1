import '../../../../l10n/app_localizations.dart';

/// Utility to lookup localized strings by key
class L10nLookup {
  /// Get localized string by key
  /// This is a simple implementation that handles tutorial keys
  static String getString(AppLocalizations l10n, String key) {
    // Map of keys to getter functions
    final Map<String, String Function(AppLocalizations)> keyMap = {
      // General tutorial keys
      'userGuide': (l) => l.userGuide,
      'tutorial': (l) => l.tutorial,
      'tutorialSkip': (l) => l.tutorialSkip,
      'tutorialNext': (l) => l.tutorialNext,
      'tutorialPrevious': (l) => l.tutorialPrevious,
      'tutorialFinish': (l) => l.tutorialFinish,
      'tutorialDontShowAgain': (l) => l.tutorialDontShowAgain,

      // Daily Closing tutorial keys
      'tutorial_daily_closing_welcome_title': (l) =>
          l.tutorial_daily_closing_welcome_title,
      'tutorial_daily_closing_welcome_desc': (l) =>
          l.tutorial_daily_closing_welcome_desc,
      'tutorial_daily_closing_date_title': (l) =>
          l.tutorial_daily_closing_date_title,
      'tutorial_daily_closing_date_desc': (l) =>
          l.tutorial_daily_closing_date_desc,
      'tutorial_daily_closing_summary_title': (l) =>
          l.tutorial_daily_closing_summary_title,
      'tutorial_daily_closing_summary_desc': (l) =>
          l.tutorial_daily_closing_summary_desc,
      'tutorial_daily_closing_payment_title': (l) =>
          l.tutorial_daily_closing_payment_title,
      'tutorial_daily_closing_payment_desc': (l) =>
          l.tutorial_daily_closing_payment_desc,
      'tutorial_daily_closing_cash_title': (l) =>
          l.tutorial_daily_closing_cash_title,
      'tutorial_daily_closing_cash_desc': (l) =>
          l.tutorial_daily_closing_cash_desc,
      'tutorial_daily_closing_actual_cash_title': (l) =>
          l.tutorial_daily_closing_actual_cash_title,
      'tutorial_daily_closing_actual_cash_desc': (l) =>
          l.tutorial_daily_closing_actual_cash_desc,
      'tutorial_daily_closing_notes_title': (l) =>
          l.tutorial_daily_closing_notes_title,
      'tutorial_daily_closing_notes_desc': (l) =>
          l.tutorial_daily_closing_notes_desc,
      'tutorial_daily_closing_perform_title': (l) =>
          l.tutorial_daily_closing_perform_title,
      'tutorial_daily_closing_perform_desc': (l) =>
          l.tutorial_daily_closing_perform_desc,
      'tutorial_daily_closing_history_title': (l) =>
          l.tutorial_daily_closing_history_title,
      'tutorial_daily_closing_history_desc': (l) =>
          l.tutorial_daily_closing_history_desc,
    };

    // Try to get the value from the map
    final getter = keyMap[key];
    if (getter != null) {
      return getter(l10n);
    }

    // Fallback: return the key itself if not found
    return key;
  }
}

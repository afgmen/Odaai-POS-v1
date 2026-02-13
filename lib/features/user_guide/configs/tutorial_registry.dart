import '../domain/models/tutorial_config.dart';
import 'daily_closing_tutorial.dart';

/// Central registry for all tutorials in the app
class TutorialRegistry {
  /// Map of tutorial IDs to their configurations
  static final Map<String, TutorialConfig> _tutorials = {
    'daily_closing_tutorial': DailyClosingTutorial.config,
    // Add more tutorials here as they are created
    // 'order_management_tutorial': OrderManagementTutorial.config,
    // 'dashboard_tutorial': DashboardTutorial.config,
  };

  /// Get a tutorial configuration by ID
  static TutorialConfig? getTutorial(String tutorialId) {
    return _tutorials[tutorialId];
  }

  /// Get all available tutorials
  static List<TutorialConfig> getAllTutorials() {
    return _tutorials.values.toList();
  }

  /// Get tutorials for a specific screen
  static List<TutorialConfig> getTutorialsForScreen(String screenName) {
    return _tutorials.values
        .where((config) => config.screenName == screenName)
        .toList();
  }

  /// Check if a tutorial exists
  static bool hasTutorial(String tutorialId) {
    return _tutorials.containsKey(tutorialId);
  }

  /// Get all tutorial IDs
  static List<String> getAllTutorialIds() {
    return _tutorials.keys.toList();
  }
}

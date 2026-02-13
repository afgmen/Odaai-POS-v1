import '../datasources/tutorial_preference_local_source.dart';
import '../models/tutorial_preference.dart';

/// Repository for managing tutorial preferences
class TutorialRepository {
  final TutorialPreferenceLocalSource _localSource;

  TutorialRepository(this._localSource);

  /// Get current tutorial preferences
  Future<TutorialPreference> getPreference() async {
    return await _localSource.getPreference();
  }

  /// Mark a tutorial as completed
  Future<void> markCompleted(String tutorialId, String version) async {
    final preference = await getPreference();
    final updated = preference.markCompleted(tutorialId, version);
    await _localSource.savePreference(updated);
  }

  /// Mark a tutorial to never show again
  Future<void> markNeverShowAgain(String tutorialId) async {
    final preference = await getPreference();
    final updated = preference.markNeverShowAgain(tutorialId);
    await _localSource.savePreference(updated);
  }

  /// Reset all tutorials
  Future<void> resetAll() async {
    final preference = await getPreference();
    final updated = preference.resetAll();
    await _localSource.savePreference(updated);
  }

  /// Reset a specific tutorial
  Future<void> resetTutorial(String tutorialId) async {
    final preference = await getPreference();
    final updated = preference.resetTutorial(tutorialId);
    await _localSource.savePreference(updated);
  }

  /// Check if a tutorial should be shown
  Future<bool> shouldShow(String tutorialId) async {
    final preference = await getPreference();
    return preference.shouldShow(tutorialId);
  }

  /// Check if a tutorial has been completed
  Future<bool> isCompleted(String tutorialId) async {
    final preference = await getPreference();
    return preference.isCompleted(tutorialId);
  }

  /// Clear all preferences
  Future<void> clearAll() async {
    await _localSource.clearPreference();
  }
}

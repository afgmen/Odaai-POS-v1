import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/tutorial_preference_local_source.dart';
import '../../data/models/tutorial_preference.dart';
import '../../data/repositories/tutorial_repository.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

/// Provider for TutorialPreferenceLocalSource
final tutorialPreferenceLocalSourceProvider = Provider<TutorialPreferenceLocalSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TutorialPreferenceLocalSource(prefs);
});

/// Provider for TutorialRepository
final tutorialRepositoryProvider = Provider<TutorialRepository>((ref) {
  final localSource = ref.watch(tutorialPreferenceLocalSourceProvider);
  return TutorialRepository(localSource);
});

/// State notifier for tutorial preferences
class TutorialPreferenceNotifier extends StateNotifier<AsyncValue<TutorialPreference>> {
  final TutorialRepository _repository;

  TutorialPreferenceNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    state = const AsyncValue.loading();
    try {
      final preference = await _repository.getPreference();
      state = AsyncValue.data(preference);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Mark a tutorial as completed
  Future<void> markCompleted(String tutorialId, String version) async {
    await _repository.markCompleted(tutorialId, version);
    await _loadPreference();
  }

  /// Mark a tutorial to never show again
  Future<void> markNeverShowAgain(String tutorialId) async {
    await _repository.markNeverShowAgain(tutorialId);
    await _loadPreference();
  }

  /// Reset all tutorials
  Future<void> resetAll() async {
    await _repository.resetAll();
    await _loadPreference();
  }

  /// Reset a specific tutorial
  Future<void> resetTutorial(String tutorialId) async {
    await _repository.resetTutorial(tutorialId);
    await _loadPreference();
  }

  /// Refresh preferences from storage
  Future<void> refresh() async {
    await _loadPreference();
  }
}

/// Provider for tutorial preference state
final tutorialPreferenceProvider =
    StateNotifierProvider<TutorialPreferenceNotifier, AsyncValue<TutorialPreference>>((ref) {
  final repository = ref.watch(tutorialRepositoryProvider);
  return TutorialPreferenceNotifier(repository);
});

/// Provider to check if a specific tutorial should be shown
final shouldShowTutorialProvider = Provider.family<AsyncValue<bool>, String>((ref, tutorialId) {
  final preferenceAsync = ref.watch(tutorialPreferenceProvider);
  return preferenceAsync.when(
    data: (preference) => AsyncValue.data(preference.shouldShow(tutorialId)),
    loading: () => const AsyncValue.loading(),
    error: (e, stack) => AsyncValue.error(e, stack),
  );
});

/// Provider to check if a tutorial is completed
final isTutorialCompletedProvider = Provider.family<AsyncValue<bool>, String>((ref, tutorialId) {
  final preferenceAsync = ref.watch(tutorialPreferenceProvider);
  return preferenceAsync.when(
    data: (preference) => AsyncValue.data(preference.isCompleted(tutorialId)),
    loading: () => const AsyncValue.loading(),
    error: (e, stack) => AsyncValue.error(e, stack),
  );
});

/// Provider to check if this is first launch
final isFirstLaunchProvider = Provider<AsyncValue<bool>>((ref) {
  final preferenceAsync = ref.watch(tutorialPreferenceProvider);
  return preferenceAsync.when(
    data: (preference) => AsyncValue.data(preference.isFirstLaunch),
    loading: () => const AsyncValue.loading(),
    error: (e, stack) => AsyncValue.error(e, stack),
  );
});

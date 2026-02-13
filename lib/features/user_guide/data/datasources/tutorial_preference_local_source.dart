import 'package:shared_preferences/shared_preferences.dart';
import '../models/tutorial_preference.dart';

/// Local data source for tutorial preferences using SharedPreferences
class TutorialPreferenceLocalSource {
  static const String _keyPreference = 'tutorial_preference';

  final SharedPreferences _prefs;

  TutorialPreferenceLocalSource(this._prefs);

  /// Get tutorial preferences
  Future<TutorialPreference> getPreference() async {
    final jsonString = _prefs.getString(_keyPreference);
    if (jsonString == null) {
      return TutorialPreference.initial();
    }
    return TutorialPreference.fromJsonString(jsonString);
  }

  /// Save tutorial preferences
  Future<void> savePreference(TutorialPreference preference) async {
    await _prefs.setString(_keyPreference, preference.toJsonString());
  }

  /// Clear all tutorial preferences
  Future<void> clearPreference() async {
    await _prefs.remove(_keyPreference);
  }
}

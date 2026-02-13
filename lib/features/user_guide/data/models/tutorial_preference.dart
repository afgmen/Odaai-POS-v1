import 'dart:convert';

/// User preferences for tutorials
class TutorialPreference {
  /// Set of completed tutorial IDs
  final Set<String> completedTutorials;

  /// Whether this is the first app launch
  final bool isFirstLaunch;

  /// Map of tutorial IDs to "never show again" flags
  final Map<String, bool> neverShowAgain;

  /// Map of tutorial IDs to last seen versions
  final Map<String, String> lastSeenVersions;

  const TutorialPreference({
    required this.completedTutorials,
    required this.isFirstLaunch,
    required this.neverShowAgain,
    required this.lastSeenVersions,
  });

  /// Default preferences for first-time users
  factory TutorialPreference.initial() {
    return const TutorialPreference(
      completedTutorials: {},
      isFirstLaunch: true,
      neverShowAgain: {},
      lastSeenVersions: {},
    );
  }

  /// Check if a tutorial has been completed
  bool isCompleted(String tutorialId) {
    return completedTutorials.contains(tutorialId);
  }

  /// Check if a tutorial should be shown
  bool shouldShow(String tutorialId) {
    return !(neverShowAgain[tutorialId] ?? false) && !isCompleted(tutorialId);
  }

  /// Mark a tutorial as completed
  TutorialPreference markCompleted(String tutorialId, String version) {
    return TutorialPreference(
      completedTutorials: {...completedTutorials, tutorialId},
      isFirstLaunch: false,
      neverShowAgain: neverShowAgain,
      lastSeenVersions: {...lastSeenVersions, tutorialId: version},
    );
  }

  /// Mark a tutorial to never show again
  TutorialPreference markNeverShowAgain(String tutorialId) {
    return TutorialPreference(
      completedTutorials: completedTutorials,
      isFirstLaunch: false,
      neverShowAgain: {...neverShowAgain, tutorialId: true},
      lastSeenVersions: lastSeenVersions,
    );
  }

  /// Reset all tutorials
  TutorialPreference resetAll() {
    return TutorialPreference.initial().copyWith(isFirstLaunch: false);
  }

  /// Reset a specific tutorial
  TutorialPreference resetTutorial(String tutorialId) {
    final newCompleted = Set<String>.from(completedTutorials);
    newCompleted.remove(tutorialId);

    final newNeverShow = Map<String, bool>.from(neverShowAgain);
    newNeverShow.remove(tutorialId);

    final newVersions = Map<String, String>.from(lastSeenVersions);
    newVersions.remove(tutorialId);

    return TutorialPreference(
      completedTutorials: newCompleted,
      isFirstLaunch: isFirstLaunch,
      neverShowAgain: newNeverShow,
      lastSeenVersions: newVersions,
    );
  }

  /// Copy with new values
  TutorialPreference copyWith({
    Set<String>? completedTutorials,
    bool? isFirstLaunch,
    Map<String, bool>? neverShowAgain,
    Map<String, String>? lastSeenVersions,
  }) {
    return TutorialPreference(
      completedTutorials: completedTutorials ?? this.completedTutorials,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      neverShowAgain: neverShowAgain ?? this.neverShowAgain,
      lastSeenVersions: lastSeenVersions ?? this.lastSeenVersions,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'completedTutorials': completedTutorials.toList(),
      'isFirstLaunch': isFirstLaunch,
      'neverShowAgain': neverShowAgain,
      'lastSeenVersions': lastSeenVersions,
    };
  }

  /// Create from JSON
  factory TutorialPreference.fromJson(Map<String, dynamic> json) {
    return TutorialPreference(
      completedTutorials: Set<String>.from(json['completedTutorials'] ?? []),
      isFirstLaunch: json['isFirstLaunch'] ?? true,
      neverShowAgain: Map<String, bool>.from(json['neverShowAgain'] ?? {}),
      lastSeenVersions: Map<String, String>.from(json['lastSeenVersions'] ?? {}),
    );
  }

  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON string
  factory TutorialPreference.fromJsonString(String jsonString) {
    return TutorialPreference.fromJson(jsonDecode(jsonString));
  }
}

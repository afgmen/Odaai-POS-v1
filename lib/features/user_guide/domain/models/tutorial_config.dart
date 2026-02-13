import 'tutorial_step.dart';

/// Configuration for a complete tutorial for a specific screen
class TutorialConfig {
  /// Unique identifier for this tutorial
  final String tutorialId;

  /// Name of the screen this tutorial is for
  final String screenName;

  /// List of tutorial steps in order
  final List<TutorialStep> steps;

  /// Whether to show this tutorial on first launch
  final bool showOnFirstLaunch;

  /// Version of this tutorial (for future updates)
  final String version;

  const TutorialConfig({
    required this.tutorialId,
    required this.screenName,
    required this.steps,
    this.showOnFirstLaunch = false,
    this.version = '1.0.0',
  });

  /// Get sorted steps by order
  List<TutorialStep> get sortedSteps {
    final sorted = List<TutorialStep>.from(steps);
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }

  /// Get step count
  int get stepCount => steps.length;

  /// Check if tutorial has steps
  bool get hasSteps => steps.isNotEmpty;
}

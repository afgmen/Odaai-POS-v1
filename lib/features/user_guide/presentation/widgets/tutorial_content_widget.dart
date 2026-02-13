import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../domain/models/tutorial_config.dart';
import '../providers/tutorial_preference_provider.dart';
import '../utils/l10n_lookup.dart';
import '../../../../l10n/app_localizations.dart';

/// Widget that manages and displays tutorials using tutorial_coach_mark
class TutorialContentWidget extends ConsumerStatefulWidget {
  /// The tutorial configuration to display
  final TutorialConfig config;

  /// Callback when tutorial is completed
  final VoidCallback? onCompleted;

  /// Callback when tutorial is skipped
  final VoidCallback? onSkipped;

  /// Whether to auto-start the tutorial
  final bool autoStart;

  const TutorialContentWidget({
    super.key,
    required this.config,
    this.onCompleted,
    this.onSkipped,
    this.autoStart = false,
  });

  @override
  ConsumerState<TutorialContentWidget> createState() => _TutorialContentWidgetState();
}

class _TutorialContentWidgetState extends ConsumerState<TutorialContentWidget> {
  TutorialCoachMark? _tutorialCoachMark;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndShowTutorial();
      });
    }
  }

  @override
  void dispose() {
    _tutorialCoachMark?.finish();
    super.dispose();
  }

  Future<void> _checkAndShowTutorial() async {
    final repository = ref.read(tutorialRepositoryProvider);
    final shouldShow = await repository.shouldShow(widget.config.tutorialId);

    if (shouldShow && mounted) {
      showTutorial();
    }
  }

  /// Manually show the tutorial
  void showTutorial() {
    if (!widget.config.hasSteps) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    // Convert TutorialSteps to TargetFocus objects
    final targets = widget.config.sortedSteps.map((step) {
      return step.toTargetFocus(
        title: _getLocalizedString(l10n, step.titleKey),
        description: _getLocalizedString(l10n, step.descriptionKey),
        skipText: l10n.tutorialSkip,
        nextText: l10n.tutorialNext,
      );
    }).toList();

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      paddingFocus: 10,
      opacityShadow: 0.8,
      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      onFinish: () {
        _onTutorialFinished();
      },
      onSkip: () {
        _onTutorialSkipped();
        return true;
      },
    );

    _tutorialCoachMark?.show(context: context);
  }

  void _onTutorialFinished() {
    final notifier = ref.read(tutorialPreferenceProvider.notifier);
    notifier.markCompleted(widget.config.tutorialId, widget.config.version);
    widget.onCompleted?.call();
  }

  void _onTutorialSkipped() {
    widget.onSkipped?.call();
  }

  String _getLocalizedString(AppLocalizations l10n, String key) {
    return L10nLookup.getString(l10n, key);
  }

  @override
  Widget build(BuildContext context) {
    // This widget doesn't render anything visible
    // It only manages the tutorial lifecycle
    return const SizedBox.shrink();
  }
}

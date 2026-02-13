import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/tutorial_config.dart';
import 'tutorial_content_widget.dart';
import '../../../../l10n/app_localizations.dart';

/// A help button that triggers a tutorial when pressed
class HelpButton extends ConsumerWidget {
  /// The tutorial configuration to show
  final TutorialConfig config;

  /// Icon to display in the button
  final IconData icon;

  /// Tooltip text
  final String? tooltip;

  /// Button style (icon, outlined, or filled)
  final HelpButtonStyle style;

  const HelpButton({
    super.key,
    required this.config,
    this.icon = Icons.help_outline,
    this.tooltip,
    this.style = HelpButtonStyle.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final effectiveTooltip = tooltip ?? l10n.userGuide;

    // Create a GlobalKey to access TutorialContentWidget's state
    final tutorialKey = GlobalKey<State<TutorialContentWidget>>();

    return Stack(
      children: [
        // Hidden tutorial widget
        TutorialContentWidget(
          key: tutorialKey,
          config: config,
          autoStart: false,
        ),
        // Visible button
        _buildButton(context, effectiveTooltip, () {
          // Trigger the tutorial when button is pressed
          final tutorialState = tutorialKey.currentState;
          if (tutorialState != null && tutorialState is dynamic) {
            (tutorialState as dynamic).showTutorial();
          }
        }),
      ],
    );
  }

  Widget _buildButton(BuildContext context, String tooltip, VoidCallback onPressed) {
    switch (style) {
      case HelpButtonStyle.icon:
        return IconButton(
          icon: Icon(icon),
          tooltip: tooltip,
          onPressed: onPressed,
        );
      case HelpButtonStyle.outlined:
        return OutlinedButton.icon(
          icon: Icon(icon),
          label: Text(tooltip),
          onPressed: onPressed,
        );
      case HelpButtonStyle.filled:
        return FilledButton.icon(
          icon: Icon(icon),
          label: Text(tooltip),
          onPressed: onPressed,
        );
    }
  }
}

/// Style options for HelpButton
enum HelpButtonStyle {
  /// Icon button only
  icon,

  /// Outlined button with icon and label
  outlined,

  /// Filled button with icon and label
  filled,
}

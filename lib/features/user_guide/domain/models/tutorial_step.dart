import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// Represents a single step in a tutorial
class TutorialStep {
  /// Unique identifier for this step
  final String id;

  /// GlobalKey that targets the widget to highlight
  final GlobalKey targetKey;

  /// L10n key for the step title
  final String titleKey;

  /// L10n key for the step description
  final String descriptionKey;

  /// Position where the content should appear relative to the target
  final ContentAlign position;

  /// Shape of the highlight area
  final ShapeLightFocus shape;

  /// Whether user can skip this step
  final bool enableSkip;

  /// Order of this step in the tutorial sequence
  final int order;

  const TutorialStep({
    required this.id,
    required this.targetKey,
    required this.titleKey,
    required this.descriptionKey,
    this.position = ContentAlign.bottom,
    this.shape = ShapeLightFocus.RRect,
    this.enableSkip = true,
    required this.order,
  });

  /// Convert to TargetFocus for tutorial_coach_mark package
  TargetFocus toTargetFocus({
    required String title,
    required String description,
    required String skipText,
    required String nextText,
    VoidCallback? onClickTarget,
    VoidCallback? onClickTargetWithTapPosition,
    VoidCallback? onClickOverlay,
  }) {
    return TargetFocus(
      identify: id,
      keyTarget: targetKey,
      alignSkip: Alignment.topRight,
      enableOverlayTab: true,
      enableTargetTab: true,
      shape: shape,
      contents: [
        TargetContent(
          align: position,
          builder: (context, controller) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (enableSkip)
                        TextButton(
                          onPressed: () => controller.skip(),
                          child: Text(
                            skipText,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => controller.next(),
                        child: Text(nextText),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

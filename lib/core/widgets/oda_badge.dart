import 'package:flutter/material.dart';
import '../theme/oda_colors.dart';

enum BadgeType { dot, numeric, outline }

/// OdaBadge widget - Oda Design System Phase 3-B
/// 
/// Provides three variants of badges:
/// - Dot: 8x8px circular indicator
/// - Numeric: 24x24px circular badge with count
/// - Outline: 24x24px badge with border
class OdaBadge extends StatelessWidget {
  final BadgeType type;
  final int? count;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? child;

  const OdaBadge({
    super.key,
    this.type = BadgeType.numeric,
    this.count,
    this.backgroundColor,
    this.textColor,
    this.child,
  });

  /// Creates a dot badge (8x8px)
  const OdaBadge.dot({
    super.key,
    this.backgroundColor,
    this.child,
  })  : type = BadgeType.dot,
        count = null,
        textColor = null;

  /// Creates a numeric badge (24x24px) with count
  const OdaBadge.numeric({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
    this.child,
  }) : type = BadgeType.numeric;

  /// Creates an outline badge (24x24px) with border
  const OdaBadge.outline({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
    this.child,
  }) : type = BadgeType.outline;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? OdaColors.red500; // #EF2E2E
    final fgColor = textColor ?? Colors.white;

    Widget badge;

    switch (type) {
      case BadgeType.dot:
        badge = Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
        );
        break;

      case BadgeType.numeric:
        final displayCount = count ?? 0;
        final countText = displayCount > 99 ? '99+' : '$displayCount';
        
        badge = Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Text(
            countText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fgColor,
              height: 1.0,
            ),
          ),
        );
        break;

      case BadgeType.outline:
        final displayCount = count ?? 0;
        final countText = displayCount > 99 ? '99+' : '$displayCount';
        
        badge = Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: bgColor, width: 2),
          ),
          child: Text(
            countText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: bgColor,
              height: 1.0,
            ),
          ),
        );
        break;
    }

    if (child != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          child!,
          Positioned(
            top: -4,
            right: -4,
            child: badge,
          ),
        ],
      );
    }

    return badge;
  }
}

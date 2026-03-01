import 'package:flutter/material.dart';
import '../theme/oda_colors.dart';

/// SnackBarHelper - Oda Design System Phase 3-B
/// 
/// Provides consistent SnackBar variants with optional actions
class SnackBarHelper {
  /// Shows a success SnackBar (green background)
  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
    bool showCloseIcon = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: OdaColors.green600, // #35974F
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction ?? () {},
                textColor: Colors.white,
              )
            : null,
        duration: duration,
        showCloseIcon: showCloseIcon,
      ),
    );
  }

  /// Shows an error SnackBar (red background)
  static void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
    bool showCloseIcon = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: OdaColors.red500, // #EF2E2E
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction ?? () {},
                textColor: Colors.white,
              )
            : null,
        duration: duration,
        showCloseIcon: showCloseIcon,
      ),
    );
  }

  /// Shows an info SnackBar (blue background)
  static void showInfo(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
    bool showCloseIcon = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: OdaColors.blue400, // #2196F3
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction ?? () {},
                textColor: Colors.white,
              )
            : null,
        duration: duration,
        showCloseIcon: showCloseIcon,
      ),
    );
  }

  /// Shows a dark SnackBar (Oda style) with green action
  static void showDark(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
    bool showCloseIcon = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF222227), // Oda dark bg
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction ?? () {},
                textColor: OdaColors.green500, // #40B65F (Oda action green)
              )
            : null,
        duration: duration,
        showCloseIcon: showCloseIcon,
        closeIconColor: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }
}

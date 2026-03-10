import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/oda_colors.dart';

/// SnackBarHelper - Oda Design System Phase 3-B
///
/// Provides consistent SnackBar variants with optional actions.
/// Also contains [sanitizeError] to prevent raw SQL/stack traces
/// from leaking into the UI.
class SnackBarHelper {
  /// Converts a raw exception into a user-friendly message.
  ///
  /// - In debug mode: shows full error detail for developers.
  /// - In release mode: hides raw SQL / stack traces and returns
  ///   a generic message instead.
  static String sanitizeError(Object e) {
    final raw = e.toString();

    // Always show full detail in debug builds (developer convenience)
    if (kDebugMode) return raw;

    // Detect DB / SQL errors
    if (_isSqliteError(raw)) {
      if (raw.contains('UNIQUE') && raw.contains('table_number')) {
        return 'A table with this number already exists.';
      }
      if (raw.contains('UNIQUE')) {
        return 'A duplicate entry was detected. Please check your input.';
      }
      if (raw.contains('FOREIGN KEY')) {
        return 'This item is linked to other records and cannot be modified.';
      }
      if (raw.contains('NOT NULL')) {
        return 'A required field is missing. Please fill in all required fields.';
      }
      return 'A database error occurred. Please try again.';
    }

    // Network / connection errors
    if (raw.contains('SocketException') ||
        raw.contains('Connection refused') ||
        raw.contains('Network is unreachable')) {
      return 'Network error. Please check your connection.';
    }

    // File / permission errors
    if (raw.contains('Permission denied') || raw.contains('FileSystemException')) {
      return 'File access error. Please check app permissions.';
    }

    // Generic fallback — strip exception class prefix
    final cleaned = raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
    // If the cleaned message is still technical (contains '::' or stack frames),
    // return a fully generic message
    if (cleaned.contains('::') || cleaned.contains('\n') || cleaned.length > 200) {
      return 'An unexpected error occurred. Please try again.';
    }
    return cleaned;
  }

  /// Returns true if [raw] looks like a SQLite / Drift error string.
  static bool _isSqliteError(String raw) {
    return raw.contains('SqliteException') ||
        raw.contains('DriftWrapped') ||
        raw.contains('sqlite3') ||
        raw.contains('SQLITE_') ||
        raw.contains('UNIQUE constraint') ||
        raw.contains('FOREIGN KEY constraint') ||
        raw.contains('NOT NULL constraint');
  }

  /// Convenience: sanitize [e] then show an error SnackBar.
  static void showSanitizedError(
    BuildContext context,
    Object e, {
    Duration duration = const Duration(seconds: 4),
  }) {
    showError(context, sanitizeError(e), duration: duration);
  }
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

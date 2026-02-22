import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';

/// Quick button to set an employee as OWNER with RBAC enabled
/// Shows in employee cards for easy RBAC setup
class QuickSetOwnerButton extends ConsumerStatefulWidget {
  final Employee employee;

  const QuickSetOwnerButton({
    super.key,
    required this.employee,
  });

  @override
  ConsumerState<QuickSetOwnerButton> createState() => _QuickSetOwnerButtonState();
}

class _QuickSetOwnerButtonState extends ConsumerState<QuickSetOwnerButton> {
  bool _isProcessing = false;

  Future<void> _setAsOwner() async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield, color: AppTheme.primary),
            SizedBox(width: 12),
            Text('Set as OWNER?'),
          ],
        ),
        content: Text(
          'This will:\n'
          '• Enable RBAC system\n'
          '• Set ${widget.employee.name} as OWNER\n'
          '• Give full access to all features\n'
          '• Show Security Settings in Settings menu\n\n'
          'You\'ll need to restart the app after this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
            child: const Text('Set as OWNER'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);

    try {
      final db = ref.read(databaseProvider);

      // 1. Enable RBAC
      await db.customStatement('''
        INSERT OR REPLACE INTO system_settings (key, value, updated_at)
        VALUES ('rbac_enabled', 'true', CURRENT_TIMESTAMP)
      ''');

      // 2. Set this employee as OWNER
      await db.customStatement('''
        UPDATE employees
        SET defaultRole = 'OWNER',
            storeScope = 'ALL_STORES',
            primaryStoreId = NULL
        WHERE id = ?
      ''', [widget.employee.id]);

      // 2.1 Also update RBAC mapping table (user_roles)
      await db.customStatement(
        'DELETE FROM user_roles WHERE user_id = ?',
        [widget.employee.id],
      );
      await db.customStatement('''
        INSERT INTO user_roles (id, user_id, role, scope, assigned_at, assigned_by)
        VALUES (lower(hex(randomblob(16))), ?, 'OWNER', 'ALL_STORES', CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER), ?)
      ''', [widget.employee.id, widget.employee.id]);

      if (!mounted) return;

      // 3. Show success and restart prompt
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.success, size: 32),
              SizedBox(width: 12),
              Text('Success!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✅ RBAC Enabled\n'
                '✅ ${widget.employee.name} is now OWNER\n'
                '✅ Security Settings will appear in Settings menu\n\n'
                'Please restart the app to see the changes.',
                style: const TextStyle(height: 1.5),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Show restart instructions
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '🔄 Please restart the app:\n'
                      '1. Close the app completely\n'
                      '2. Reopen it\n'
                      '3. Login and go to Settings → Security',
                    ),
                    duration: Duration(seconds: 8),
                    backgroundColor: AppTheme.success,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
              ),
              child: const Text('OK - Will Restart'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isProcessing ? null : _setAsOwner,
        icon: _isProcessing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.shield, size: 18),
        label: Text(
          _isProcessing ? 'Setting...' : '🛡️ Set as OWNER (Enable RBAC)',
          style: const TextStyle(fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primary,
          side: const BorderSide(color: AppTheme.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        ),
      ),
    );
  }
}

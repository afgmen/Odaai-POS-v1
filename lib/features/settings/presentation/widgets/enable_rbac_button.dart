import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../providers/database_providers.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/rbac_providers.dart';

/// Quick Enable RBAC Button (For Settings Screen)
/// This button enables RBAC and sets the current user as OWNER
class EnableRbacButton extends ConsumerStatefulWidget {
  const EnableRbacButton({super.key});

  @override
  ConsumerState<EnableRbacButton> createState() => _EnableRbacButtonState();
}

class _EnableRbacButtonState extends ConsumerState<EnableRbacButton> {
  bool _isProcessing = false;

  Future<void> _enableRbac() async {
    setState(() => _isProcessing = true);

    try {
      final db = ref.read(databaseProvider);
      final currentSession = ref.read(currentSessionProvider);

      if (currentSession == null) {
        throw Exception('Not logged in');
      }

      // 1. Ensure system_settings table exists (migration safety net)
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS system_settings (
          key TEXT PRIMARY KEY NOT NULL,
          value TEXT NOT NULL,
          updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER))
        )
      ''');

      // 2. Enable RBAC in system settings
      await db.customStatement('''
        INSERT OR REPLACE INTO system_settings (key, value, updated_at)
        VALUES ('rbac_enabled', 'true', CAST(strftime('%s', 'now') AS INTEGER))
      ''');

      // 3. Set current user as OWNER
      await db.customStatement('''
        UPDATE employees
        SET default_role = 'OWNER',
            store_scope = 'ALL_STORES',
            primary_store_id = NULL
        WHERE id = ?
      ''', [currentSession.employeeId]);

      // 3.1 Also write to RBAC mapping table (user_roles)
      // PermissionService.isOwner() checks user_roles, not employees.defaultRole
      await db.customStatement(
        'DELETE FROM user_roles WHERE user_id = ?',
        [currentSession.employeeId],
      );
      await db.customStatement('''
        INSERT INTO user_roles (id, user_id, role, scope, assigned_at, assigned_by)
        VALUES (lower(hex(randomblob(16))), ?, 'OWNER', 'ALL_STORES', CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER), ?)
      ''', [currentSession.employeeId, currentSession.employeeId]);

      if (!mounted) return;

      // 4. Invalidate RBAC cache so fresh DB read occurs on next check
      ref.read(permissionServiceProvider).clearCache();
      // Invalidate rbacSettingProvider so it re-reads from DB
      ref.invalidate(rbacSettingProvider);

      // 5. Show success and re-login prompt
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.success),
              SizedBox(width: 12),
              Text('RBAC Enabled!'),
            ],
          ),
          content: const Text(
            'RBAC has been enabled and you are now set as OWNER.\n\n'
            'Please log out and log in again to see the Security Settings section.',
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                // Clear cache before logout to ensure fresh state on re-login
                ref.read(permissionServiceProvider).clearCache();
                await ref.read(authProvider.notifier).logout();
                if (ctx.mounted) {
                  Navigator.of(ctx).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              child: const Text('Log Out Now'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // User-friendly error message instead of exposing raw SQL error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'An error occurred while applying settings. Please log out and log in again.',
          ),
          backgroundColor: AppTheme.error,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Log Out',
            textColor: Colors.white,
            onPressed: () {
              ref.read(permissionServiceProvider).clearCache();
              ref.read(authProvider.notifier).logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: AppTheme.primary, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable RBAC Security',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Role-Based Access Control for your POS',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '✅ Control who can see revenue data\n'
            '✅ Manage employee permissions\n'
            '✅ Set yourself as OWNER with full access',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isProcessing ? null : _enableRbac,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.shield),
              label: Text(_isProcessing ? 'Enabling...' : 'Enable RBAC Now'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../providers/database_providers.dart';
import '../../../auth/providers/auth_provider.dart';

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

      // 1. Enable RBAC in system settings
      await db.customStatement('''
        INSERT OR REPLACE INTO system_settings (key, value, updated_at)
        VALUES ('rbac_enabled', 'true', CURRENT_TIMESTAMP)
      ''');

      // 2. Set current user as OWNER
      await db.customStatement('''
        UPDATE employees
        SET defaultRole = 'OWNER',
            storeScope = 'ALL_STORES',
            primaryStoreId = NULL
        WHERE id = ?
      ''', [currentSession.employeeId]);

      if (!mounted) return;

      // 3. Show success and restart prompt
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
            'Please restart the app to see the Security Settings section.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Force logout to trigger restart
                ref.read(authProvider.notifier).logout();
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              },
              child: const Text('Restart Now'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to enable RBAC: $e'),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
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

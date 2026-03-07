import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/database_providers.dart';

/// Kitchen Approval Requirement Toggle
/// Controls whether checkout requires kitchen order completion
class KitchenApprovalToggle extends ConsumerStatefulWidget {
  const KitchenApprovalToggle({super.key});

  @override
  ConsumerState<KitchenApprovalToggle> createState() => _KitchenApprovalToggleState();
}

class _KitchenApprovalToggleState extends ConsumerState<KitchenApprovalToggle> {
  bool _requireApproval = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final db = ref.read(databaseProvider);
    
    try {
      final result = await db.customSelect(
        "SELECT value FROM system_settings WHERE key = 'require_kitchen_approval'",
      ).getSingleOrNull();
      
      setState(() {
        _requireApproval = result?.data['value'] == 'true';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSetting(bool value) async {
    final db = ref.read(databaseProvider);
    
    try {
      await db.customStatement(
        "INSERT OR REPLACE INTO system_settings (key, value, updated_at) VALUES (?, ?, ?)",
        ['require_kitchen_approval', value ? 'true' : 'false', DateTime.now().millisecondsSinceEpoch ~/ 1000],
      );
      
      setState(() => _requireApproval = value);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value 
                  ? 'Kitchen approval now required for checkout'
                  : 'Kitchen approval disabled',
            ),
            backgroundColor: value ? AppTheme.success : AppTheme.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update setting: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.restaurant_menu, size: 28, color: AppTheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Require Kitchen Approval',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _requireApproval
                        ? 'Checkout blocked until kitchen order is ready'
                        : 'Checkout allowed without kitchen confirmation',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _requireApproval,
              onChanged: _toggleSetting,
              activeColor: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

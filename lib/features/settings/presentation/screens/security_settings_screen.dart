import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/rbac_providers.dart';
import 'role_permissions_screen.dart';

/// Security & Access Control Settings Screen
/// Allows Owner to enable/disable RBAC system
class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rbacSetting = ref.watch(rbacSettingNotifierProvider);
    final isOwner = ref.watch(isOwnerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Access Control'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isOwner.when(
        data: (owner) {
          if (!owner) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Access denied: Owner only',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Role-Based Access Control (RBAC)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          rbacSetting.when(
                            data: (enabled) => Switch(
                              value: enabled,
                              onChanged: (value) async {
                                await ref
                                    .read(rbacSettingNotifierProvider.notifier)
                                    .toggle(value);

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        value
                                            ? 'RBAC enabled'
                                            : 'RBAC disabled',
                                      ),
                                      backgroundColor: value
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  );
                                }
                              },
                            ),
                            loading: () => const CircularProgressIndicator(),
                            error: (_, _) => const Icon(Icons.error),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      rbacSetting.when(
                        data: (enabled) => Text(
                          enabled
                              ? 'RBAC is enabled. Access depends on each user\'s role.'
                              : 'RBAC is disabled. All users have full access.',
                          style: TextStyle(
                            color: enabled ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        loading: () => const SizedBox(),
                        error: (_, _) => const SizedBox(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'When enabled:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletPoint('Staff cannot view revenue reports'),
                      _buildBulletPoint('Only admins can access settings'),
                      _buildBulletPoint('Area managers can manage multiple stores'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber,
                                color: Colors.amber.shade700),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Changes take effect immediately',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Link to Roles & Permissions management
              rbacSetting.when(
                data: (enabled) {
                  if (!enabled) return const SizedBox();

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.admin_panel_settings,
                          color: Colors.blue),
                      title: const Text('Manage role permissions'),
                      subtitle: const Text('Customize permissions per role'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RolePermissionsScreen(),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, _) => const SizedBox(),
              ),
              const SizedBox(height: 16),
              // Role descriptions card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Role overview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRoleDescription(
                        'Owner (OWNER)',
                        'Full system access - all stores',
                        Icons.star,
                        Colors.amber,
                      ),
                      const Divider(),
                      _buildRoleDescription(
                        'Area Manager (AREA_MANAGER)',
                        'Manage multiple assigned stores',
                        Icons.business,
                        Colors.blue,
                      ),
                      const Divider(),
                      _buildRoleDescription(
                        'Store Manager (STORE_MANAGER)',
                        'Manage a single store',
                        Icons.store,
                        Colors.green,
                      ),
                      const Divider(),
                      _buildRoleDescription(
                        'Staff (STAFF)',
                        'Basic POS operations',
                        Icons.person,
                        Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildRoleDescription(
      String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

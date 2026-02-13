import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/rbac_providers.dart';

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
        title: const Text('보안 및 접근 제어'),
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
                    '접근 권한 없음: 사업주 전용',
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
                            '역할 기반 접근 제어 (RBAC)',
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
                                            ? 'RBAC가 활성화되었습니다'
                                            : 'RBAC가 비활성화되었습니다',
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
                            error: (_, __) => const Icon(Icons.error),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      rbacSetting.when(
                        data: (enabled) => Text(
                          enabled
                              ? 'RBAC가 활성화됨. 직원은 역할에 따라 기능에 접근합니다.'
                              : 'RBAC가 비활성화됨. 모든 직원이 모든 기능에 접근할 수 있습니다.',
                          style: TextStyle(
                            color: enabled ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '활성화 시:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletPoint('직원은 재무 보고서를 볼 수 없습니다'),
                      _buildBulletPoint('관리자만 설정에 접근할 수 있습니다'),
                      _buildBulletPoint('지역 관리자는 여러 매장을 관리할 수 있습니다'),
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
                                '변경 사항은 즉시 적용됩니다',
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
                      title: const Text('역할 권한 관리'),
                      subtitle: const Text('각 역할의 권한 커스터마이징'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navigate to Roles & Permissions screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('역할 권한 관리 화면 (개발 중)'),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
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
                        '역할 설명',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRoleDescription(
                        '사업주 (OWNER)',
                        '전체 시스템 접근 - 모든 매장',
                        Icons.star,
                        Colors.amber,
                      ),
                      const Divider(),
                      _buildRoleDescription(
                        '지역 관리자 (AREA MANAGER)',
                        '할당된 여러 매장 관리',
                        Icons.business,
                        Colors.blue,
                      ),
                      const Divider(),
                      _buildRoleDescription(
                        '매장 관리자 (STORE MANAGER)',
                        '단일 매장 관리',
                        Icons.store,
                        Colors.green,
                      ),
                      const Divider(),
                      _buildRoleDescription(
                        '직원 (STAFF)',
                        '기본 POS 작업',
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
          child: Text('오류: $error'),
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

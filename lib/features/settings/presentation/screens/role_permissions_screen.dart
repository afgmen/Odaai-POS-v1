import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/employee_role.dart';
import '../../../auth/domain/permission_modules.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/providers/rbac_providers.dart';

/// 역할별 권한 관리 화면 (Owner 전용)
class RolePermissionsScreen extends ConsumerStatefulWidget {
  const RolePermissionsScreen({super.key});

  @override
  ConsumerState<RolePermissionsScreen> createState() =>
      _RolePermissionsScreenState();
}

class _RolePermissionsScreenState extends ConsumerState<RolePermissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// 편집 가능한 역할 (OWNER 제외)
  static const _editableRoles = [
    EmployeeRole.AREA_MANAGER,
    EmployeeRole.STORE_MANAGER,
    EmployeeRole.STAFF,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _editableRoles.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Role Permissions'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: _editableRoles
              .map((role) => Tab(text: role.displayName))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _editableRoles
            .map((role) => _RolePermissionTab(role: role))
            .toList(),
      ),
    );
  }
}

/// 개별 역할의 권한 탭
class _RolePermissionTab extends ConsumerWidget {
  final EmployeeRole role;

  const _RolePermissionTab({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsAsync =
        ref.watch(rolePermissionsByModuleProvider(role.name));

    return permissionsAsync.when(
      data: (modulePermissions) => _buildContent(context, ref, modulePermissions),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(
                  rolePermissionsByModuleProvider(role.name)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Map<String, Map<String, bool>> modulePermissions,
  ) {
    final modules = PermissionModules.getAllModules();

    return Column(
      children: [
        // 역할 설명 헤더
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue.withValues(alpha: 0.05),
          child: Row(
            children: [
              Icon(_getRoleIcon(role), color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 모듈별 권한 리스트
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: modules.length + 1, // +1 for reset button
            itemBuilder: (context, index) {
              if (index == modules.length) {
                return _buildResetButton(context, ref);
              }

              final module = modules[index];
              final permissions = modulePermissions[module] ?? {};

              if (permissions.isEmpty) return const SizedBox.shrink();

              return _ModuleExpansionTile(
                role: role,
                module: module,
                permissions: permissions,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: () => _confirmReset(context, ref),
        icon: const Icon(Icons.restore, color: Colors.orange),
        label: const Text(
          'Reset to Default',
          style: TextStyle(color: Colors.orange),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.orange),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Permissions'),
        content: Text(
          'Reset all ${role.displayName} permissions to default?\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _resetPermissions(context, ref);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPermissions(BuildContext context, WidgetRef ref) async {
    try {
      final session = ref.read(currentSessionProvider);
      if (session == null) return;

      final service = ref.read(rolePermissionServiceProvider);
      await service.resetToDefault(
        actorId: session.employeeId,
        role: role.name,
      );

      // 캐시 무효화하여 UI 새로고침
      ref.invalidate(rolePermissionsByModuleProvider(role.name));
      ref.invalidate(rolePermissionsProvider(role.name));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${role.displayName} permissions reset to default'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getRoleIcon(EmployeeRole role) {
    switch (role) {
      case EmployeeRole.OWNER:
        return Icons.star;
      case EmployeeRole.AREA_MANAGER:
        return Icons.business;
      case EmployeeRole.STORE_MANAGER:
        return Icons.store;
      case EmployeeRole.STAFF:
        return Icons.person;
    }
  }
}

/// 모듈별 확장 타일 (ExpansionTile + SwitchListTile)
class _ModuleExpansionTile extends ConsumerWidget {
  final EmployeeRole role;
  final String module;
  final Map<String, bool> permissions;

  const _ModuleExpansionTile({
    required this.role,
    required this.module,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSensitiveModule =
        module == 'revenue' || module == 'settings';
    final enabledCount = permissions.values.where((v) => v).length;
    final totalCount = permissions.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          _getModuleIcon(module),
          color: isSensitiveModule ? Colors.orange : Colors.blue,
        ),
        title: Row(
          children: [
            Text(
              PermissionModules.getModuleDisplayName(module),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (isSensitiveModule) ...[
              const SizedBox(width: 6),
              Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
            ],
          ],
        ),
        subtitle: Text(
          '$enabledCount / $totalCount enabled',
          style: TextStyle(
            fontSize: 12,
            color: enabledCount == 0 ? Colors.red : Colors.grey[600],
          ),
        ),
        children: permissions.entries.map((entry) {
          return _PermissionSwitch(
            role: role,
            permissionName: entry.key,
            enabled: entry.value,
          );
        }).toList(),
      ),
    );
  }

  IconData _getModuleIcon(String module) {
    switch (module) {
      case 'pos':
        return Icons.point_of_sale;
      case 'order':
        return Icons.receipt_long;
      case 'inventory':
        return Icons.inventory_2;
      case 'revenue':
        return Icons.trending_up;
      case 'staff':
        return Icons.people;
      case 'settings':
        return Icons.settings;
      default:
        return Icons.extension;
    }
  }
}

/// 개별 권한 스위치
class _PermissionSwitch extends ConsumerStatefulWidget {
  final EmployeeRole role;
  final String permissionName;
  final bool enabled;

  const _PermissionSwitch({
    required this.role,
    required this.permissionName,
    required this.enabled,
  });

  @override
  ConsumerState<_PermissionSwitch> createState() => _PermissionSwitchState();
}

class _PermissionSwitchState extends ConsumerState<_PermissionSwitch> {
  late bool _enabled;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled;
  }

  @override
  void didUpdateWidget(_PermissionSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _enabled = widget.enabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSensitive = PermissionModules.isSensitive(widget.permissionName);
    final displayName =
        PermissionModules.getPermissionDisplayName(widget.permissionName);

    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(
        displayName,
        style: TextStyle(
          fontSize: 14,
          color: isSensitive ? Colors.orange[900] : null,
        ),
      ),
      subtitle: Text(
        widget.permissionName,
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
      value: _enabled,
      activeTrackColor: isSensitive ? Colors.orange.withValues(alpha: 0.5) : Colors.blue.withValues(alpha: 0.5),
      thumbColor: WidgetStatePropertyAll(isSensitive ? Colors.orange : Colors.blue),
      onChanged: _updating ? null : _onToggle,
      secondary: _updating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : isSensitive
              ? Icon(Icons.shield, size: 18, color: Colors.orange[300])
              : null,
    );
  }

  Future<void> _onToggle(bool newValue) async {
    setState(() {
      _enabled = newValue;
      _updating = true;
    });

    try {
      final session = ref.read(currentSessionProvider);
      if (session == null) return;

      final service = ref.read(rolePermissionServiceProvider);
      await service.updatePermission(
        actorId: session.employeeId,
        role: widget.role.name,
        permissionName: widget.permissionName,
        enabled: newValue,
      );

      // 캐시 무효화
      ref.invalidate(rolePermissionsByModuleProvider(widget.role.name));
      ref.invalidate(rolePermissionsProvider(widget.role.name));
    } catch (e) {
      // 실패 시 롤백
      setState(() => _enabled = !newValue);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }
}

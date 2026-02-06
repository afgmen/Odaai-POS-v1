import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../auth/providers/auth_provider.dart';
import '../widgets/employee_form_modal.dart';

/// 직원 관리 화면
class EmployeeManagementScreen extends ConsumerWidget {
  const EmployeeManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(activeEmployeesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.people, color: AppTheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text(
              '직원 관리',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
          ],
        ),
        actions: [
          // 새 직원 추가 버튼
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showEmployeeFormModal(context, ref, null),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('직원 추가', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: employeesAsync.when(
        data: (employees) {
          if (employees.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: AppTheme.textDisabled),
                  SizedBox(height: 16),
                  Text(
                    '등록된 직원이 없습니다',
                    style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];
                return _EmployeeCard(
                  employee: employee,
                  onEdit: () => _showEmployeeFormModal(context, ref, employee),
                  onToggleActive: () => _toggleEmployeeActive(ref, employee),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            '직원 목록을 불러올 수 없습니다\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
      ),
    );
  }

  void _showEmployeeFormModal(BuildContext context, WidgetRef ref, Employee? employee) {
    showDialog(
      context: context,
      builder: (_) => EmployeeFormModal(employee: employee),
    ).then((_) {
      // 모달 닫힌 후 목록 새로고침
      ref.invalidate(activeEmployeesProvider);
    });
  }

  Future<void> _toggleEmployeeActive(WidgetRef ref, Employee employee) async {
    final authService = ref.read(authServiceProvider);
    try {
      await authService.updateEmployee(
        id: employee.id,
        isActive: !employee.isActive,
      );
      ref.invalidate(activeEmployeesProvider);
    } catch (e) {
      // 에러 처리
    }
  }
}

/// 직원 카드
class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  const _EmployeeCard({
    required this.employee,
    required this.onEdit,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final roleLabel = _getRoleLabel(employee.role);
    final roleColor = _getRoleColor(employee.role);
    final hasPin = employee.pin != null;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 아바타
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  employee.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: roleColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          employee.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: roleColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          roleLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          employee.username,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        hasPin ? Icons.lock : Icons.lock_open,
                        size: 14,
                        color: hasPin ? AppTheme.success : AppTheme.textDisabled,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        hasPin ? 'PIN' : '없음',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasPin ? AppTheme.success : AppTheme.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 액션 버튼
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20, color: AppTheme.textSecondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'toggle':
                    onToggleActive();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18, color: AppTheme.textPrimary),
                      SizedBox(width: 8),
                      Text('수정'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        employee.isActive ? Icons.block : Icons.check_circle,
                        size: 18,
                        color: employee.isActive ? AppTheme.error : AppTheme.success,
                      ),
                      const SizedBox(width: 8),
                      Text(employee.isActive ? '비활성화' : '활성화'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'ADMIN';
      case 'manager':
        return 'MANAGER';
      case 'cashier':
        return 'CASHIER';
      default:
        return role.toUpperCase();
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppTheme.primary;
      case 'manager':
        return const Color(0xFF8B5CF6);
      case 'cashier':
        return AppTheme.success;
      default:
        return AppTheme.textSecondary;
    }
  }
}

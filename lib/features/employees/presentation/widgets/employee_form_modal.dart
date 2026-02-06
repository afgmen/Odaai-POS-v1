import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../auth/providers/auth_provider.dart';

/// 직원 추가/수정 모달
class EmployeeFormModal extends ConsumerStatefulWidget {
  final Employee? employee;

  const EmployeeFormModal({super.key, this.employee});

  @override
  ConsumerState<EmployeeFormModal> createState() => _EmployeeFormModalState();
}

class _EmployeeFormModalState extends ConsumerState<EmployeeFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _pinCtrl;

  String _selectedRole = 'cashier';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.employee?.username ?? '');
    _nameCtrl = TextEditingController(text: widget.employee?.name ?? '');
    _pinCtrl = TextEditingController();
    _selectedRole = widget.employee?.role ?? 'cashier';
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.employee != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? '직원 정보 수정' : '새 직원 추가',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 사용자명
                TextFormField(
                  controller: _usernameCtrl,
                  enabled: !isEdit, // 수정 시에는 사용자명 변경 불가
                  decoration: const InputDecoration(
                    labelText: '사용자명 (로그인 ID)',
                    hintText: '예: john_doe',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '사용자명을 입력하세요';
                    }
                    if (value.length < 3) {
                      return '사용자명은 3자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 이름
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '이름',
                    hintText: '예: 홍길동',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이름을 입력하세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 역할
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: '역할',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cashier', child: Text('캐셔 (Cashier)')),
                    DropdownMenuItem(value: 'manager', child: Text('매니저 (Manager)')),
                    DropdownMenuItem(value: 'admin', child: Text('관리자 (Admin)')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedRole = value!);
                  },
                ),
                const SizedBox(height: 16),

                // PIN 입력
                TextFormField(
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'PIN 변경 (선택사항)' : 'PIN (4자리 숫자)',
                    hintText: '1234',
                    prefixIcon: const Icon(Icons.lock_outline),
                    helperText: isEdit ? '비워두면 PIN이 변경되지 않습니다' : '4자리 숫자를 입력하세요',
                  ),
                  validator: (value) {
                    if (!isEdit && (value == null || value.isEmpty)) {
                      return 'PIN을 입력하세요';
                    }
                    if (value != null && value.isNotEmpty && value.length != 4) {
                      return 'PIN은 4자리여야 합니다';
                    }
                    if (value != null && value.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(value)) {
                      return 'PIN은 숫자만 입력 가능합니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // 안내 메시지
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isEdit
                              ? '직원 정보를 수정합니다. PIN을 변경하려면 새로운 4자리 숫자를 입력하세요.'
                              : '새 직원이 생성됩니다. PIN을 사용하여 로그인할 수 있습니다.',
                          style: const TextStyle(fontSize: 12, color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 버튼
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppTheme.divider),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(isEdit ? '수정' : '추가'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final pin = _pinCtrl.text.trim();

      if (widget.employee == null) {
        // 신규 직원 추가
        await authService.createEmployee(
          username: _usernameCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          role: _selectedRole,
          pin: pin.isNotEmpty ? pin : null,
        );

        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessMessage('새 직원이 추가되었습니다');
        }
      } else {
        // 기존 직원 수정
        await authService.updateEmployee(
          id: widget.employee!.id,
          name: _nameCtrl.text.trim(),
          role: _selectedRole,
          pin: pin.isNotEmpty ? pin : null,
        );

        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessMessage('직원 정보가 수정되었습니다');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorMessage('오류가 발생했습니다: ${e.toString()}');
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

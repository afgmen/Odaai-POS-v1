import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../database/daos/employees_dao.dart';
import '../../../../providers/database_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/utils/pin_hasher.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
                      isEdit ? l10n.editEmployee : l10n.addEmployee,
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
                  decoration: InputDecoration(
                    labelText: l10n.usernameLabel,
                    hintText: l10n.usernameHint,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.usernameRequired;
                    }
                    if (value.length < 3) {
                      return l10n.usernameMinLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 이름
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.nameLabel,
                    hintText: l10n.nameHint,
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.nameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 역할
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: l10n.roleLabel,
                    prefixIcon: const Icon(Icons.work_outline),
                  ),
                  items: [
                    DropdownMenuItem(value: 'cashier', child: Text(l10n.roleCashier)),
                    DropdownMenuItem(value: 'manager', child: Text(l10n.roleManager)),
                    DropdownMenuItem(value: 'admin', child: Text(l10n.roleAdmin)),
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
                    labelText: isEdit ? l10n.pinChangeLabel : l10n.pinNewLabel,
                    hintText: l10n.pinHint,
                    prefixIcon: const Icon(Icons.lock_outline),
                    helperText: isEdit ? l10n.pinNoChangeHelper : l10n.pinNewHelper,
                  ),
                  validator: (value) {
                    if (!isEdit && (value == null || value.isEmpty)) {
                      return l10n.pinRequired;
                    }
                    if (value != null && value.isNotEmpty && value.length != 4) {
                      return l10n.pinLengthError;
                    }
                    if (value != null && value.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(value)) {
                      return l10n.pinDigitsOnly;
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
                              ? l10n.employeeInfoEdit
                              : l10n.employeeInfoNew,
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
                        child: Text(l10n.cancel),
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
                            : Text(isEdit ? l10n.edit : l10n.add),
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
      final employeesDao = ref.read(employeesDaoProvider);
      final pin = _pinCtrl.text.trim();
      final l10n = AppLocalizations.of(context)!;

      if (widget.employee == null) {
        // 신규 직원 추가
        final employeeId = await employeesDao.createEmployee(
          EmployeesCompanion.insert(
            username: _usernameCtrl.text.trim(),
            name: _nameCtrl.text.trim(),
            passwordHash: 'unused',
            role: Value(_selectedRole),
          ),
        );

        // PIN 설정
        if (pin.isNotEmpty && PinHasher.isValidPinFormat(pin)) {
          await employeesDao.setPIN(employeeId, pin);
        }

        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessMessage(l10n.employeeAdded);
        }
      } else {
        // 기존 직원 수정
        await employeesDao.updateEmployee(
          widget.employee!.id,
          EmployeesCompanion(
            name: Value(_nameCtrl.text.trim()),
            role: Value(_selectedRole),
          ),
        );

        // PIN 업데이트 (입력된 경우)
        if (pin.isNotEmpty && PinHasher.isValidPinFormat(pin)) {
          await employeesDao.setPIN(widget.employee!.id, pin);
        }

        if (mounted) {
          Navigator.of(context).pop();
          _showSuccessMessage(l10n.employeeUpdated);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context)!;
        _showErrorMessage(l10n.msgError(e.toString()));
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/app_database.dart';
import '../../../../database/daos/employees_dao.dart';
import '../../../../providers/database_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../domain/auth_error.dart';
import '../widgets/pin_pad_widget.dart';

/// PIN 로그인 화면
class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  int? _selectedEmployeeId;
  String _pin = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 활성 직원 목록 조회
    final employeesAsyncValue = ref.watch(_activeEmployeesProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 로고 및 타이틀
                const Icon(
                  Icons.store,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Oda POS',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.employeeLogin,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 48),

                // Employee selection dropdown
                employeesAsyncValue.when(
                  data: (employees) => _buildEmployeeSelector(employees, l10n),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('${l10n.employeeLoadError}: $error'),
                ),

                const SizedBox(height: 32),

                // PIN input
                if (_selectedEmployeeId != null) ...[
                  Text(
                    l10n.enterPinCode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PIN 패드
                  PinPadWidget(
                    pin: _pin,
                    maxLength: 4,
                    onChanged: (newPin) {
                      setState(() {
                        _pin = newPin;
                        _errorMessage = null;
                      });
                    },
                    onSubmit: _handleLogin,
                  ),

                  const SizedBox(height: 24),

                  // Login button
                  SizedBox(
                    width: 280,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _pin.length >= 4 && !_isLoading
                          ? _handleLogin
                          : null,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.loginButton,
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),

                  // 에러 메시지
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Help text
                  Text(
                    l10n.forgotPin,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeSelector(List<Employee> employees, AppLocalizations l10n) {
    if (employees.isEmpty) {
      return Text(l10n.noEmployeesRegistered);
    }

    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedEmployeeId,
          hint: Text(l10n.selectEmployee),
          isExpanded: true,
          items: employees.map((employee) {
            return DropdownMenuItem<int>(
              value: employee.id,
              child: Text('${employee.name} (${_getRoleDisplay(employee.role, l10n)})'),
            );
          }).toList(),
          onChanged: (employeeId) {
            setState(() {
              _selectedEmployeeId = employeeId;
              _pin = '';
              _errorMessage = null;
            });
          },
        ),
      ),
    );
  }

  String _getRoleDisplay(String role, AppLocalizations l10n) {
    switch (role.toUpperCase()) {
      case 'MANAGER':
        return l10n.roleManager;
      case 'CASHIER':
        return l10n.roleCashier;
      case 'KITCHEN':
        return l10n.roleKitchen;
      default:
        return role;
    }
  }

  Future<void> _handleLogin() async {
    if (_selectedEmployeeId == null || _pin.length < 4) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Login attempt
      await ref.read(authProvider.notifier).login(_selectedEmployeeId!, _pin);

      // Navigate to main screen on successful login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on AuthError catch (e) {
      // Authentication error handling
      setState(() {
        _errorMessage = e.userMessage;
        _pin = '';
      });
    } catch (e) {
      // Other error handling
      setState(() {
        _errorMessage = l10n.loginFailed(e.toString());
        _pin = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// ============================================================
// Private Providers (화면 전용)
// ============================================================

/// 활성 직원 목록 Provider
final _activeEmployeesProvider = FutureProvider<List<Employee>>((ref) async {
  final employeesDao = ref.watch(employeesDaoProvider);
  return await employeesDao.getAllEmployees();
});

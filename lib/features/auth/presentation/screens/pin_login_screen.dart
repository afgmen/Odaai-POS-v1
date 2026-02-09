import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../../app_root_screen.dart';

/// PIN 로그인 화면
class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen> {
  String _pin = '';
  bool _isAuthenticating = false;
  String? _errorMessage;

  void _onNumberPressed(String number) {
    if (_pin.length < 4) {
      setState(() {
        _pin += number;
        _errorMessage = null;
      });

      // 4자리 입력 완료 시 자동 인증
      if (_pin.length == 4) {
        _authenticate();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onClear() {
    setState(() {
      _pin = '';
      _errorMessage = null;
    });
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final employee = await authService.authenticateWithPin(_pin);

      if (employee != null) {
        ref.read(currentEmployeeProvider.notifier).state = employee;

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AppRootScreen()),
          );
        }
      } else {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _errorMessage = l10n.pinMismatch;
          _pin = '';
        });
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorMessage = l10n.loginError(e.toString());
        _pin = '';
      });
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 로고/제목
                  const Icon(Icons.store, size: 80, color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    l10n.appName,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.pinLoginTitle,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 48),

                  // PIN 입력 표시
                  _PinDisplay(pin: _pin, isAuthenticating: _isAuthenticating),
                  const SizedBox(height: 16),

                  // 에러 메시지
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDEBEB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 13, color: AppTheme.error),
                      ),
                    ),
                  const SizedBox(height: 32),

                  // 숫자 패드
                  _NumberPad(
                    onNumberPressed: _onNumberPressed,
                    onBackspace: _onBackspace,
                    onClear: _onClear,
                    enabled: !_isAuthenticating,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// PIN 입력 표시 (동그라미)
class _PinDisplay extends StatelessWidget {
  final String pin;
  final bool isAuthenticating;

  const _PinDisplay({required this.pin, required this.isAuthenticating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < pin.length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? AppTheme.primary : Colors.transparent,
              border: Border.all(
                color: isFilled ? AppTheme.primary : AppTheme.divider,
                width: 2,
              ),
            ),
            child: isAuthenticating && index == 3
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : null,
          ),
        );
      }),
    );
  }
}

/// 숫자 패드
class _NumberPad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final bool enabled;

  const _NumberPad({
    required this.onNumberPressed,
    required this.onBackspace,
    required this.onClear,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1 2 3
        Row(
          children: [
            _NumberButton(number: '1', onPressed: () => onNumberPressed('1'), enabled: enabled),
            const SizedBox(width: 12),
            _NumberButton(number: '2', onPressed: () => onNumberPressed('2'), enabled: enabled),
            const SizedBox(width: 12),
            _NumberButton(number: '3', onPressed: () => onNumberPressed('3'), enabled: enabled),
          ],
        ),
        const SizedBox(height: 12),
        // 4 5 6
        Row(
          children: [
            _NumberButton(number: '4', onPressed: () => onNumberPressed('4'), enabled: enabled),
            const SizedBox(width: 12),
            _NumberButton(number: '5', onPressed: () => onNumberPressed('5'), enabled: enabled),
            const SizedBox(width: 12),
            _NumberButton(number: '6', onPressed: () => onNumberPressed('6'), enabled: enabled),
          ],
        ),
        const SizedBox(height: 12),
        // 7 8 9
        Row(
          children: [
            _NumberButton(number: '7', onPressed: () => onNumberPressed('7'), enabled: enabled),
            const SizedBox(width: 12),
            _NumberButton(number: '8', onPressed: () => onNumberPressed('8'), enabled: enabled),
            const SizedBox(width: 12),
            _NumberButton(number: '9', onPressed: () => onNumberPressed('9'), enabled: enabled),
          ],
        ),
        const SizedBox(height: 12),
        // C 0 <-
        Row(
          children: [
            _ActionButton(icon: Icons.clear, onPressed: onClear, enabled: enabled, label: 'C'),
            const SizedBox(width: 12),
            _NumberButton(number: '0', onPressed: () => onNumberPressed('0'), enabled: enabled),
            const SizedBox(width: 12),
            _ActionButton(icon: Icons.backspace_outlined, onPressed: onBackspace, enabled: enabled),
          ],
        ),
      ],
    );
  }
}

/// 숫자 버튼
class _NumberButton extends StatelessWidget {
  final String number;
  final VoidCallback onPressed;
  final bool enabled;

  const _NumberButton({
    required this.number,
    required this.onPressed,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 70,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.cardWhite,
            foregroundColor: AppTheme.textPrimary,
            disabledBackgroundColor: AppTheme.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            side: const BorderSide(color: AppTheme.divider),
          ),
          child: Text(
            number,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

/// 액션 버튼 (지우기, 백스페이스)
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;
  final String? label;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    required this.enabled,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 70,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.background,
            foregroundColor: AppTheme.textSecondary,
            disabledBackgroundColor: AppTheme.background,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            side: const BorderSide(color: AppTheme.divider),
          ),
          child: label != null
              ? Text(label!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))
              : Icon(icon, size: 28),
        ),
      ),
    );
  }
}

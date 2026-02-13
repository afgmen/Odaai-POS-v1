import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/permission.dart';
import '../../providers/auth_provider.dart';
import '../../providers/permission_provider.dart';
import '../widgets/pin_pad_widget.dart';

/// 관리자 승인 다이얼로그
class ManagerOverrideDialog extends ConsumerStatefulWidget {
  final Permission permission;
  final String actionDescription;

  const ManagerOverrideDialog({
    super.key,
    required this.permission,
    required this.actionDescription,
  });

  @override
  ConsumerState<ManagerOverrideDialog> createState() =>
      _ManagerOverrideDialogState();
}

class _ManagerOverrideDialogState
    extends ConsumerState<ManagerOverrideDialog> {
  String _managerPin = '';
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final currentSession = ref.watch(currentSessionProvider);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          const Text('관리자 권한 필요'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 설명
            Text(
              '${widget.actionDescription}은(는) 관리자 권한이 필요합니다.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            // 요청자 정보
            if (currentSession != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '요청자: ${currentSession.employeeName} (${currentSession.role.displayName})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '작업: ${widget.actionDescription}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 관리자 PIN 입력
            const Text(
              '관리자 PIN을 입력하세요',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // PIN 패드 (소형)
            Center(
              child: Transform.scale(
                scale: 0.8,
                child: PinPadWidget(
                  pin: _managerPin,
                  maxLength: 6,
                  onChanged: (newPin) {
                    setState(() {
                      _managerPin = newPin;
                      _errorMessage = null;
                    });
                  },
                  onSubmit: _handleApprove,
                ),
              ),
            ),

            // 에러 메시지
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 16, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed:
              _managerPin.length >= 4 && !_isVerifying ? _handleApprove : null,
          child: _isVerifying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('승인'),
        ),
      ],
    );
  }

  Future<void> _handleApprove() async {
    if (_managerPin.length < 4) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      // 관리자 승인 요청
      final permissionChecker = ref.read(permissionProvider);
      final approved = await permissionChecker.requestManagerOverride(
        widget.permission,
        widget.actionDescription,
        _managerPin,
      );

      if (!mounted) return;

      if (approved) {
        // 승인 성공
        Navigator.of(context).pop(true);
      } else {
        // 승인 실패
        setState(() {
          _errorMessage = '관리자 PIN이 일치하지 않습니다.';
          _managerPin = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '승인 처리 중 오류가 발생했습니다: $e';
        _managerPin = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }
}

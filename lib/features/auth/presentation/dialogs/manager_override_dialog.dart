import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/permission.dart';
import '../../domain/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/permission_provider.dart';
import '../widgets/pin_pad_widget.dart';

/// Manager override dialog — requires manager PIN to approve a restricted action
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
          const Text('Manager Approval Required'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.actionDescription} requires manager approval.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),

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
                      'Requested by: ${currentSession.employeeName} (${currentSession.role.displayName})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Action: ${widget.actionDescription}',
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

            const Text(
              'Enter manager PIN',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

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
          child: const Text('Cancel'),
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
              : const Text('Approve'),
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
      final permissionChecker = ref.read(permissionProvider);
      final approved = await permissionChecker.requestManagerOverride(
        widget.permission,
        widget.actionDescription,
        _managerPin,
      );

      if (!mounted) return;

      if (approved) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = 'Manager PIN does not match.';
          _managerPin = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Approval failed: $e';
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

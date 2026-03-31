import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Cancel reason selection modal
class CancelReasonModal extends StatefulWidget {
  final Future<void> Function(String reason) onConfirm;

  const CancelReasonModal({super.key, required this.onConfirm});

  @override
  State<CancelReasonModal> createState() => _CancelReasonModalState();
}

class _CancelReasonModalState extends State<CancelReasonModal> {
  String? _selectedReason;
  final _customReasonController = TextEditingController();

  static const List<String> _predefinedReasons = [
    'Customer Request',
    'Out of Stock',
    'Kitchen Error',
    'Other',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a cancellation reason'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String finalReason = _selectedReason!;
    if (_selectedReason == 'Other') {
      final custom = _customReasonController.text.trim();
      if (custom.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a reason'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      finalReason = 'Other: $custom';
    }

    // Await the callback so all DB operations complete before closing the dialog.
    // This ensures the KDS stream updates before the dialog context is removed.
    await widget.onConfirm(finalReason);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel Order — Reason'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please select a cancellation reason',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ..._predefinedReasons.map((reason) => RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    setState(() => _selectedReason = value);
                  },
                  contentPadding: EdgeInsets.zero,
                )),
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customReasonController,
                decoration: const InputDecoration(
                  labelText: 'Enter reason',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Menu change request',
                ),
                maxLines: 2,
                autofocus: true,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// 취소 사유 선택 모달
class CancelReasonModal extends StatefulWidget {
  final Function(String reason) onConfirm;

  const CancelReasonModal({super.key, required this.onConfirm});

  @override
  State<CancelReasonModal> createState() => _CancelReasonModalState();
}

class _CancelReasonModalState extends State<CancelReasonModal> {
  String? _selectedReason;
  final _customReasonController = TextEditingController();

  static const List<String> _predefinedReasons = [
    '고객 요청',
    '재고 소진',
    '주방 오류',
    '기타',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('취소 사유를 선택해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String finalReason = _selectedReason!;
    if (_selectedReason == '기타') {
      final custom = _customReasonController.text.trim();
      if (custom.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기타 사유를 입력해주세요'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      finalReason = '기타: $custom';
    }

    widget.onConfirm(finalReason);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('주문 취소 사유'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '취소 사유를 선택해주세요',
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
            if (_selectedReason == '기타') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customReasonController,
                decoration: const InputDecoration(
                  labelText: '상세 사유 입력',
                  border: OutlineInputBorder(),
                  hintText: '예: 메뉴 변경 요청',
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
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error,
            foregroundColor: Colors.white,
          ),
          child: const Text('확인'),
        ),
      ],
    );
  }
}

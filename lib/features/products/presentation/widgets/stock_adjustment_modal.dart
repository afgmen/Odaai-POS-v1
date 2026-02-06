import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';

/// 재고 조정 모달
class StockAdjustmentModal extends ConsumerStatefulWidget {
  final Product product;

  const StockAdjustmentModal({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<StockAdjustmentModal> createState() => _StockAdjustmentModalState();
}

class _StockAdjustmentModalState extends ConsumerState<StockAdjustmentModal> {
  bool _isIn = true; // true = 입고, false = 출고
  bool _isProcessing = false;
  late final TextEditingController _quantityController;
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  int get _quantity => int.tryParse(_quantityController.text) ?? 0;

  int get _previewStock {
    return widget.product.stock + (_isIn ? _quantity : -_quantity);
  }

  bool get _isValid => _quantity > 0;

  bool get _willOverflow => _previewStock < 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 헤더 ──────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '재고 조정',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    Text(
                      widget.product.name,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 22, color: AppTheme.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── 현재 재고 표시 ─────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '현재 재고',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                  ),
                  Text(
                    '${widget.product.stock}개',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ─── 입고 / 출고 토글 ───────────────
            const Text(
              '조정 유형',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _ToggleButton(
                    label: '+ 입고',
                    icon: Icons.add_circle_outline,
                    isActive: _isIn,
                    activeColor: AppTheme.success,
                    onTap: () => setState(() => _isIn = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ToggleButton(
                    label: '- 출고',
                    icon: Icons.remove_circle_outline,
                    isActive: !_isIn,
                    activeColor: AppTheme.error,
                    onTap: () => setState(() => _isIn = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ─── 조정 수량 ──────────────────────
            const Text(
              '조정 수량',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                suffixText: '개',
                suffixStyle: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                hintText: '수량 입력',
              ),
            ),
            const SizedBox(height: 14),

            // ─── 사유 ───────────────────────────
            const Text(
              '사유 (선택)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                hintText: '예: 신규 입고, 손실 등',
              ),
            ),
            const SizedBox(height: 14),

            // ─── 조정 후 재고 미리보기 ──────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _willOverflow ? const Color(0xFFFDEBEB) : const Color(0xFFE6FAF2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '조정 후 재고',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _willOverflow ? AppTheme.error : AppTheme.success,
                    ),
                  ),
                  Text(
                    '$_previewStock개',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _willOverflow ? AppTheme.error : AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── 액션 버튼 ──────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (!_isValid || _isProcessing) ? null : _executeAdjustment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      disabledBackgroundColor: AppTheme.textDisabled,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessing
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('조정 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeAdjustment() async {
    setState(() => _isProcessing = true);
    try {
      final dao = ref.read(productsDaoProvider);
      await dao.updateStock(
        productId: widget.product.id,
        quantity: _isIn ? _quantity : -_quantity,
        type: _isIn ? 'in' : 'out',
        reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar('재고가 조정되었습니다 (${_isIn ? '+' : ''}${_isIn ? _quantity : -_quantity}개)', AppTheme.success);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSnackBar(e.toString(), AppTheme.error);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }
}

/// 입고/출고 토글 버튼
class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.1) : AppTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? activeColor : AppTheme.divider,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isActive ? activeColor : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

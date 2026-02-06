import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';
import '../../../products/providers/products_management_provider.dart';

/// 상품 추가 / 수정 폼 모달
/// existingProduct == null → 추가 모드
/// existingProduct != null → 수정 모드
class ProductFormModal extends ConsumerStatefulWidget {
  final Product? existingProduct;

  const ProductFormModal({
    super.key,
    this.existingProduct,
  });

  @override
  ConsumerState<ProductFormModal> createState() => _ProductFormModalState();
}

class _ProductFormModalState extends ConsumerState<ProductFormModal> {
  bool _isProcessing = false;

  // ── 폼 컨트롤러 ─────────────────────────
  late final TextEditingController _skuCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _minStockCtrl;
  late final TextEditingController _categoryCtrl;

  bool get _isEditMode => widget.existingProduct != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? '');
    _priceCtrl = TextEditingController(text: p != null ? _num(p.price) : '');
    _costCtrl = TextEditingController(text: p != null ? _num(p.cost) : '');
    _stockCtrl = TextEditingController(text: p != null ? '${p.stock}' : '0');
    _minStockCtrl = TextEditingController(text: p != null ? '${p.minStock}' : '0');
    _categoryCtrl = TextEditingController(text: p?.category ?? '');
  }

  @override
  void dispose() {
    _skuCtrl.dispose();
    _nameCtrl.dispose();
    _barcodeCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  /// 숫자 컨트롤러 초기값 포맷 (소수점 제거)
  String _num(double v) => v == v.toInt().toDouble() ? '${v.toInt()}' : '$v';

  bool get _isValid => _skuCtrl.text.trim().isNotEmpty && _nameCtrl.text.trim().isNotEmpty && _priceCtrl.text.trim().isNotEmpty;

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── 헤더 ──────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditMode ? '상품 수정' : '상품 추가',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
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

              // ─── 기본정보 섹션 ──────────────
              _sectionLabel('기본정보'),
              _formField(
                label: 'SKU *',
                controller: _skuCtrl,
                hint: 'DEMO001',
                readOnly: _isEditMode, // 수정 시 SKU 변경 불가
                onChanged: (_) => setState(() {}),
              ),
              _formField(
                label: '상품명 *',
                controller: _nameCtrl,
                hint: '테스트 감자칩',
                onChanged: (_) => setState(() {}),
              ),
              _formField(
                label: '바코드',
                controller: _barcodeCtrl,
                hint: '4000386123457',
              ),

              // ─── 가격정보 섹션 ──────────────
              _sectionLabel('가격정보'),
              _formField(
                label: '판매가 *',
                controller: _priceCtrl,
                hint: '10000',
                isNumber: true,
                prefixText: '₩',
                onChanged: (_) => setState(() {}),
              ),
              _formField(
                label: '원가',
                controller: _costCtrl,
                hint: '7000',
                isNumber: true,
                prefixText: '₩',
              ),

              // ─── 재고정보 섹션 ──────────────
              _sectionLabel('재고정보'),
              _formField(
                label: '재고수량',
                controller: _stockCtrl,
                hint: '0',
                isNumber: true,
                suffixText: '개',
                readOnly: _isEditMode, // 수정 시 재고조정 모달로만 변경
              ),
              _formField(
                label: '최소재고',
                controller: _minStockCtrl,
                hint: '10',
                isNumber: true,
                suffixText: '개',
              ),
              _formField(
                label: '카테고리',
                controller: _categoryCtrl,
                hint: '식품, 음료, 전자제품 등',
              ),
              const SizedBox(height: 4),

              // ─── 액션 버튼 ──────────────────
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
                      onPressed: (!_isValid || _isProcessing) ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        disabledBackgroundColor: AppTheme.textDisabled,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isProcessing
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text('저장', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 폼 제출 ─────────────────────────────
  Future<void> _submitForm() async {
    setState(() => _isProcessing = true);
    try {
      final dao = ref.read(productsDaoProvider);

      if (_isEditMode) {
        // 수정 모드 — Companion을 직접 구성하여 write
        final old = widget.existingProduct!;
        final companion = ProductsCompanion(
          name: Value(_nameCtrl.text.trim()),
          barcode: Value(_barcodeCtrl.text.trim().isEmpty ? null : _barcodeCtrl.text.trim()),
          price: Value(double.tryParse(_priceCtrl.text) ?? old.price),
          cost: Value(double.tryParse(_costCtrl.text) ?? old.cost),
          minStock: Value(int.tryParse(_minStockCtrl.text) ?? old.minStock),
          category: Value(_categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim()),
          updatedAt: Value(DateTime.now()),
          needsSync: const Value(true),
        );
        final db = ref.read(databaseProvider);
        await (db.update(db.products)..where((p) => p.id.equals(old.id))).write(companion);
        if (mounted) {
          // provider 캐시 갱신 → 목록 리스트 즉시 반영
          ref.invalidate(mgmtFilteredProductsProvider);
          ref.invalidate(mgmtCategoryListProvider);
          Navigator.of(context).pop();
          _showSnackBar('상품이 수정되었습니다', AppTheme.success);
        }
      } else {
        // 추가 모드
        final companion = ProductsCompanion.insert(
          sku: _skuCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          barcode: _barcodeCtrl.text.trim().isEmpty ? const Value.absent() : Value(_barcodeCtrl.text.trim()),
          price: Value(double.tryParse(_priceCtrl.text) ?? 0),
          cost: Value(double.tryParse(_costCtrl.text) ?? 0),
          stock: Value(int.tryParse(_stockCtrl.text) ?? 0),
          minStock: Value(int.tryParse(_minStockCtrl.text) ?? 0),
          category: _categoryCtrl.text.trim().isEmpty ? const Value.absent() : Value(_categoryCtrl.text.trim()),
        );
        await dao.createProduct(companion);
        if (mounted) {
          ref.invalidate(mgmtFilteredProductsProvider);
          ref.invalidate(mgmtCategoryListProvider);
          Navigator.of(context).pop();
          _showSnackBar('상품이 추가되었습니다', AppTheme.success);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSnackBar('오류: ${e.toString()}', AppTheme.error);
      }
    }
  }

  // ── UI 헬퍼 ───────────────────────────────
  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDisabled),
      ),
    );
  }

  Widget _formField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    bool isNumber = false,
    bool readOnly = false,
    String? prefixText,
    String? suffixText,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            readOnly: readOnly,
            onChanged: onChanged,
            keyboardType: isNumber ? const TextInputType.numberWithOptions() : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              prefixText: prefixText,
              prefixStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary),
              suffixText: suffixText,
              suffixStyle: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              fillColor: readOnly ? const Color(0xFFF0F0F2) : AppTheme.background,
            ),
          ),
        ],
      ),
    );
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

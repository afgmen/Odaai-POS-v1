import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';
import '../../../products/providers/products_management_provider.dart';
import '../../domain/models/search_image_result.dart';
import '../providers/image_providers.dart';
import 'image_search_dialog.dart';

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

  // ── 이미지 상태 ─────────────────────────
  String? _imageUrl;
  File? _localImageFile;

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

    // Load existing image if in edit mode
    _imageUrl = p?.imageUrl;
    if (_imageUrl != null) {
      _loadLocalImage();
    }
  }

  Future<void> _loadLocalImage() async {
    if (_imageUrl == null || widget.existingProduct == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/$_imageUrl';
    final file = File(imagePath);

    if (await file.exists()) {
      setState(() {
        _localImageFile = file;
      });
    }
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
    final l10n = AppLocalizations.of(context)!;
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
                    _isEditMode ? l10n.editProduct : l10n.addProduct,
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
              _sectionLabel(l10n.basicInfo),
              _formField(
                label: 'SKU *',
                controller: _skuCtrl,
                hint: 'DEMO001',
                readOnly: _isEditMode, // 수정 시 SKU 변경 불가
                onChanged: (_) => setState(() {}),
              ),
              _formField(
                label: l10n.productNameRequired,
                controller: _nameCtrl,
                hint: '테스트 감자칩',
                onChanged: (_) => setState(() {}),
              ),
              _formField(
                label: l10n.barcode,
                controller: _barcodeCtrl,
                hint: '4000386123457',
              ),

              // ─── 가격정보 섹션 ──────────────
              _sectionLabel(l10n.priceInfo),
              _formField(
                label: l10n.sellingPriceRequired,
                controller: _priceCtrl,
                hint: '10000',
                isNumber: true,
                prefixText: '₩',
                onChanged: (_) => setState(() {}),
              ),
              _formField(
                label: l10n.costPrice,
                controller: _costCtrl,
                hint: '7000',
                isNumber: true,
                prefixText: '₩',
              ),

              // ─── 재고정보 섹션 ──────────────
              _sectionLabel(l10n.stockInfo),
              _formField(
                label: l10n.stockQuantity,
                controller: _stockCtrl,
                hint: '0',
                isNumber: true,
                suffixText: '개',
                readOnly: _isEditMode, // 수정 시 재고조정 모달로만 변경
              ),
              _formField(
                label: l10n.minStock,
                controller: _minStockCtrl,
                hint: '10',
                isNumber: true,
                suffixText: '개',
              ),
              _formField(
                label: l10n.category,
                controller: _categoryCtrl,
                hint: l10n.categoryHint,
              ),

              // ─── 이미지 섹션 ──────────────────
              _sectionLabel('상품 이미지'),
              _buildImageSection(),
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
                      child: Text(l10n.cancel),
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
                          : Text(l10n.save, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
    final l10n = AppLocalizations.of(context)!;
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
          _showSnackBar(l10n.productUpdated, AppTheme.success);
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
          _showSnackBar(l10n.productAdded, AppTheme.success);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSnackBar(l10n.errorPrefix(e.toString()), AppTheme.error);
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

  // ── 이미지 섹션 빌더 ─────────────────────────────
  Widget _buildImageSection() {
    final imageState = ref.watch(imageUploadStateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image preview or placeholder
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: _localImageFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _localImageFile!,
                    fit: BoxFit.cover,
                  ),
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: AppTheme.textDisabled,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '이미지 없음',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 12),

        // Loading indicator
        if (imageState is ImageUploadLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),

        // Action buttons
        if (imageState is! ImageUploadLoading)
          Row(
            children: [
              // Camera button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleCameraUpload,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('카메라'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Gallery button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleGalleryUpload,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('갤러리'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // AI Search button (new row)
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _handleAISearch,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('AI 자동 검색'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

        // Delete button (if image exists)
        if (_localImageFile != null && imageState is! ImageUploadLoading)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: _handleDeleteImage,
              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
              label: const Text(
                '이미지 삭제',
                style: TextStyle(color: AppTheme.error),
              ),
            ),
          ),

        // Error message
        if (imageState is ImageUploadError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              imageState.message,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.error,
              ),
            ),
          ),
      ],
    );
  }

  // ── 이미지 핸들러 ─────────────────────────────
  Future<void> _handleCameraUpload() async {
    if (!_isEditMode && _skuCtrl.text.trim().isEmpty) {
      _showSnackBar('SKU를 먼저 입력해주세요', AppTheme.error);
      return;
    }

    final sku = _skuCtrl.text.trim();
    final productId = widget.existingProduct?.id ?? 0;

    final notifier = ref.read(imageUploadStateProvider.notifier);
    final file = await notifier.uploadFromCamera(productId, sku);

    if (file != null && mounted) {
      setState(() {
        _localImageFile = file;
        _imageUrl = 'product_images/$sku.jpg';
      });
      _showSnackBar('이미지가 업로드되었습니다', AppTheme.success);
    }
  }

  Future<void> _handleGalleryUpload() async {
    if (!_isEditMode && _skuCtrl.text.trim().isEmpty) {
      _showSnackBar('SKU를 먼저 입력해주세요', AppTheme.error);
      return;
    }

    final sku = _skuCtrl.text.trim();
    final productId = widget.existingProduct?.id ?? 0;

    final notifier = ref.read(imageUploadStateProvider.notifier);
    final file = await notifier.uploadFromGallery(productId, sku);

    if (file != null && mounted) {
      setState(() {
        _localImageFile = file;
        _imageUrl = 'product_images/$sku.jpg';
      });
      _showSnackBar('이미지가 업로드되었습니다', AppTheme.success);
    }
  }

  Future<void> _handleDeleteImage() async {
    if (!_isEditMode && _skuCtrl.text.trim().isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이미지 삭제'),
        content: const Text('정말로 이미지를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final sku = _skuCtrl.text.trim();
    final productId = widget.existingProduct?.id ?? 0;

    final notifier = ref.read(imageUploadStateProvider.notifier);
    await notifier.deleteImage(productId, sku);

    if (mounted) {
      setState(() {
        _localImageFile = null;
        _imageUrl = null;
      });
      _showSnackBar('이미지가 삭제되었습니다', AppTheme.success);
    }
  }

  Future<void> _handleAISearch() async {
    // Validate product name
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnackBar('상품명을 먼저 입력해주세요', AppTheme.error);
      return;
    }

    if (!_isEditMode && _skuCtrl.text.trim().isEmpty) {
      _showSnackBar('SKU를 먼저 입력해주세요', AppTheme.error);
      return;
    }

    // Show AI search dialog
    final SearchImageResult? selectedImage = await showDialog<SearchImageResult>(
      context: context,
      builder: (context) => ImageSearchDialog(
        productName: _nameCtrl.text.trim(),
      ),
    );

    if (selectedImage == null || !mounted) return;

    // Download and save selected image
    try {
      setState(() => _isProcessing = true);

      final searchService = ref.read(imageSearchServiceProvider);
      final sku = _skuCtrl.text.trim();

      final imagePath = await searchService.downloadAndSaveImage(
        imageUrl: selectedImage.regularUrl,
        sku: sku,
      );

      // Update DB if in edit mode
      if (_isEditMode) {
        final productId = widget.existingProduct!.id;
        final dao = ref.read(productsDaoProvider);
        await dao.updateProductImageUrl(
          productId,
          'product_images/$sku.jpg',
        );
      }

      // Update local state
      setState(() {
        _localImageFile = File(imagePath);
        _imageUrl = 'product_images/$sku.jpg';
        _isProcessing = false;
      });

      _showSnackBar('AI 검색으로 이미지가 설정되었습니다', AppTheme.success);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSnackBar('이미지 다운로드 실패: $e', AppTheme.error);
      }
    }
  }
}

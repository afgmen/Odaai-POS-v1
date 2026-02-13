import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';
import '../../../../providers/currency_provider.dart';
import '../../domain/models/search_image_result.dart';
import '../../providers/products_management_provider.dart';
import '../../services/excel_service.dart';
import '../providers/image_providers.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/product_form_modal.dart';
import '../widgets/stock_adjustment_modal.dart';

/// 상품관리 메인 화면
class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  ConsumerState<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends ConsumerState<ProductManagementScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final searchQuery = ref.watch(mgmtSearchQueryProvider);
    final selectedCategory = ref.watch(mgmtSelectedCategoryProvider);
    final categoriesAsync = ref.watch(mgmtCategoryListProvider);
    final productsAsync = ref.watch(mgmtFilteredProductsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        titleSpacing: 16,
        title: Text(l10n.productManagement, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
        actions: [
          // ── 엑셀 업로드 / 다운로드 드롭다운 ──
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.description_outlined, color: AppTheme.textSecondary),
              tooltip: l10n.excelManage,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: AppTheme.cardWhite,
              elevation: 4,
              onSelected: (value) {
                if (value == 'download') _handleDownload();
                if (value == 'upload') _handleUpload();
              },
              itemBuilder: (_) => [
                PopupMenuItem<String>(
                  value: 'download',
                  enabled: !_isExporting,
                  child: ListTile(
                    leading: Icon(Icons.download_outlined, color: AppTheme.primary, size: 20),
                    title: Text(l10n.excelDownload, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                    subtitle: Text(l10n.excelDownloadDesc, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'upload',
                  enabled: !_isImporting,
                  child: ListTile(
                    leading: Icon(Icons.upload_outlined, color: AppTheme.success, size: 20),
                    title: Text(l10n.excelUpload, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                    subtitle: Text(l10n.excelUploadDesc, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          // ── AI Auto Image Search Button ──────────
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: () => _handleBatchImageProcess(ref),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(l10n.aiImageSearch),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // ── 상품 추가 버튼 ──────────────────
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showProductForm(context, null),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addProduct),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── 검색 바 ─────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => ref.read(mgmtSearchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.cardWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.primary, width: 2),
                ),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textDisabled),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () => ref.read(mgmtSearchQueryProvider.notifier).state = '',
                        icon: const Icon(Icons.close, size: 18, color: AppTheme.textDisabled),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: l10n.searchProductHint,
                hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textDisabled),
              ),
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
            ),
          ),

          // ─── 카테고리 필터 Chip ───────────────
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: categoriesAsync.when(
              data: (categories) => Row(
                children: [
                  // "전체" 칩
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CategoryChip(
                      label: l10n.all,
                      isSelected: selectedCategory == null,
                      onTap: () => ref.read(mgmtSelectedCategoryProvider.notifier).state = null,
                    ),
                  ),
                  ...categories.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryChip(
                        label: cat,
                        isSelected: selectedCategory == cat,
                        onTap: () => ref.read(mgmtSelectedCategoryProvider.notifier).state = cat,
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
            ),
          ),

          // ─── 상품 테이블 ──────────────────────
          Expanded(
            child: productsAsync.when(
              data: (products) => _ProductTable(
                products: products,
                onEdit: (product) => _showProductForm(context, product),
                onStockAdjust: (product) => _showStockAdjustment(context, product),
                onDelete: (product) => _deleteProduct(context, ref, product),
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: AppTheme.error),
                    const SizedBox(height: 8),
                    Text(l10n.errorPrefix(err.toString()), style: const TextStyle(color: AppTheme.error)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 모달 표시 헬퍼 ──────────────────────────
  void _showProductForm(BuildContext context, Product? product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductFormModal(existingProduct: product),
    );
  }

  void _showStockAdjustment(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StockAdjustmentModal(product: product),
    );
  }

  Future<void> _deleteProduct(BuildContext context, WidgetRef ref, Product product) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteConfirmationDialog(productName: product.name),
    );
    if (confirmed == true && context.mounted) {
      final dao = ref.read(productsDaoProvider);
      await dao.deleteProduct(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.productDeleted(product.name), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
      }
    }
  }

  // ── 엑셀 다운로드 ─────────────────────────
  Future<void> _handleDownload() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isExporting = true);
    _showSnackBar(l10n.excelExporting, color: AppTheme.primary);

    final dao = ref.read(productsDaoProvider);
    final products = await dao.getAllProducts();

    if (!mounted) return;

    final filePath = await ExcelService.downloadProducts(
      products: products,
      context: context,
      labels: {
        'sheetName': l10n.excelSheetProductList,
        'headerProductName': l10n.excelHeaderProductName,
        'headerBarcode': l10n.excelHeaderBarcode,
        'headerCategory': l10n.excelHeaderCategory,
        'headerSellingPrice': l10n.excelHeaderSellingPrice,
        'headerCostPrice': l10n.excelHeaderCostPrice,
        'headerStock': l10n.excelHeaderStock,
        'headerMinStock': l10n.excelHeaderMinStock,
        'dialogSaveTitle': l10n.excelFileSave,
      },
    );

    setState(() => _isExporting = false);
    if (!mounted) return;

    if (filePath != null) {
      _showSnackBar(l10n.excelSaveComplete, color: AppTheme.success);
    } else {
      _showSnackBar(l10n.excelSaveFailed, color: AppTheme.error);
    }
  }

  // ── 엑셀 업로드 ───────────────────────────
  Future<void> _handleUpload() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isImporting = true);

    final dao = ref.read(productsDaoProvider);
    final db = ref.read(databaseProvider);

    final result = await ExcelService.uploadProducts(
      dao: dao,
      db: db,
      context: context,
      labels: {
        'dialogSelectTitle': l10n.excelFileSelect,
        'rowNameEmpty': l10n.excelRowNameEmpty('{row}'),
        'rowPriceError': l10n.excelRowPriceError('{row}'),
        'rowCostError': l10n.excelRowCostError('{row}'),
        'rowStockError': l10n.excelRowStockError('{row}'),
        'rowError': l10n.excelRowError('{error}', '{row}'),
      },
    );

    setState(() => _isImporting = false);
    if (!mounted) return;

    if (result == null) {
      // 파일 선택 취소
      return;
    }

    // ── 결과 다이얼로그 표시 ──────────────────
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (_) => _UploadResultDialog(result: result),
      );
      // 리스트 갱신을 위해 provider invalidate
      ref.invalidate(mgmtFilteredProductsProvider);
      ref.invalidate(mgmtCategoryListProvider);
    }
  }

  // ── AI 이미지 일괄 처리 ────────────────────
  Future<void> _handleBatchImageProcess(WidgetRef ref) async {
    final batchNotifier = ref.read(batchProcessProvider.notifier);

    // Start batch process
    await batchNotifier.startBatchProcess();

    // Show result dialog
    final state = ref.read(batchProcessProvider);
    if (state is BatchProcessCompleted && mounted) {
      await showDialog(
        context: context,
        builder: (_) => _BatchProcessResultDialog(result: state.result),
      );
      // Refresh list
      ref.invalidate(mgmtFilteredProductsProvider);
    } else if (state is BatchProcessError && mounted) {
      _showSnackBar(state.message, color: AppTheme.error);
    }
  }

  // ── 스냅바 헬퍼 ──────────────────────────
  void _showSnackBar(String message, {Color color = AppTheme.primary}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
  }
}

/// 업로드 결과 다이얼로그
class _UploadResultDialog extends StatelessWidget {
  final ExcelUploadResult result;

  const _UploadResultDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasErrors = result.errors.isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppTheme.cardWhite,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 타이틀 ──
          Row(
            children: [
              Icon(Icons.check_circle, color: hasErrors ? AppTheme.warning : AppTheme.success, size: 28),
              const SizedBox(width: 10),
              Text(
                l10n.uploadComplete,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── 결과 요약 카드 ──
          Container(
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              children: [
                _ResultRow(Icons.add_circle_outline, l10n.newProductAdded, result.inserted, AppTheme.success),
                const Divider(color: AppTheme.divider, height: 1),
                _ResultRow(Icons.edit_outlined, l10n.existingProductUpdated, result.updated, AppTheme.primary),
                const Divider(color: AppTheme.divider, height: 1),
                _ResultRow(Icons.inventory_2_outlined, l10n.totalProcessed, result.totalProcessed, AppTheme.textPrimary),
              ],
            ),
          ),

          // ── 오류 목록 ──
          if (hasErrors) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFDEBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.error, width: 0.5),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.errorsOccurred(result.errors.length),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.error),
                  ),
                  const SizedBox(height: 6),
                  ...result.errors.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(e, style: const TextStyle(fontSize: 12, color: AppTheme.error)),
                  )),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── 닫기 버튼 ──
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(l10n.ok, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      ), // Padding
    );
  }
}

/// 결과 행 (아이콘 + 레이블 + 숫자)
class _ResultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _ResultRow(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary))),
          Text(
            l10n.countUnit(value),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

/// Batch Process 결과 다이얼로그
class _BatchProcessResultDialog extends StatelessWidget {
  final BatchProcessResult result;

  const _BatchProcessResultDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasErrors = result.failed > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppTheme.cardWhite,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 타이틀 ──
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: hasErrors ? AppTheme.warning : AppTheme.success,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.aiImageSearchComplete,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── 결과 요약 카드 ──
            Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                children: [
                  _ResultRow(
                    Icons.check_circle_outline,
                    l10n.success,
                    result.success,
                    AppTheme.success,
                  ),
                  const Divider(color: AppTheme.divider, height: 1),
                  _ResultRow(
                    Icons.error_outline,
                    l10n.failed,
                    result.failed,
                    AppTheme.error,
                  ),
                  const Divider(color: AppTheme.divider, height: 1),
                  _ResultRow(
                    Icons.inventory_2_outlined,
                    l10n.totalProcessed,
                    result.total,
                    AppTheme.textPrimary,
                  ),
                  const Divider(color: AppTheme.divider, height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.percent, size: 20, color: AppTheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.successRate,
                            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                          ),
                        ),
                        Text(
                          '${result.successRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── 실패 목록 ──
            if (hasErrors && result.failedProducts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFDEBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.error, width: 0.5),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.failedProducts(result.failedProducts.length),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.error,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...result.failedProducts.take(5).map(
                          (name) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '• $name',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.error,
                              ),
                            ),
                          ),
                        ),
                    if (result.failedProducts.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          l10n.more,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── 닫기 버튼 ──
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  l10n.confirm,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 카테고리 필터 Chip
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// 상품 테이블
class _ProductTable extends ConsumerWidget {
  final List<Product> products;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onStockAdjust;
  final ValueChanged<Product> onDelete;

  const _ProductTable({
    required this.products,
    required this.onEdit,
    required this.onStockAdjust,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final priceFormatter = ref.watch(priceFormatterProvider);
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 56, color: AppTheme.textDisabled),
            const SizedBox(height: 12),
            Text(l10n.noProductsFound, style: const TextStyle(fontSize: 16, color: AppTheme.textDisabled)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.background),
              columnSpacing: 16,
              horizontalMargin: 16,
              headingTextStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              dataTextStyle: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              columns: [
                DataColumn(label: Text(l10n.image)),
                DataColumn(label: Text(l10n.productName)),
                const DataColumn(label: Text('SKU')),
                DataColumn(label: Text(l10n.category)),
                DataColumn(label: Text(l10n.sellingPrice), numeric: true),
                DataColumn(label: Text(l10n.costPrice), numeric: true),
                DataColumn(label: Text(l10n.stock), numeric: true),
                DataColumn(label: Text(l10n.minStock), numeric: true),
                DataColumn(label: Text(l10n.status)),
                DataColumn(label: Text(l10n.action)),
              ],
              rows: products.map((p) {
                final isLowStock = p.stock <= p.minStock;
                return DataRow(
                  cells: [
                    // 이미지
                    DataCell(
                      _ProductImage(imageUrl: p.imageUrl, sku: p.sku),
                      onTap: () => onEdit(p),
                    ),
                    // 상품명
                    DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)), onTap: () => onEdit(p)),
                    // SKU
                    DataCell(Text(p.sku, style: const TextStyle(color: AppTheme.textSecondary)), onTap: () => onEdit(p)),
                    // 카테고리
                    DataCell(
                      p.category != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(p.category!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            )
                          : const Text('-', style: TextStyle(color: AppTheme.textDisabled)),
                      onTap: () => onEdit(p),
                    ),
                    // 판매가
                    DataCell(Text(priceFormatter.format(p.price), style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)), onTap: () => onEdit(p)),
                    // 원가
                    DataCell(Text(priceFormatter.format(p.cost)), onTap: () => onEdit(p)),
                    // 재고
                    DataCell(
                      Text(
                        l10n.piecesUnit(p.stock),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: p.stock <= 0 ? AppTheme.error : (isLowStock ? AppTheme.warning : AppTheme.textPrimary),
                        ),
                      ),
                      onTap: () => onEdit(p),
                    ),
                    // 최소재고
                    DataCell(Text(l10n.piecesUnit(p.minStock)), onTap: () => onEdit(p)),
                    // 상태
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.stock <= 0 ? const Color(0xFFFDEBEB) : (isLowStock ? const Color(0xFFFFF3CD) : const Color(0xFFE6FAF2)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          p.stock <= 0 ? l10n.statusOutOfStock : (isLowStock ? l10n.statusLow : l10n.statusNormal),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.stock <= 0 ? AppTheme.error : (isLowStock ? AppTheme.warning : AppTheme.success),
                          ),
                        ),
                      ),
                      onTap: () => onEdit(p),
                    ),
                    // 액션 버튼
                    DataCell(
                      Row(
                        children: [
                          // 재고조정
                          IconButton(
                            onPressed: () => onStockAdjust(p),
                            icon: const Icon(Icons.inventory_2_outlined, size: 20, color: AppTheme.primary),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            tooltip: l10n.stockAdjust,
                          ),
                          // 삭제
                          IconButton(
                            onPressed: () => onDelete(p),
                            icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            tooltip: l10n.delete,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// 상품 이미지 썸네일
class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final String sku;

  const _ProductImage({
    required this.imageUrl,
    required this.sku,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
        color: AppTheme.background,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageUrl != null
            ? FutureBuilder<File?>(
                future: _getImageFile(imageUrl!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  if (snapshot.hasData && snapshot.data != null && snapshot.data!.existsSync()) {
                    return Image.file(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image,
                          color: AppTheme.textDisabled,
                          size: 24,
                        );
                      },
                    );
                  }

                  return const Icon(
                    Icons.image_not_supported,
                    color: AppTheme.textDisabled,
                    size: 24,
                  );
                },
              )
            : const Icon(
                Icons.image_not_supported,
                color: AppTheme.textDisabled,
                size: 24,
              ),
      ),
    );
  }

  Future<File?> _getImageFile(String imageUrl) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$imageUrl');
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

String _formatPrice(double price) {
  return price.toInt().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

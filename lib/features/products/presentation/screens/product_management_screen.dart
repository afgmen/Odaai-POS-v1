import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';
import '../../providers/products_management_provider.dart';
import '../../services/excel_service.dart';
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
        title: const Text('상품관리', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
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
              tooltip: '엑셀 관리',
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
                    title: const Text('엑셀로 다운로드', style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                    subtitle: const Text('현재 상품 목록 내보내기', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'upload',
                  enabled: !_isImporting,
                  child: ListTile(
                    leading: Icon(Icons.upload_outlined, color: AppTheme.success, size: 20),
                    title: const Text('엑셀에서 업로드', style: TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                    subtitle: const Text('.xlsx 파일로 상품 추가/수정', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          // ── 상품 추가 버튼 ──────────────────
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showProductForm(context, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('상품 추가'),
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
                hintText: '상품명, SKU, 바코드 검색...',
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
                      label: '전체',
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
                    Text('오류: $err', style: const TextStyle(color: AppTheme.error)),
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
              content: Text("'${product.name}'이(가) 삭제되었습니다", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
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
    setState(() => _isExporting = true);
    _showSnackBar('엑셀 파일 생성 중...', color: AppTheme.primary);

    final dao = ref.read(productsDaoProvider);
    final products = await dao.getAllProducts();

    if (!mounted) return;

    final filePath = await ExcelService.downloadProducts(
      products: products,
      context: context,
    );

    setState(() => _isExporting = false);
    if (!mounted) return;

    if (filePath != null) {
      _showSnackBar('엑셀 파일 저장 완료!', color: AppTheme.success);
    } else {
      _showSnackBar('저장 취소 또는 실패. 다시 시도하세요.', color: AppTheme.error);
    }
  }

  // ── 엑셀 업로드 ───────────────────────────
  Future<void> _handleUpload() async {
    setState(() => _isImporting = true);

    final dao = ref.read(productsDaoProvider);
    final db = ref.read(databaseProvider);

    final result = await ExcelService.uploadProducts(
      dao: dao,
      db: db,
      context: context,
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
                '업로드 완료',
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
                _ResultRow(Icons.add_circle_outline, '새 상품 추가', result.inserted, AppTheme.success),
                const Divider(color: AppTheme.divider, height: 1),
                _ResultRow(Icons.edit_outlined, '기존 상품 수정', result.updated, AppTheme.primary),
                const Divider(color: AppTheme.divider, height: 1),
                _ResultRow(Icons.inventory_2_outlined, '총 처리 건수', result.totalProcessed, AppTheme.textPrimary),
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
                    '⚠️ ${result.errors.length}건 오류 발생',
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
              child: const Text('확인', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary))),
          Text(
            '$value건',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color),
          ),
        ],
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
class _ProductTable extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 56, color: AppTheme.textDisabled),
            const SizedBox(height: 12),
            const Text('상품이 없습니다', style: TextStyle(fontSize: 16, color: AppTheme.textDisabled)),
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
              columns: const [
                DataColumn(label: Text('상품명')),
                DataColumn(label: Text('SKU')),
                DataColumn(label: Text('카테고리')),
                DataColumn(label: Text('판매가'), numeric: true),
                DataColumn(label: Text('원가'), numeric: true),
                DataColumn(label: Text('재고'), numeric: true),
                DataColumn(label: Text('최소재고'), numeric: true),
                DataColumn(label: Text('상태')),
                DataColumn(label: Text('액션')),
              ],
              rows: products.map((p) {
                final isLowStock = p.stock <= p.minStock;
                return DataRow(
                  cells: [
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
                    DataCell(Text('₩${_formatPrice(p.price)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary)), onTap: () => onEdit(p)),
                    // 원가
                    DataCell(Text('₩${_formatPrice(p.cost)}'), onTap: () => onEdit(p)),
                    // 재고
                    DataCell(
                      Text(
                        '${p.stock}개',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: p.stock <= 0 ? AppTheme.error : (isLowStock ? AppTheme.warning : AppTheme.textPrimary),
                        ),
                      ),
                      onTap: () => onEdit(p),
                    ),
                    // 최소재고
                    DataCell(Text('${p.minStock}개'), onTap: () => onEdit(p)),
                    // 상태
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.stock <= 0 ? const Color(0xFFFDEBEB) : (isLowStock ? const Color(0xFFFFF3CD) : const Color(0xFFE6FAF2)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          p.stock <= 0 ? '품절' : (isLowStock ? '잔재고' : '정상'),
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
                            tooltip: '재고 조정',
                          ),
                          // 삭제
                          IconButton(
                            onPressed: () => onDelete(p),
                            icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.error),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            tooltip: '삭제',
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

String _formatPrice(double price) {
  return price.toInt().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

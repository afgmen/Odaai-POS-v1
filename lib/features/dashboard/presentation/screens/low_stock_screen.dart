import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/database_providers.dart';
import '../../providers/dashboard_provider.dart';
import '../../../../core/utils/snackbar_helper.dart';

/// 재고 부족 알림 화면
class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncProducts = ref.watch(lowStockStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            // 경고 아이콘 배지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFDEBEB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.error),
                  const SizedBox(width: 4),
                  asyncProducts.when(
                    data: (list) => Text(
                      '${list.length}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.error),
                    ),
                    loading: () => const Text('...', style: TextStyle(fontSize: 13, color: AppTheme.error)),
                    error: (_, _) => const Text('!', style: TextStyle(fontSize: 13, color: AppTheme.error)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.lowStockAlert,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),
      body: asyncProducts.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6FAF2),
                      borderRadius: BorderRadius.circular(36),
                    ),
                    child: const Icon(Icons.check_circle_outlined, size: 36, color: AppTheme.success),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.allStockSufficient,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.aboveMinStock,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: EdgeInsets.only(bottom: i < products.length - 1 ? 10 : 0),
                child: _LowStockCard(
                  product: products[i],
                  onRestock: () => _showRestockDialog(context, ref, products[i]),
                ),
              );
            },
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppTheme.error),
              const SizedBox(height: 8),
              Text(l10n.msgError(err.toString()), style: const TextStyle(color: AppTheme.error)),
            ],
          ),
        ),
      ),
    );
  }

  /// 재고 조정 다이얼로그
  Future<void> _showRestockDialog(BuildContext context, WidgetRef ref, Product product) async {
    final l10n = AppLocalizations.of(context)!;
    final dao = ref.read(productsDaoProvider);
    int addQty = 0;
    final supplierCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setLocalState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text(
                      l10n.addStockTitle(product.name),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.currentStock(product.stock, product.minStock),
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 18),

                    // 수량 입력
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () => setLocalState(() { if (addQty > 0) addQty--; }),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: const Icon(Icons.remove, size: 20, color: AppTheme.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$addQty',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () => setLocalState(() { addQty++; }),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add, size: 20, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 빠른 추가 버튼
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [5, 10, 20, 50].map((n) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => setLocalState(() { addQty = n; }),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: Text('+$n', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // 입고 출처 (supplier_name)
                    Text(l10n.stockSource, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: supplierCtrl,
                      decoration: InputDecoration(
                        hintText: l10n.stockSourceHint,
                        prefixIcon: const Icon(Icons.local_shipping_outlined, size: 20),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 메모 (reason)
                    Text(l10n.reasonOptional, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteCtrl,
                      decoration: InputDecoration(
                        hintText: l10n.reasonHint,
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 버튼 행
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.pop(ctx, false),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: Center(child: Text(l10n.cancel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary))),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              if (addQty > 0) Navigator.pop(ctx, true);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: addQty > 0 ? AppTheme.primary : AppTheme.textDisabled,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(child: Text(l10n.addStock, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    final supplier = supplierCtrl.text.trim();
    final note = noteCtrl.text.trim();
    supplierCtrl.dispose();
    noteCtrl.dispose();

    if (result == true && context.mounted) {
      try {
        await dao.updateStock(
          productId: product.id,
          quantity: addQty,
          type: 'in',
          reason: note.isNotEmpty ? note : l10n.stockReplenishReason,
          supplierName: supplier.isNotEmpty ? supplier : null,
        );
        // T-8: POS 화면 즉시 갱신
        ref.read(productChangeSignalProvider.notifier).state++;
        if (context.mounted) {
          SnackBarHelper.showSuccess(context, l10n.stockAddedMsg(product.name, addQty));
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarHelper.showSanitizedError(context, e);
        }
      }
    }
  }
}

// ── 재고 부족 카드 ──────────────────────────────────
class _LowStockCard extends StatelessWidget {
  final Product product;
  final VoidCallback onRestock;

  const _LowStockCard({required this.product, required this.onRestock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 재고 == 0 이면 빨강, 아니면 주황
    final isOutOfStock = product.stock <= 0;
    final statusColor = isOutOfStock ? AppTheme.error : AppTheme.warning;
    final statusBg = isOutOfStock ? const Color(0xFFFDEBEB) : const Color(0xFFFFF3E0);
    final statusLabel = isOutOfStock ? l10n.outOfStockLabel : l10n.lowStockLabel;

    // 재고 비율 (현재 / 최소) — 최소재고 기준으로 퍼센트
    final ratio = product.minStock > 0
        ? (product.stock / product.minStock).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 상품명 + 상태 배지
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${product.sku}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusLabel,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 재고 수치 행
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoChip(label: l10n.currentStockLabel, value: '${product.stock}'),
              _InfoChip(label: l10n.minStockLabel, value: '${product.minStock}'),
              _InfoChip(label: l10n.needReplenish, value: '${product.minStock - product.stock}',
                  valueColor: statusColor),
            ],
          ),
          const SizedBox(height: 10),

          // 재고 프로그레스 바
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppTheme.background,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // 재고 추가 버튼
          SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: onRestock,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Text(l10n.addStock,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 정보 칩 ────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoChip({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppTheme.textPrimary)),
      ],
    );
  }
}

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../providers/database_providers.dart';
import '../../providers/refunds_provider.dart';

/// 환불/반품 처리 화면
class RefundScreen extends ConsumerStatefulWidget {
  const RefundScreen({super.key});

  @override
  ConsumerState<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends ConsumerState<RefundScreen> {
  final _saleNumberCtrl = TextEditingController();
  Sale? _foundSale;
  List<SaleItem>? _saleItems;
  final Map<int, int> _refundQuantities = {}; // saleItemId → qty to refund
  String? _reason;

  @override
  void dispose() {
    _saleNumberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todayRefunds = ref.watch(todayRefundsProvider);
    final currencyFormat = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(l10n.refundManagement), centerTitle: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── 영수증 검색 ─────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.searchByReceipt, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _saleNumberCtrl,
                            decoration: InputDecoration(
                              hintText: l10n.receiptNumberHint,
                              prefixIcon: const Icon(Icons.receipt),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _searchSale,
                          child: Text(l10n.search),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── 검색 결과 ──────────────────────────
            if (_foundSale != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('#${_foundSale!.saleNumber}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _foundSale!.status == 'refunded'
                                  ? AppTheme.error.withAlpha(20)
                                  : AppTheme.success.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _foundSale!.status == 'refunded' ? l10n.refundedStatus : l10n.paidStatus,
                              style: TextStyle(
                                color: _foundSale!.status == 'refunded' ? AppTheme.error : AppTheme.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₩${currencyFormat.format(_foundSale!.total.toInt())} · ${_foundSale!.paymentMethod}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm').format(_foundSale!.createdAt),
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),

                      if (_saleItems != null && _foundSale!.status != 'refunded') ...[
                        const SizedBox(height: 16),
                        Text(l10n.selectRefundItems, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ..._saleItems!.map((item) => _RefundItemRow(
                              item: item,
                              refundQty: _refundQuantities[item.id] ?? 0,
                              onChanged: (qty) => setState(() {
                                if (qty == 0) {
                                  _refundQuantities.remove(item.id);
                                } else {
                                  _refundQuantities[item.id] = qty;
                                }
                              }),
                            )),

                        const SizedBox(height: 12),
                        TextField(
                          decoration: InputDecoration(
                            labelText: l10n.refundReasonLabel,
                            hintText: l10n.refundReasonHint,
                            prefixIcon: const Icon(Icons.note),
                          ),
                          onChanged: (val) => _reason = val,
                        ),

                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _refundQuantities.isEmpty ? null : _processPartialRefund,
                                icon: const Icon(Icons.undo),
                                label: Text(l10n.partialRefund(currencyFormat.format(_calculatePartialRefund()))),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _processFullRefund,
                                icon: const Icon(Icons.replay),
                                label: Text(l10n.fullRefund),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (_foundSale!.status == 'refunded')
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(l10n.alreadyRefunded,
                              style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // ─── 오늘 환불 내역 ─────────────────────
            const SizedBox(height: 24),
            Text(l10n.todayRefundHistory, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            todayRefunds.when(
              data: (refundList) {
                if (refundList.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text(l10n.noRefundToday, style: const TextStyle(color: AppTheme.textSecondary))),
                    ),
                  );
                }
                return Column(
                  children: refundList.map((r) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.undo, color: AppTheme.error),
                      title: Text('#${r.originalSaleNumber}'),
                      subtitle: Text('${r.refundType == 'full' ? l10n.fullRefundType : l10n.partialRefundType} · ${r.reason ?? '-'}'),
                      trailing: Text(
                        '-₩${currencyFormat.format(r.refundAmount.toInt())}',
                        style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700),
                      ),
                    ),
                  )).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(l10n.msgError(e.toString())),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchSale() async {
    final l10n = AppLocalizations.of(context)!;
    final query = _saleNumberCtrl.text.trim();
    if (query.isEmpty) return;

    final db = ref.read(databaseProvider);
    // 영수증 번호 또는 ID로 검색
    final sale = await (db.select(db.sales)
          ..where((s) => s.saleNumber.equals(query)))
        .getSingleOrNull();

    if (sale == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.receiptNotFound)),
      );
      return;
    }

    final items = await (db.select(db.saleItems)
          ..where((si) => si.saleId.equals(sale!.id)))
        .get();

    setState(() {
      _foundSale = sale;
      _saleItems = items;
      _refundQuantities.clear();
    });
  }

  int _calculatePartialRefund() {
    if (_saleItems == null) return 0;
    int total = 0;
    for (final entry in _refundQuantities.entries) {
      final item = _saleItems!.firstWhere((i) => i.id == entry.key);
      total += (item.unitPrice * entry.value).toInt();
    }
    return total;
  }

  Future<void> _processFullRefund() async {
    final l10n = AppLocalizations.of(context)!;
    if (_foundSale == null) return;
    final confirm = await _confirmRefund(l10n.fullRefund, _foundSale!.total.toInt());
    if (!confirm) return;

    final dao = ref.read(refundsDaoProvider);
    final db = ref.read(databaseProvider);

    // 환불 기록 생성
    final refundId = await dao.createRefund(RefundsCompanion.insert(
      originalSaleId: _foundSale!.id,
      originalSaleNumber: _foundSale!.saleNumber,
      refundAmount: _foundSale!.total,
      reason: Value(_reason),
      refundType: 'full',
    ));

    // 주문 상태 변경
    await (db.update(db.sales)..where((s) => s.id.equals(_foundSale!.id)))
        .write(const SalesCompanion(status: Value('refunded')));

    // 재고 복구
    if (_saleItems != null) {
      for (final item in _saleItems!) {
        await db.productsDao.updateStock(productId: item.productId, quantity: item.quantity, type: 'in', reason: 'refund_stock_restore');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fullRefundComplete), backgroundColor: AppTheme.success),
      );
      setState(() {
        _foundSale = _foundSale!.copyWith(status: 'refunded');
      });
    }
  }

  Future<void> _processPartialRefund() async {
    final l10n = AppLocalizations.of(context)!;
    if (_foundSale == null || _refundQuantities.isEmpty) return;
    final amount = _calculatePartialRefund();
    final confirm = await _confirmRefund(l10n.partialRefundType, amount);
    if (!confirm) return;

    final dao = ref.read(refundsDaoProvider);
    final db = ref.read(databaseProvider);

    // 환불 기록 생성
    final refundId = await dao.createRefund(RefundsCompanion.insert(
      originalSaleId: _foundSale!.id,
      originalSaleNumber: _foundSale!.saleNumber,
      refundAmount: amount.toDouble(),
      reason: Value(_reason),
      refundType: 'partial',
    ));

    // 환불 항목 생성 + 재고 복구
    final refundItemsList = <RefundItemsCompanion>[];
    for (final entry in _refundQuantities.entries) {
      final item = _saleItems!.firstWhere((i) => i.id == entry.key);
      refundItemsList.add(RefundItemsCompanion.insert(
        refundId: refundId,
        saleItemId: item.id,
        productId: item.productId,
        productName: item.productName,
        quantity: entry.value,
        unitPrice: item.unitPrice,
        total: item.unitPrice * entry.value,
      ));
      await db.productsDao.updateStock(productId: item.productId, quantity: entry.value, type: 'in', reason: 'partial_refund_stock_restore');
    }
    await dao.insertRefundItems(refundItemsList);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.partialRefundComplete), backgroundColor: AppTheme.success),
      );
      setState(() {
        _refundQuantities.clear();
      });
    }
  }

  Future<bool> _confirmRefund(String type, int amount) async {
    final currencyFormat = NumberFormat('#,###');
    return await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final l10nDialog = AppLocalizations.of(ctx)!;
            return AlertDialog(
              title: Text(type),
              content: Text(l10nDialog.refundConfirm(currencyFormat.format(amount))),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10nDialog.cancel)),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                  child: Text(l10nDialog.refundAction),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

/// 환불 항목 행
class _RefundItemRow extends StatelessWidget {
  final SaleItem item;
  final int refundQty;
  final ValueChanged<int> onChanged;

  const _RefundItemRow({required this.item, required this.refundQty, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '₩${currencyFormat.format(item.unitPrice.toInt())} x ${item.quantity}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          // 수량 조절
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: refundQty > 0 ? () => onChanged(refundQty - 1) : null,
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$refundQty',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: refundQty > 0 ? AppTheme.error : AppTheme.textSecondary,
                  ),
                ),
              ),
              IconButton(
                onPressed: refundQty < item.quantity ? () => onChanged(refundQty + 1) : null,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:drift/drift.dart' show Value;

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';
import '../../../cash_drawer/providers/cash_drawer_provider.dart';
import '../../../sales/providers/sales_provider.dart';
import '../../../dashboard/providers/dashboard_provider.dart';

/// 주문 상세 화면 (주문번호 + 상품 목록 + 환불 버튼)
class SaleDetailScreen extends ConsumerStatefulWidget {
  final int saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  @override
  ConsumerState<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends ConsumerState<SaleDetailScreen> {
  Sale? _sale;
  List<SaleItem>? _items;
  bool _isLoading = true;
  bool _isRefunding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dao = ref.read(salesDaoProvider);
    final sale = await dao.getSaleById(widget.saleId);
    final items = await dao.getSaleItems(widget.saleId);
    if (mounted) {
      setState(() {
        _sale = sale;
        _items = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _sale == null || _items == null) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final sale = _sale!;
    final items = _items!;
    final isRefunded = sale.status == 'refunded';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardWhite,
        elevation: 0,
        title: const Text(
          'Order Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.divider),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 주문 헤더 카드 ──────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 주문번호 + 상태 배지
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        sale.saleNumber,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                      _StatusBadge(status: sale.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 날짜 · 결제 방법
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 15, color: AppTheme.textSecondary),
                      const SizedBox(width: 5),
                      Text(
                        _formatDateTime(sale.saleDate),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.payment_outlined, size: 15, color: AppTheme.textSecondary),
                      const SizedBox(width: 5),
                      Text(
                        _paymentLabel(sale.paymentMethod),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 상품 목록 카드 ──────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상품 목록 헤더
                  Padding(
                    padding: const EdgeInsets.only(left: 18, right: 18, top: 16, bottom: 10),
                    child: const Text(
                      'Products',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.divider),

                  // 상품 행
                  ...List.generate(items.length, (i) {
                    final item = items[i];
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          child: Row(
                            children: [
                              // 상품명 + SKU
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'SKU: ${item.sku}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              // 수량 × 단가
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₫${_fmt(item.total)}',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.quantity} x ₫${_fmt(item.unitPrice)}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 마지막 아이템이 아니면 구분선
                        if (i < items.length - 1) const Divider(height: 1, color: AppTheme.divider),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 금액 요약 카드 ──────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.cardWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                children: [
                  _AmountRow(label: 'Subtotal', value: sale.subtotal),
                  if (sale.discount > 0) _AmountRow(label: 'Discount', value: -sale.discount, color: AppTheme.error),
                  if (sale.tax > 0) _AmountRow(label: 'Tax', value: sale.tax),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppTheme.divider),
                  const SizedBox(height: 8),
                  _AmountRow(label: 'Total', value: sale.total, isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── 환불 버튼 (완료 상태일 때만) ────────
            if (!isRefunded)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isRefunding ? null : () => _showRefundConfirmation(),
                  icon: const Icon(Icons.replay_outlined, size: 18),
                  label: const Text('Refund Request'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── 환불 확인 다이얼로그 ──────────────────────────
  Future<void> _showRefundConfirmation() async {
    String? refundReason;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_outlined, size: 40, color: AppTheme.warning),
              const SizedBox(height: 12),
              const Text(
                'Refund Confirmation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Hoàn toàn bộ ₫${_fmt(_sale!.total)} cho đơn ${_sale!.saleNumber}?',
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // ✅ CRITICAL FIX 1: Add TextField for refund reason
              TextField(
                decoration: InputDecoration(
                  labelText: 'Refund Reason',
                  hintText: 'Enter reason for refund (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 2,
                onChanged: (val) => refundReason = val.trim().isEmpty ? null : val.trim(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.divider),
                        foregroundColor: AppTheme.textSecondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Refund'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isRefunding = true);

    try {
      final dao = ref.read(salesDaoProvider);
      await dao.refundSale(widget.saleId, 1, reason: refundReason); // employeeId: 1 (기본 관리자)

      // 현금 결제 환불 시 Cash Drawer에 refund 로그 기록
      if (_sale!.paymentMethod == 'cash') {
        final cashDao = ref.read(cashDrawerDaoProvider);
        final currentBalance = await cashDao.getCurrentDrawerBalance();
        final refundAmount = _sale!.total;
        await cashDao.logCashDrawer(CashDrawerLogsCompanion.insert(
          type: 'refund',
          amount: -refundAmount,
          balanceBefore: currentBalance,
          balanceAfter: currentBalance - refundAmount,
          note: Value(refundReason ?? 'Refund for ${_sale!.saleNumber}'),
        ));
        ref.invalidate(currentDrawerBalanceProvider);
      }

      // B-098: 주문 목록 + 대시보드 Total Sales 강제 갱신
      ref.invalidate(salesListProvider);
      ref.invalidate(totalSalesProvider);

      // 로컬 상태 갱신
      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Refund completed.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefunding = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Refund failed: $e', style: const TextStyle(color: Colors.white)),
              backgroundColor: AppTheme.error,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
      }
    }
  }
}

// ── 상태 배지 ────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isRefunded = status == 'refunded';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isRefunded ? const Color(0xFFFDEBEB) : const Color(0xFFE6FAF2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isRefunded ? 'Refunded' : 'Paid',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isRefunded ? AppTheme.error : AppTheme.success,
        ),
      ),
    );
  }
}

// ── 금액 행 ──────────────────────────────────────
class _AmountRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  final Color? color;

  const _AmountRow({required this.label, required this.value, this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        Text(
          '₫${_fmt(value.abs())}',
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── 유틸리티 ──────────────────────────────────────

String _fmt(double price) {
  return price.toInt().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

String _formatDateTime(DateTime dt) {
  return '${dt.year}-${_p(dt.month)}-${_p(dt.day)} ${_p(dt.hour)}:${_p(dt.minute)}';
}

String _p(int v) => v.toString().padLeft(2, '0');

String _paymentLabel(String method) => switch (method) {
      'cash' => 'Cash',
      'card' => 'Card',
      'qr' => 'QR',
      _ => method,
    };

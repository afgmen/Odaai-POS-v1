import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../screens/receipt_screen.dart';

/// 결제 방법 열거형
enum PaymentMethod {
  cash('현금', Icons.attach_money),
  card('카드', Icons.credit_card),
  qr('QR', Icons.qr_code);

  final String label;
  final IconData icon;

  const PaymentMethod(this.label, this.icon);
}

/// 결제 모달 (BottomSheet)
class PaymentModal extends ConsumerStatefulWidget {
  const PaymentModal({super.key});

  @override
  ConsumerState<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends ConsumerState<PaymentModal> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  double _cashInput = 0;
  bool _isProcessing = false;
  late final TextEditingController _cashController;

  @override
  void initState() {
    super.initState();
    _cashController = TextEditingController();
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = ref.watch(cartSubtotalProvider);
    final allDiscount = ref.watch(cartAllDiscountProvider);
    final total = ref.watch(cartTotalProvider);
    final change = _selectedMethod == PaymentMethod.cash ? (_cashInput - total) : 0.0;
    final isCashValid = _selectedMethod != PaymentMethod.cash || _cashInput >= total;

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
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── 헤더 ─────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '결제 방법 선택',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 22, color: AppTheme.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 금액 요약
            if (allDiscount > 0) ...[
              Text(
                '소계: ₩${_formatPrice(subtotal)}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              Text(
                '할인: -₩${_formatPrice(allDiscount)}',
                style: const TextStyle(fontSize: 13, color: AppTheme.error),
              ),
            ],
            Text(
              '결제 금액: ₩${_formatPrice(total)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 20),

            // ─── 결제 방법 선택 버튼 ────────────────
            Row(
              children: PaymentMethod.values.map((method) {
                final isActive = _selectedMethod == method;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: method == PaymentMethod.values.last ? 0 : 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedMethod = method),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFE8F0FE) : AppTheme.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive ? AppTheme.primary : AppTheme.divider,
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(method.icon, size: 28, color: isActive ? AppTheme.primary : AppTheme.iconColor),
                            const SizedBox(height: 6),
                            Text(
                              method.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // ─── 현금 입력 (현금 선택 시만 표시) ────
            if (_selectedMethod == PaymentMethod.cash) ...[
              const SizedBox(height: 18),
              const Text(
                '현금 투입 금액',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 6),
              // 빠른 금액 버튼
              Row(
                children: [10000, 50000, 100000].map((amount) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: amount == 100000 ? 0 : 6),
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _cashInput = amount.toDouble());
                          _cashController.text = _formatPrice(amount.toDouble());
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: const BorderSide(color: AppTheme.divider),
                          foregroundColor: AppTheme.textPrimary,
                        ),
                        child: Text('₩${_formatPrice(amount.toDouble())}', style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // 현금 금액 입력
              TextField(
                controller: _cashController,
                keyboardType: const TextInputType.numberWithOptions(),
                decoration: InputDecoration(
                  prefixText: '₩',
                  prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primary),
                  hintText: '금액 입력',
                ),
                onChanged: (value) {
                  final cleaned = value.replaceAll(',', '');
                  setState(() => _cashInput = double.tryParse(cleaned) ?? 0);
                },
              ),
              const SizedBox(height: 12),
              // 거스름돈
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: change >= 0 ? const Color(0xFFE6FAF2) : const Color(0xFFFDEBEB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '거스름돈',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: change >= 0 ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                    Text(
                      '₩${_formatPrice(change.abs())}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: change >= 0 ? AppTheme.success : AppTheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ─── 결제 완료 버튼 ─────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: (!isCashValid || _isProcessing) ? null : () => _processPayment(subtotal, allDiscount, total),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  disabledBackgroundColor: AppTheme.textDisabled,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('결제 완료', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(double subtotal, double discountAmount, double total) async {
    setState(() => _isProcessing = true);

    try {
      final cart = ref.read(cartProvider);
      final dao = ref.read(salesDaoProvider);
      final currentEmployee = ref.read(currentEmployeeProvider);

      // 현재 로그인한 직원이 없으면 에러
      if (currentEmployee == null) {
        throw Exception('로그인한 직원이 없습니다');
      }

      // ── 매출 번호 생성 (SO-YYYYMMDD-NNNNN) ──
      final now = DateTime.now();
      final dateStr = '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';
      final seqStr = (now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
      final saleNumber = 'SO-$dateStr-$seqStr';

      // ── Sales 레코드 구성 ──────────────────
      final saleCompanion = SalesCompanion.insert(
        saleNumber: saleNumber,
        paymentMethod: _selectedMethod.name, // 'cash' | 'card' | 'qr'
        subtotal: Value(subtotal),
        discount: Value(discountAmount),
        total: Value(total),
        employeeId: Value(currentEmployee.id),
        needsSync: const Value(true),
      );

      // ── SaleItems 레코드 구성 (장바구니 → DB) ─
      final saleItemsList = cart.map((item) {
        return SaleItemsCompanion.insert(
          saleId: 0, // 플레이스홀더 — createSale 내부에서 실제 ID로 교체
          productId: item.product.id,
          productName: item.product.name,
          sku: item.product.sku,
          unitPrice: item.product.price,
          quantity: item.quantity,
          total: item.subtotal,
        );
      }).toList();

      // ── DB 저장 (트랜잭션: 판매 기록 + 재고 차감) ─
      final createdSale = await dao.createSale(sale: saleCompanion, items: saleItemsList);

      // ── 저장된 SaleItems 조회 (영수증용) ───────
      final savedItems = await dao.getSaleItems(createdSale.id);

      if (mounted) {
        ref.read(cartProvider.notifier).clear();
        // 할인 state 초기화
        ref.read(discountValueProvider.notifier).state = 0;
        // 프로모션 state 초기화
        ref.read(promotionProductIdProvider.notifier).state = null;
        // 결제 모달 닫고 영수증 화면으로 전이
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReceiptScreen(
              saleNumber: saleNumber,
              items: savedItems,
              subtotal: subtotal,
              discount: discountAmount,
              total: total,
              paymentMethod: _selectedMethod.name,
              cashPaid: _cashInput,
              saleDate: createdSale.saleDate,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showPaymentError(e.toString());
      }
    }
  }

  void _showPaymentError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => _PaymentErrorDialog(message: message),
    );
  }
}

/// 결제 오류 다이얼로그
class _PaymentErrorDialog extends StatelessWidget {
  final String message;

  const _PaymentErrorDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 오류 아이콘
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFFDEBEB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 40, color: AppTheme.error),
            ),
            const SizedBox(height: 16),
            const Text(
              '결제 실패',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.error),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('확인'),
              ),
            ),
          ],
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

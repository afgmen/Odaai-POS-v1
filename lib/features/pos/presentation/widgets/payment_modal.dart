import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/currency_provider.dart';
import '../../../../providers/database_providers.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../customers/providers/customers_provider.dart';
import '../../../loyalty/domain/services/loyalty_service.dart';
import '../../providers/cart_provider.dart';
import '../screens/receipt_screen.dart';

/// 결제 방법 열거형
enum PaymentMethod {
  cash(Icons.attach_money),
  card(Icons.credit_card),
  qr(Icons.qr_code),
  transfer(Icons.account_balance);

  final IconData icon;

  const PaymentMethod(this.icon);

  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      PaymentMethod.cash => l10n.cashPayment,
      PaymentMethod.card => l10n.cardPayment,
      PaymentMethod.qr => l10n.qrPayment,
      PaymentMethod.transfer => l10n.transferPayment,
    };
  }
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
  late final TextEditingController _tableNumberController;
  late final TextEditingController _specialInstructionsController;

  @override
  void initState() {
    super.initState();
    _cashController = TextEditingController();
    _tableNumberController = TextEditingController();
    _specialInstructionsController = TextEditingController();
  }

  @override
  void dispose() {
    _cashController.dispose();
    _tableNumberController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtotal = ref.watch(cartSubtotalProvider);
    final allDiscount = ref.watch(cartAllDiscountProvider);
    final total = ref.watch(cartTotalProvider);
    final selectedCustomer = ref.watch(selectedCustomerProvider);
    final pointsToUse = ref.watch(pointsToUseProvider);
    final priceFormatter = ref.watch(priceFormatterProvider);

    // 포인트 사용 후 최종 금액
    final finalTotal = total - pointsToUse;
    final change = _selectedMethod == PaymentMethod.cash ? (_cashInput - finalTotal) : 0.0;
    final isCashValid = _selectedMethod != PaymentMethod.cash || _cashInput >= finalTotal;

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
                Text(
                  l10n.selectPaymentMethod,
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
            const SizedBox(height: 4),
            // 금액 요약
            if (allDiscount > 0) ...[
              Text(
                '${l10n.subtotal}: ₩${_formatPrice(subtotal)}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              Text(
                '${l10n.discount}: -₩${_formatPrice(allDiscount)}',
                style: const TextStyle(fontSize: 13, color: AppTheme.error),
              ),
            ],
            Text(
              '${l10n.paymentAmount}: ₩${_formatPrice(total)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            // 포인트 사용 정보
            if (selectedCustomer != null && pointsToUse > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Color(0xFFFF9800), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${selectedCustomer.name} - 포인트 사용',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE65100),
                            ),
                          ),
                          Text(
                            '-${_formatPrice(pointsToUse.toDouble())}P',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF9800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '최종 결제 금액: ₩${_formatPrice(finalTotal)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.success,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ─── 테이블 번호 & 특이사항 입력 (KDS 연동용) ────
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Table Number',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _tableNumberController,
                        decoration: InputDecoration(
                          hintText: 'e.g. T01',
                          prefixIcon: const Icon(Icons.table_restaurant, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.divider),
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Special Instructions',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _specialInstructionsController,
                        decoration: InputDecoration(
                          hintText: 'e.g. No sugar, Extra ice',
                          prefixIcon: const Icon(Icons.edit_note, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppTheme.divider),
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
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
                              method.localizedLabel(l10n),
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
              Text(
                l10n.cashInputAmount,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
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
                  prefixText: priceFormatter.currency.symbol,
                  prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primary),
                  hintText: l10n.enterAmount,
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
                      l10n.change,
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
                    : Text(l10n.paymentComplete, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(double subtotal, double discountAmount, double total) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isProcessing = true);

    try {
      final cart = ref.read(cartProvider);
      final dao = ref.read(salesDaoProvider);
      final db = ref.read(databaseProvider);
      final currentEmployee = ref.read(currentEmployeeProvider);
      final selectedCustomer = ref.read(selectedCustomerProvider);
      final pointsToUse = ref.read(pointsToUseProvider);

      // 현재 로그인한 직원이 없으면 에러
      if (currentEmployee == null) {
        throw Exception(l10n.noEmployeeLoggedIn);
      }

      // ── 매출 번호 생성 (SO-YYYYMMDD-NNNNN) ──
      final now = DateTime.now();
      final dateStr = '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}';
      final seqStr = (now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
      final saleNumber = 'SO-$dateStr-$seqStr';

      // ── 포인트 사용 처리 ──────────────────────
      double finalTotal = total;
      int usedPoints = 0;

      if (selectedCustomer != null && pointsToUse > 0) {
        // 포인트 검증
        final loyaltyService = ref.read(loyaltyServiceProvider);
        final validation = await loyaltyService.validatePointRedeem(
          customerId: selectedCustomer.id,
          pointsToUse: pointsToUse,
          saleAmount: total,
        );

        if (validation.isValid) {
          finalTotal = total - pointsToUse;
          usedPoints = pointsToUse;
        }
      }

      // ── Sales 레코드 구성 ──────────────────
      final saleCompanion = SalesCompanion.insert(
        saleNumber: saleNumber,
        paymentMethod: _selectedMethod.name, // 'cash' | 'card' | 'qr' | 'transfer'
        subtotal: Value(subtotal),
        discount: Value(discountAmount),
        total: Value(finalTotal),
        customerId: Value(selectedCustomer?.id),
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
      final createdSale = await dao.createSale(
        sale: saleCompanion,
        items: saleItemsList,
        tableNumber: _tableNumberController.text.trim().isNotEmpty ? _tableNumberController.text.trim() : null,
        specialInstructions: _specialInstructionsController.text.trim().isNotEmpty ? _specialInstructionsController.text.trim() : null,
        createKitchenOrder: true,
      );

      // ── 포인트 사용 및 적립 처리 ──────────────
      if (selectedCustomer != null) {
        final loyaltyService = ref.read(loyaltyServiceProvider);

        // 1. 포인트 사용
        if (usedPoints > 0) {
          await loyaltyService.redeemPoints(
            customerId: selectedCustomer.id,
            pointsToUse: usedPoints,
            saleId: createdSale.id,
            employeeId: currentEmployee.id,
          );
        }

        // 2. 포인트 적립 (실제 결제 금액 기준)
        await loyaltyService.earnPointsForSale(
          customerId: selectedCustomer.id,
          saleId: createdSale.id,
          saleAmount: finalTotal,
          employeeId: currentEmployee.id,
        );

        // 3. 고객 누적 구매액 업데이트
        await db.customersDao.updateTotalSpent(selectedCustomer.id, finalTotal.toInt());
      }

      // ── 저장된 SaleItems 조회 (영수증용) ───────
      final savedItems = await dao.getSaleItems(createdSale.id);

      if (mounted) {
        ref.read(cartProvider.notifier).clear();
        // 할인 state 초기화
        ref.read(discountValueProvider.notifier).state = 0;
        // 프로모션 state 초기화
        ref.read(promotionProductIdProvider.notifier).state = null;
        // 고객 선택 및 포인트 사용 초기화
        ref.read(selectedCustomerProvider.notifier).state = null;
        ref.read(pointsToUseProvider.notifier).state = 0;

        // 결제 모달 닫고 영수증 화면으로 전이
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReceiptScreen(
              saleNumber: saleNumber,
              items: savedItems,
              subtotal: subtotal,
              discount: discountAmount,
              total: finalTotal,
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
    final l10n = AppLocalizations.of(context)!;
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
            Text(
              l10n.paymentFailed,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.error),
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
                child: Text(l10n.confirm),
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

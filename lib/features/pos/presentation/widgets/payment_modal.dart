import 'dart:math';
import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import '../../providers/tax_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/currency_provider.dart';
import '../../../../providers/database_providers.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../customers/providers/customers_provider.dart';
import '../../../delivery/data/delivery_orders_dao.dart';
import '../../../loyalty/domain/services/loyalty_service.dart';
import '../../providers/cart_provider.dart';
import '../../data/models/order_type.dart';
import '../screens/receipt_screen.dart';
import '../../../cash_drawer/providers/cash_drawer_provider.dart';
import '../../../tables/data/tables_providers.dart';
import '../../../dashboard/providers/dashboard_provider.dart';
import '../../../daily_closing/providers/daily_closing_provider.dart';
import '../../../reports/providers/reports_provider.dart';
import '../../../sales/providers/sales_provider.dart';
import 'delivery_info_section.dart';

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
  final OrderType? orderType;
  final int? tableId;
  final int? saleId; // Open Tab 체크아웃 시 사용
  final double? billTotal; // BillRequestScreen에서 전달되는 실제 청구 금액
  final double billDiscount; // BillRequestScreen에서 전달되는 기존 할인 금액

  const PaymentModal({
    super.key,
    this.orderType,
    this.tableId,
    this.saleId,
    this.billTotal,
    this.billDiscount = 0,
  });

  @override
  ConsumerState<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends ConsumerState<PaymentModal> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  double _cashInput = 0;
  bool _isProcessing = false;
  bool _tableAutocompleteInitialized = false;
  late final TextEditingController _cashController;
  late final TextEditingController _tableNumberController;
  late final TextEditingController _specialInstructionsController;
  late final TextEditingController _customerNameController;
  late final TextEditingController _deliveryPhoneController;
  late final TextEditingController _deliveryAddressController;

  @override
  void initState() {
    super.initState();
    _selectedOrderType = widget.orderType ?? OrderType.dineIn;
    _cashController = TextEditingController();
    _tableNumberController = TextEditingController();
    _specialInstructionsController = TextEditingController();
    _customerNameController = TextEditingController();
    _deliveryPhoneController = TextEditingController();
    _deliveryAddressController = TextEditingController();
  }
  
  late OrderType _selectedOrderType;

  bool get _isDeliveryOrder =>
      _selectedOrderType == OrderType.phoneDelivery ||
      _selectedOrderType == OrderType.platformDelivery;

  @override
  void dispose() {
    _cashController.dispose();
    _tableNumberController.dispose();
    _specialInstructionsController.dispose();
    _customerNameController.dispose();
    _deliveryPhoneController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cartSubtotal = ref.watch(cartSubtotalProvider);
    final cartDiscount = ref.watch(cartAllDiscountProvider);
    final cartTotal = ref.watch(cartTotalProvider);
    // BillRequestScreen에서 기존 Sale의 금액을 직접 전달받는 경우 해당 금액 사용
    final subtotal = widget.billTotal ?? cartSubtotal;
    final allDiscount = widget.billTotal != null ? widget.billDiscount : cartDiscount;
    final total = widget.billTotal ?? cartTotal;
    final selectedCustomer = ref.watch(selectedCustomerProvider);
    final pointsToUse = ref.watch(pointsToUseProvider);
    final priceFormatter = ref.watch(priceFormatterProvider);

    // 포인트 사용 후 최종 금액
    final finalTotal = total - pointsToUse;
    final change = _selectedMethod == PaymentMethod.cash ? (_cashInput - finalTotal) : 0.0;
    final isCashValid = _selectedMethod != PaymentMethod.cash || _cashInput >= finalTotal;
    final activeTablesAsync = ref.watch(allTablesStreamProvider);
    final availableTables = activeTablesAsync.maybeWhen<List<RestaurantTable>>(
      data: (tables) => tables,
      orElse: () => [],
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      // B-109: 화면 높이에 맞게 최대 높이 제한 + 세로 스크롤 지원 (issue #16)
      child: ConstrainedBox(
        // 키보드 높이와 상태바를 고려한 동적 최대 높이
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height
              - MediaQuery.of(context).viewInsets.bottom
              - MediaQuery.of(context).padding.top
              - 20,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 24,
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
            // 금액 요약
            Text(
              '${l10n.subtotal}: ${priceFormatter.format(subtotal)}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            if (allDiscount > 0)
              Text(
                '${l10n.discount}: -${priceFormatter.format(allDiscount)}',
                style: const TextStyle(fontSize: 13, color: AppTheme.error),
              ),
            // VAT line
            if (ref.watch(taxEnabledProvider)) ...[
              Builder(builder: (context) {
                final taxAmount = ref.watch(cartTaxAmountProvider);
                final taxRate = ref.watch(taxRateProvider);
                final taxInclusive = ref.watch(taxInclusiveProvider);
                return Text(
                  'VAT (${taxRate.toStringAsFixed(0)}%)${taxInclusive ? " (included)" : ""}: ${priceFormatter.format(taxAmount)}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                );
              }),
            ],
            const SizedBox(height: 4),
            Text(
              '${l10n.paymentAmount}: ${priceFormatter.format(total)}',
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
                            '${selectedCustomer.name} - Points Redeemed',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE65100),
                            ),
                          ),
                          Text(
                            '-${priceFormatter.format(pointsToUse.toDouble())}P',
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
                'Total: ${priceFormatter.format(finalTotal)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.success,
                ),
              ),
            ],
            const SizedBox(height: 20),

            // ─── 주문 유형 선택 (B-074) — BillRequestScreen에서 열면 숨김 ────
            if (widget.billTotal == null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Type',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                SegmentedButton<OrderType>(
                  segments: const [
                    ButtonSegment<OrderType>(
                      value: OrderType.dineIn,
                      icon: Icon(Icons.restaurant),
                      label: Text('Dine-in'),
                    ),
                    ButtonSegment<OrderType>(
                      value: OrderType.takeaway,
                      icon: Icon(Icons.shopping_bag),
                      label: Text('Takeout'),
                    ),
                    ButtonSegment<OrderType>(
                      value: OrderType.phoneDelivery,
                      icon: Icon(Icons.delivery_dining),
                      label: Text('Delivery'),
                    ),
                  ],
                  selected: {_selectedOrderType},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _selectedOrderType = selection.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ], // end if (widget.billTotal == null) for Order Type

            // ─── 테이블 번호 & 특이사항 입력 (KDS 연동용, delivery 제외, BillRequestScreen 제외) ────
            if (widget.billTotal == null && !_isDeliveryOrder) ...[
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
                      Autocomplete<RestaurantTable>(
                        optionsBuilder: (textEditingValue) {
                          final query = textEditingValue.text.trim().toLowerCase();
                          if (availableTables.isEmpty) return const Iterable<RestaurantTable>.empty();
                          if (query.isEmpty) return availableTables;
                          return availableTables.where((table) {
                            final tableNumber = table.tableNumber.toLowerCase();
                            return tableNumber.contains(query);
                          });
                        },
                        displayStringForOption: (option) => option.tableNumber,
                        onSelected: (selection) {
                          setState(() {
                            _tableNumberController.text = selection.tableNumber;
                            _tableNumberController.selection = TextSelection.collapsed(
                              offset: _tableNumberController.text.length,
                            );
                          });
                        },
                        fieldViewBuilder: (
                          context,
                          textEditingController,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          if (!_tableAutocompleteInitialized) {
                            _tableAutocompleteInitialized = true;
                            textEditingController.text = _tableNumberController.text;
                            textEditingController.selection = _tableNumberController.selection;
                            textEditingController.addListener(() {
                              _tableNumberController.value = textEditingController.value;
                            });
                          }
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            onSubmitted: (_) => onFieldSubmitted(),
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
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          final optionList = options.toList();
                          if (optionList.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 240, minWidth: 200),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: optionList.length,
                                  shrinkWrap: true,
                                  itemBuilder: (context, index) {
                                    final table = optionList[index];
                                    return ListTile(
                                      dense: true,
                                      title: Text(table.tableNumber),
                                      subtitle: Text(table.status),
                                      onTap: () => onSelected(table),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
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
            ], // end if (!_isDeliveryOrder)

            // ─── 배달 정보 입력 (phoneDelivery, platformDelivery만 표시, BillRequestScreen 제외) ────
            if (widget.billTotal == null && _isDeliveryOrder) ...[
              DeliveryInfoSection(
                customerNameController: _customerNameController,
                deliveryPhoneController: _deliveryPhoneController,
                deliveryAddressController: _deliveryAddressController,
              ),
              const SizedBox(height: 20),
            ],

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
              // 빠른 금액 버튼 (클릭 시 누적 합산, 4종: 10k/50k/100k/500k)
              Row(
                children: [10000, 50000, 100000, 500000].map((amount) {
                  final isLast = amount == 500000;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: isLast ? 0 : 6),
                      child: OutlinedButton(
                        onPressed: () {
                          // 누적: 기존 금액에 더함
                          final newAmount = _cashInput + amount;
                          setState(() => _cashInput = newAmount);
                          _cashController.text = priceFormatter.format(newAmount, includeSymbol: false);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          side: const BorderSide(color: AppTheme.divider),
                          foregroundColor: AppTheme.textPrimary,
                        ),
                        child: Text(
                          // 짧게 표시: 10K / 50K / 100K / 500K
                          amount >= 1000 ? '${(amount ~/ 1000)}K' : '$amount',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // 현금 금액 입력 (숫자 패드 강제 표시)
              TextField(
                controller: _cashController,
                keyboardType: TextInputType.number,
                // POS 특성상 숫자 패드만 표시
                inputFormatters: [],
                decoration: InputDecoration(
                  prefixText: priceFormatter.currency.symbol,
                  prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primary),
                  hintText: l10n.enterAmount,
                  suffixIcon: _cashInput > 0
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() => _cashInput = 0);
                            _cashController.clear();
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  final cleaned = value.replaceAll(',', '').replaceAll('.', '');
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
                      priceFormatter.format(change.abs()),
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
                onPressed: (!isCashValid || _isProcessing) ? null : () async {
                  // Validate delivery information if it's a delivery order
                  if (_isDeliveryOrder) {
                    final validationError = DeliveryInfoSection.validate(
                      context,
                      _customerNameController.text,
                      _deliveryPhoneController.text,
                      _deliveryAddressController.text,
                    );
                    
                    if (validationError != null) {
                      SnackBarHelper.showError(context, validationError);
                      return;
                    }
                  }
                  
                  await _processPayment(subtotal, allDiscount, total);
                },
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
        ), // SingleChildScrollView
      ), // ConstrainedBox
    );
  }

  /// KDS 상태 체크 (Open Tab 체크아웃 시)
  Future<bool> _checkKitchenApproval(int? saleId) async {
    if (saleId == null) return true; // 신규 주문은 체크 스킵
    
    final db = ref.read(databaseProvider);
    
    // 1. Settings에서 "require_kitchen_approval" 확인
    final requireApprovalResult = await db.customSelect(
      "SELECT value FROM system_settings WHERE key = 'require_kitchen_approval'"
    ).getSingleOrNull();
    
    final requireApproval = requireApprovalResult?.data['value'] == 'true';
    
    if (!requireApproval) return true; // 설정 OFF면 바로 허용
    
    // 2. 해당 Sale의 KitchenOrder 상태 조회
    final kitchenOrderResult = await db.customSelect(
      "SELECT status FROM kitchen_orders WHERE sale_id = ?",
      variables: [Variable.withInt(saleId)]
    ).getSingleOrNull();
    
    if (kitchenOrderResult == null) return true; // KitchenOrder 없으면 허용
    
    final status = kitchenOrderResult.data['status'] as String?;
    
    // 3. READY 또는 SERVED 상태면 허용
    if (status == 'READY' || status == 'SERVED') {
      return true;
    }
    
    // 4. PENDING 또는 PREPARING이면 경고 모달 표시
    if (!mounted) return false;
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Kitchen Not Ready'),
          ],
        ),
        content: Text(
          'This order is still being prepared in the kitchen (Status: ${status ?? 'UNKNOWN'}).' + '\n\n' +
          'Are you sure you want to proceed with checkout?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'Force Checkout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    
    // 5. 강제 체크아웃 시 로깅
    if (confirmed == true) {
      final currentEmployee = ref.read(currentEmployeeProvider);
      await db.customStatement('''
        INSERT INTO permission_logs (employee_id, action_type, action_target, permission_granted, metadata)
        VALUES (?, 'FORCE_CHECKOUT', ?, 1, ?)
      ''', [
        currentEmployee?.id ?? 0,
        'sale_$saleId',
        'Kitchen status: ${status ?? 'UNKNOWN'}',
      ]);
    }
    
    return confirmed ?? false;
  }

  Future<void> _processPayment(double subtotal, double discountAmount, double total) async {
    final l10n = AppLocalizations.of(context)!;
    
    // ────────────────────────────────────────────────────────
    // 🔥 NEW: KDS 상태 체크 (Open Tab 체크아웃 시)
    // ────────────────────────────────────────────────────────
    final approved = await _checkKitchenApproval(widget.saleId);
    if (!approved) return; // 사용자가 취소하면 체크아웃 중단

    // ── 빈 카트 가드: saleId 없이 cart도 비어있으면 결제 차단 ──
    final cart = ref.read(cartProvider);
    if (cart.isEmpty && widget.saleId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cartEmpty),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final cart = ref.read(cartProvider);

      // B-102: cart 전체 아이템 재고 일괄 검증
      if (cart.isNotEmpty) {
        final productsDao = ref.read(productsDaoProvider);
        final List<String> insufficientItems = [];

        for (final cartItem in cart) {
          final product = await productsDao.getProductById(cartItem.product.id);
          // B-102: stock >= 0이면 재고 추적 대상으로 간주
          if (product != null &&
              product.stock >= 0 &&
              product.stock < cartItem.quantity) {
            insufficientItems.add(
              '${product.name} (stock: ${product.stock}, ordered: ${cartItem.quantity})',
            );
          }
        }

        if (insufficientItems.isNotEmpty) {
          setState(() => _isProcessing = false);
          if (mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Insufficient Stock'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('The following items have insufficient stock:'),
                    const SizedBox(height: 8),
                    ...insufficientItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $item',
                            style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }

      final dao = ref.read(salesDaoProvider);
      final db = ref.read(databaseProvider);
      final currentEmployee = ref.read(currentEmployeeProvider);
      final selectedCustomer = ref.read(selectedCustomerProvider);
      final pointsToUse = ref.read(pointsToUseProvider);


      // 현재 로그인한 직원이 없으면 에러
      if (currentEmployee == null) {
        throw Exception(l10n.noEmployeeLoggedIn);
      }

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

      // ── Sale 처리: 기존 Open Tab 완료 OR 신규 Sale 생성 ──────────
      late Sale createdSale;
      late List<SaleItem> savedItems;

      await db.transaction(() async {
      if (widget.saleId != null) {
        // ─── Bill checkout: 기존 Open Tab Sale을 completed로 마킹 ───
        await (db.update(db.sales)..where((s) => s.id.equals(widget.saleId!)))
            .write(SalesCompanion(
          status: const Value('completed'),
          paymentMethod: Value(_selectedMethod.name.toUpperCase()),
          total: Value(finalTotal),
        ));
        createdSale = await dao.getSaleById(widget.saleId!);
        debugPrint('[Payment] Bill checkout: Sale ${widget.saleId} marked completed, table ${widget.tableId} will be reset');
      } else {
        // ─── 신규 Sale 생성 (장바구니 기반) ───────────────────────
        // 매출 번호 생성 (SO-YYYYMMDD-XXXXX)
        final now = DateTime.now();
        final dateStr = '${now.year}'
            '${now.month.toString().padLeft(2, '0')}'
            '${now.day.toString().padLeft(2, '0')}';
        final seqStr = (Random.secure().nextInt(900000) + 100000).toString();

        final saleCompanion = SalesCompanion.insert(
          saleNumber: 'SO-$dateStr-$seqStr',
          paymentMethod: _selectedMethod.name.toUpperCase(),
          subtotal: Value(subtotal),
          discount: Value(discountAmount),
          total: Value(finalTotal),
          tax: Value(ref.read(cartTaxAmountProvider)),
          customerId: Value(selectedCustomer?.id),
          employeeId: Value(currentEmployee.id),
          customerName: _isDeliveryOrder && _customerNameController.text.trim().isNotEmpty
              ? Value(_customerNameController.text.trim())
              : const Value.absent(),
          deliveryPhone: _isDeliveryOrder && _deliveryPhoneController.text.trim().isNotEmpty
              ? Value(_deliveryPhoneController.text.trim())
              : const Value.absent(),
          deliveryAddress: _isDeliveryOrder && _deliveryAddressController.text.trim().isNotEmpty
              ? Value(_deliveryAddressController.text.trim())
              : const Value.absent(),
          orderType: Value(_selectedOrderType.dbValue),
          needsSync: const Value(true),
        );

        final saleItemsList = cart.map((item) {
          return SaleItemsCompanion.insert(
            saleId: 0,
            productId: item.product.id,
            productName: item.product.name,
            sku: item.product.sku,
            unitPrice: item.product.price,
            quantity: item.quantity,
            total: item.subtotal,
          );
        }).toList();

        createdSale = await dao.createSale(
          sale: saleCompanion,
          items: saleItemsList,
          tableNumber: _tableNumberController.text.trim().isNotEmpty ? _tableNumberController.text.trim() : null,
          specialInstructions: _specialInstructionsController.text.trim().isNotEmpty ? _specialInstructionsController.text.trim() : null,
          createKitchenOrder: true,
        );

        // Save Sale Item Modifiers
        final saleItemsFromDb = await dao.getSaleItems(createdSale.id);
        for (int i = 0; i < cart.length; i++) {
          final cartItem = cart[i];
          if (cartItem.modifiers.isNotEmpty && i < saleItemsFromDb.length) {
            final saleItem = saleItemsFromDb[i];
            final modifierCompanions = cartItem.modifiers.map((mod) {
              return SaleItemModifiersCompanion.insert(
                saleItemId: saleItem.id,
                modifierOptionId: Value(mod.optionId),
                modifierName: mod.groupName,
                optionName: mod.optionName,
                priceAdjustment: mod.priceAdjustment,
              );
            }).toList();

            if (modifierCompanions.isNotEmpty) {
              await db.modifierDao.saveSaleItemModifiers(saleItem.id, modifierCompanions);
            }
          }
        }
      } // end of else (new sale) branch

      // ── Cash Drawer 매출 기록 (현금 결제 시) ──
      if (_selectedMethod == PaymentMethod.cash) {
        final cashDao = ref.read(cashDrawerDaoProvider);
        final currentBalance = await cashDao.getCurrentDrawerBalance();
        await cashDao.logCashDrawer(
          CashDrawerLogsCompanion.insert(
            type: 'sale',
            amount: finalTotal,
            balanceBefore: currentBalance,
            balanceAfter: currentBalance + finalTotal,
            note: Value('Sale #${createdSale.saleNumber}'),
          ),
        );
      }

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
      savedItems = await dao.getSaleItems(createdSale.id);

      // ── 배달 주문인 경우 delivery_orders 테이블에도 기록 ──────────────
      // B-UAT: 배달 주문 체크아웃 후 Delivery Orders 화면에 표시되도록 수정
      if (_isDeliveryOrder) {
        try {
          final platform = _selectedOrderType == OrderType.platformDelivery ? 'grab' : 'manual';
          final deliveryItemsJson = jsonEncode(
            savedItems.map((item) => {
              'name': item.productName,
              'quantity': item.quantity,
              'price': item.unitPrice,
              'notes': null,
            }).toList(),
          );
          // B-124: saleId 포함하여 delivery_orders 테이블에 저장
          final deliveryOrderCompanion = DeliveryOrdersCompanion.insert(
            platformOrderId: createdSale.saleNumber,
            platform: platform,
            status: const Value('PREPARING'),
            customerName: _customerNameController.text.trim().isNotEmpty
                ? _customerNameController.text.trim()
                : 'Walk-in Customer',
            customerPhone: Value(_deliveryPhoneController.text.trim().isNotEmpty
                ? _deliveryPhoneController.text.trim()
                : null),
            deliveryAddress: Value(_deliveryAddressController.text.trim().isNotEmpty
                ? _deliveryAddressController.text.trim()
                : null),
            itemsJson: deliveryItemsJson,
            totalAmount: createdSale.total,
            specialInstructions: Value(_specialInstructionsController.text.trim().isNotEmpty
                ? _specialInstructionsController.text.trim()
                : null),
            saleId: Value(createdSale.id),
          );
          await db.deliveryOrdersDao.insertOrder(deliveryOrderCompanion);
          debugPrint('[Checkout] Delivery order created for sale ${createdSale.saleNumber} (saleId=${createdSale.id})');
        } catch (e, st) {
          // 배달 주문 기록 실패해도 결제 완료 처리 계속 (에러는 로깅)
          debugPrint('[Checkout] Failed to create delivery order record: $e\n$st');
        }
      }

      // ── 테이블 상태 업데이트 (Dine-in/Open Tab 완료 시) ──────────────
      if (widget.tableId != null) {
        final tablesDao = ref.read(tablesDaoProvider);
        await tablesDao.updateTableStatus(
          tableId: widget.tableId!,
          status: 'AVAILABLE',
          currentSaleId: null,
          occupiedAt: null,
        );
        debugPrint('[Checkout] Table ${widget.tableId} reset to AVAILABLE');
      }
      }); // end transaction

      // U-23: 결제 완료 후 주방 주문 SERVED로 자동 업데이트
      try {
        final finalSaleId = widget.saleId ?? createdSale.id;
        await db.kitchenOrdersDao.serveOrdersBySaleId(finalSaleId);
      } catch (e) {
        debugPrint('[Checkout] Failed to mark kitchen orders as served: $e');
      }

      if (mounted) {
        ref.read(cartProvider.notifier).clear();
        // 할인 state 초기화
        ref.read(discountValueProvider.notifier).state = 0;
        // 프로모션 state 초기화
        ref.read(promotionProductIdProvider.notifier).state = null;
        ref.read(selectedManualPromotionProvider.notifier).state = null;
        // 고객 선택 및 포인트 사용 초기화
        ref.read(selectedCustomerProvider.notifier).state = null;
        ref.read(pointsToUseProvider.notifier).state = 0;

        // B-103: FutureProvider 계열 강제 갱신
        // (StreamProvider들은 DB 변경 감지로 자동 갱신)
        // Dashboard
        ref.invalidate(topSellingProvider);
        ref.invalidate(inventoryValueProvider);
        ref.invalidate(lowStockProvider);
        ref.invalidate(canCloseTodayProvider);
        // Daily Closing (집계 쿼리 — FutureProvider 유지)
        ref.invalidate(salesAggregationProvider);
        // Reports (FutureProvider 전체 갱신)
        ref.invalidate(reportTotalSalesProvider);
        ref.invalidate(reportOrderCountProvider);
        ref.invalidate(reportAvgOrderProvider);
        ref.invalidate(reportGrowthProvider);
        ref.invalidate(dailySalesChartProvider);
        ref.invalidate(paymentPieChartProvider);
        ref.invalidate(topProductsBarChartProvider);
        ref.invalidate(hourlySalesProvider);
        // Sales list (StreamProvider이지만 invalidate도 허용)
        ref.invalidate(salesListProvider);

        // 결제 모달 닫고 영수증 화면으로 전이
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReceiptScreen(
              saleNumber: createdSale.saleNumber,
              items: savedItems,
              subtotal: subtotal,
              discount: discountAmount,
              tax: ref.read(cartTaxAmountProvider),
              total: finalTotal,
              paymentMethod: _selectedMethod.name.toUpperCase(),
              cashPaid: _selectedMethod == PaymentMethod.cash ? _cashInput : 0,
              saleDate: createdSale.saleDate,
              orderType: _selectedOrderType.dbValue,
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


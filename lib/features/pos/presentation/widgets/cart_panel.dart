import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/currency_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auto_promotion_provider.dart';
import '../../../customers/providers/customers_provider.dart';

/// 장바구니 패널 (하단 또는 우측 사이드)
class CartPanel extends ConsumerWidget {
  /// 결제 버튼 눌릴 때 콜백
  final VoidCallback onCheckout;

  /// true: 태블릿/데스크탑에서 우측 사이드 패널로 표시
  /// false: 모바일에서 하단 패널로 표시
  final bool isSidePanel;

  const CartPanel({
    super.key,
    required this.onCheckout,
    this.isSidePanel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final isEmpty = cart.isEmpty;
    final priceFormatter = ref.watch(priceFormatterProvider);

    // ── 사이드 패널 모드 (태블릿/데스크탑) ──
    if (isSidePanel) {
      return Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardWhite,
          border: Border(left: BorderSide(color: AppTheme.divider, width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 헤더
            _buildHeader(ref, isEmpty, l10n),
            const Divider(height: 1, color: AppTheme.divider),
            // 고객 선택
            _CustomerSelection(),
            const Divider(height: 1, color: AppTheme.divider),
            // 아이템 리스트 (Expanded로 남은 공간 채움)
            Expanded(
              child: isEmpty
                  ? Center(
                      child: Text(
                        l10n.cartEmpty,
                        style: const TextStyle(color: AppTheme.textDisabled, fontSize: 14),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: cart.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: AppTheme.divider),
                      itemBuilder: (context, index) {
                        final item = cart[index];
                        return _CartItemRow(
                          item: item,
                          compact: true,
                          onIncrease: () => ref.read(cartProvider.notifier).updateQuantity(
                                item.product.id,
                                item.quantity + 1,
                              ),
                          onDecrease: () => ref.read(cartProvider.notifier).updateQuantity(
                                item.product.id,
                                item.quantity - 1,
                              ),
                          onRemove: () => ref.read(cartProvider.notifier).removeItem(item.product.id),
                        );
                      },
                    ),
            ),
            const Divider(height: 1, color: AppTheme.divider),
            // 금액 요약 + 결제 버튼
            _buildSummary(subtotal, isEmpty, l10n, priceFormatter),
          ],
        ),
      );
    }

    // ── 하단 패널 모드 (모바일) ──
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(ref, isEmpty, l10n),
          const Divider(height: 1, color: AppTheme.divider),
          // 고객 선택
          _CustomerSelection(),
          const Divider(height: 1, color: AppTheme.divider),
          // 아이템 리스트 (제한된 높이)
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                l10n.cartEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textDisabled, fontSize: 14),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: cart.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.divider),
                itemBuilder: (context, index) {
                  final item = cart[index];
                  return _CartItemRow(
                    item: item,
                    onIncrease: () => ref.read(cartProvider.notifier).updateQuantity(
                          item.product.id,
                          item.quantity + 1,
                        ),
                    onDecrease: () => ref.read(cartProvider.notifier).updateQuantity(
                          item.product.id,
                          item.quantity - 1,
                        ),
                    onRemove: () => ref.read(cartProvider.notifier).removeItem(item.product.id),
                  );
                },
              ),
            ),
          const Divider(height: 1, color: AppTheme.divider),
          _buildSummary(subtotal, isEmpty, l10n, priceFormatter),
        ],
      ),
    );
  }

  /// 장바구니 헤더 공통 빌더
  Widget _buildHeader(WidgetRef ref, bool isEmpty, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_cart_outlined, color: AppTheme.textPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.cart,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
            ],
          ),
          if (!isEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: Text(
                l10n.clearCart,
                style: const TextStyle(fontSize: 13, color: AppTheme.error),
              ),
            ),
        ],
      ),
    );
  }

  /// 금액 요약 + 할인 + 결제 버튼 공통 빌더
  Widget _buildSummary(double subtotal, bool isEmpty, AppLocalizations l10n, dynamic priceFormatter) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.subtotal, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              Text(priceFormatter.format(subtotal), style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          const _DiscountRow(),
          const SizedBox(height: 6),
          const _AutoPromotionsSection(),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppTheme.divider),
          const SizedBox(height: 8),
          const _TotalRow(),
          const SizedBox(height: 12),
          _CheckoutButton(isEmpty: isEmpty, onCheckout: onCheckout),
        ],
      ),
    );
  }
}

/// 장바구니 단일 행 (상품명, 수량 조절, 소계)
class _CartItemRow extends ConsumerWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final bool compact;

  const _CartItemRow({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceFormatter = ref.watch(priceFormatterProvider);
    // compact 모드: 사이드 패널용 2줄 레이아웃
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1행: 삭제 + 상품명
            Row(
              children: [
                InkWell(
                  onTap: onRemove,
                  child: const Icon(Icons.close, size: 14, color: AppTheme.textDisabled),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.product.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 2행: 수량 조절 + 소계
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _QuantitySelector(
                  quantity: item.quantity,
                  onIncrease: onIncrease,
                  onDecrease: onDecrease,
                  small: true,
                ),
                Text(
                  priceFormatter.format(item.subtotal),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 기본 모드: 하단 패널용 1줄 레이아웃
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 삭제 버튼
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 16, color: AppTheme.textDisabled),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          // 상품명
          Expanded(
            child: Text(
              item.product.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // 수량 조절 버튼
          _QuantitySelector(
            quantity: item.quantity,
            onIncrease: onIncrease,
            onDecrease: onDecrease,
          ),
          const SizedBox(width: 12),
          // 소계
          SizedBox(
            width: 72,
            child: Text(
              priceFormatter.format(item.subtotal),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// 수량 + / - 셀렉터
class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final bool small;

  const _QuantitySelector({
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final btnSize = small ? 24.0 : 28.0;
    final iconSize = small ? 14.0 : 16.0;
    final qtyWidth = small ? 28.0 : 32.0;
    final fontSize = small ? 13.0 : 15.0;

    return Row(
      children: [
        // - 버튼
        InkWell(
          onTap: onDecrease,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: btnSize,
            height: btnSize,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Icon(Icons.remove, size: iconSize, color: AppTheme.textSecondary),
          ),
        ),
        // 수량
        SizedBox(
          width: qtyWidth,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
        ),
        // + 버튼
        InkWell(
          onTap: onIncrease,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: btnSize,
            height: btnSize,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.add, size: iconSize, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ── 할인 행 ──────────────────────────────────────
class _DiscountRow extends ConsumerWidget {
  const _DiscountRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final allDiscount = ref.watch(cartAllDiscountProvider);
    final discountValue = ref.watch(discountValueProvider);
    final promoProductId = ref.watch(promotionProductIdProvider);
    final hasAny = discountValue > 0 || promoProductId != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(l10n.discount, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(width: 8),
            // 할인 버튼
            InkWell(
              onTap: () => _showDiscountModal(context, ref),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hasAny ? const Color(0xFFE8F0FE) : AppTheme.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: hasAny ? AppTheme.primary : AppTheme.divider),
                ),
                child: Row(
                  children: [
                    Icon(hasAny ? Icons.edit : Icons.add, size: 14, color: AppTheme.primary),
                    const SizedBox(width: 3),
                    Text(
                      hasAny ? l10n.edit : l10n.add,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
            ),
            // 할인/프로모션 중일 때 삭제 버튼
            if (hasAny) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: () {
                  ref.read(discountValueProvider.notifier).state = 0;
                  ref.read(promotionProductIdProvider.notifier).state = null;
                },
                borderRadius: BorderRadius.circular(4),
                child: const Icon(Icons.close, size: 14, color: AppTheme.textDisabled),
              ),
            ],
          ],
        ),
        // 할인금액 표시
        Text(
          hasAny ? '-\${priceFormatter.format(allDiscount)}' : '₩0',
          style: TextStyle(
            fontSize: 14,
            fontWeight: hasAny ? FontWeight.w600 : FontWeight.w400,
            color: hasAny ? AppTheme.error : AppTheme.textDisabled,
          ),
        ),
      ],
    );
  }

  void _showDiscountModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DiscountModal(),
    );
  }
}

// ── 합계 행 ──────────────────────────────────────
class _TotalRow extends ConsumerWidget {
  const _TotalRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final total = ref.watch(cartTotalProvider);
    final priceFormatter = ref.watch(priceFormatterProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l10n.total, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        Text(priceFormatter.format(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
      ],
    );
  }
}

// ── 결제 버튼 ────────────────────────────────────
class _CheckoutButton extends ConsumerWidget {
  final bool isEmpty;
  final VoidCallback onCheckout;

  const _CheckoutButton({required this.isEmpty, required this.onCheckout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final total = ref.watch(cartTotalProvider);

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isEmpty ? null : onCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEmpty ? AppTheme.textDisabled : AppTheme.success,
          disabledBackgroundColor: AppTheme.textDisabled,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(
          isEmpty ? l10n.addProductsPlease : '${l10n.checkout} ₩${_formatPrice(total)}',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── 할인 모달 ────────────────────────────────────
class _DiscountModal extends ConsumerStatefulWidget {
  const _DiscountModal();

  @override
  ConsumerState<_DiscountModal> createState() => _DiscountModalState();
}

class _DiscountModalState extends ConsumerState<_DiscountModal> with SingleTickerProviderStateMixin {
  late final TextEditingController _ctrl;
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: ref.read(discountValueProvider) > 0
          ? '${ref.read(discountValueProvider).toInt()}'
          : '',
    );
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtotal = ref.watch(cartSubtotalProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.discountSettings, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 22, color: AppTheme.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 탭 바 (할인 / 프로모션)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: l10n.discount),
                  Tab(text: l10n.promotion),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 탭 내용
            Flexible(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _DiscountTab(ctrl: _ctrl, subtotal: subtotal),
                  _PromotionTab(subtotal: subtotal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ── 할인 탭 ─────────────────────────────────────
class _DiscountTab extends ConsumerStatefulWidget {
  final TextEditingController ctrl;
  final double subtotal;

  const _DiscountTab({required this.ctrl, required this.subtotal});

  @override
  ConsumerState<_DiscountTab> createState() => _DiscountTabState();
}

class _DiscountTabState extends ConsumerState<_DiscountTab> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = ref.watch(discountTypeProvider);
    final inputVal = double.tryParse(widget.ctrl.text) ?? 0;
    final priceFormatter = ref.watch(priceFormatterProvider);

    // 미리 보는 할인금액
    final previewDiscount = switch (type) {
      DiscountType.percent => (widget.subtotal * (inputVal / 100)).clamp(0.0, widget.subtotal),
      DiscountType.won => inputVal.clamp(0.0, widget.subtotal),
    };
    final previewTotal = widget.subtotal - previewDiscount;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 타입 토글 (퍼센트 / 금액)
          Row(
            children: [
              Expanded(child: _typeButton(DiscountType.percent, '%', type)),
              const SizedBox(width: 8),
              Expanded(child: _typeButton(DiscountType.won, '원', type)),
            ],
          ),
          const SizedBox(height: 14),

          // 할인값 입력
          TextField(
            controller: widget.ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              suffixText: type == DiscountType.percent ? '%' : '원',
              suffixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primary),
              hintText: type == DiscountType.percent ? '예: 10' : '예: 5000',
            ),
          ),

          // 빠른 퍼센트 버튼 (퍼센트 모드일 때만)
          if (type == DiscountType.percent) ...[
            const SizedBox(height: 10),
            Row(
              children: [5, 10, 15, 20].map((v) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: v == 20 ? 0 : 6),
                    child: OutlinedButton(
                      onPressed: () {
                        widget.ctrl.text = '$v';
                        setState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: AppTheme.divider),
                        foregroundColor: AppTheme.textPrimary,
                      ),
                      child: Text('$v%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 14),

          // 미리보기 카드
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.subtotal, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    Text(priceFormatter.format(widget.subtotal), style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.discount, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    Text('-\${priceFormatter.format(previewDiscount)}', style: const TextStyle(fontSize: 13, color: AppTheme.error)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.paymentAmount, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    Text(priceFormatter.format(previewTotal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 적용 버튼
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                ref.read(discountValueProvider.notifier).state = inputVal;
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(l10n.apply, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeButton(DiscountType t, String label, DiscountType current) {
    final isActive = current == t;
    return InkWell(
      onTap: () {
        ref.read(discountTypeProvider.notifier).state = t;
        widget.ctrl.clear();
        setState(() {});
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : AppTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? AppTheme.primary : AppTheme.divider),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : AppTheme.textPrimary,
          )),
        ),
      ),
    );
  }
}

// ── 프로모션 탭 ───────────────────────────────────
class _PromotionTab extends ConsumerWidget {
  final double subtotal;

  const _PromotionTab({required this.subtotal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceFormatter = ref.watch(priceFormatterProvider);
    final l10n = AppLocalizations.of(context)!;
    final cart = ref.watch(cartProvider);
    final promoProductId = ref.watch(promotionProductIdProvider);
    final promoType = ref.watch(promotionTypeProvider);
    final promoDiscount = ref.watch(promotionDiscountProvider);
    final total = subtotal - promoDiscount;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 프로모션 타입 선택
          Row(
            children: PromotionType.values.map((t) {
              final isActive = promoType == t;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: t == PromotionType.buy2get1 ? 0 : 8),
                  child: InkWell(
                    onTap: () => ref.read(promotionTypeProvider.notifier).state = t,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.primary : AppTheme.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isActive ? AppTheme.primary : AppTheme.divider),
                      ),
                      child: Center(
                        child: Text(
                          t.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isActive ? Colors.white : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            promoType.description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),

          // 상품 선택
          Text(l10n.appliedProducts, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          ...cart.map((item) {
            final isSelected = promoProductId == item.product.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () {
                  ref.read(promotionProductIdProvider.notifier).state =
                      isSelected ? null : item.product.id;
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE8F0FE) : AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        size: 20,
                        color: isSelected ? AppTheme.primary : AppTheme.textDisabled,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.product.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        l10n.itemCount(item.quantity),
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 14),

          // 미리보기 카드
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.subtotal, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    Text(priceFormatter.format(subtotal), style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.promotion, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    Text('-\${priceFormatter.format(promoDiscount)}', style: const TextStyle(fontSize: 13, color: AppTheme.error)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.paymentAmount, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    Text(priceFormatter.format(total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 적용 버튼
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: promoProductId == null ? null : () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                disabledBackgroundColor: AppTheme.textDisabled,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(l10n.apply, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 자동 프로모션 섹션 ──────────────────────────────
class _AutoPromotionsSection extends ConsumerWidget {
  const _AutoPromotionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final appliedPromos = ref.watch(appliedPromotionsListProvider);
    final autoDiscount = ref.watch(autoPromotionDiscountProvider);

    if (appliedPromos.isEmpty || autoDiscount <= 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.local_offer, size: 14, color: AppTheme.success),
            const SizedBox(width: 4),
            Text(
              l10n.autoPromotionsApplied,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.success),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...appliedPromos.map((promo) {
          return Padding(
            padding: const EdgeInsets.only(left: 18, top: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    promo.promotionName,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '-\${priceFormatter.format(promo.discountAmount)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

String _formatPrice(double price) {
  return price.toInt().toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

/// 고객 선택 위젯
class _CustomerSelection extends ConsumerWidget {
  const _CustomerSelection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCustomer = ref.watch(selectedCustomerProvider);

    return InkWell(
      onTap: () => _showCustomerSelector(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              selectedCustomer == null ? Icons.person_add_outlined : Icons.person_outlined,
              size: 20,
              color: selectedCustomer == null ? AppTheme.textSecondary : AppTheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: selectedCustomer == null
                  ? const Text(
                      'Select Customer',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedCustomer.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${selectedCustomer.points.toInt()}P available',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
            ),
            if (selectedCustomer != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => ref.read(selectedCustomerProvider.notifier).state = null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              const Icon(Icons.chevron_right, size: 20, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

void _showCustomerSelector(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => const _CustomerSelectorDialog(),
  );
}

/// 고객 선택 다이얼로그
class _CustomerSelectorDialog extends ConsumerStatefulWidget {
  const _CustomerSelectorDialog();

  @override
  _CustomerSelectorDialogState createState() => _CustomerSelectorDialogState();
}

class _CustomerSelectorDialogState extends ConsumerState<_CustomerSelectorDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final dao = ref.watch(customersDaoProvider);

    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Customer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 검색
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name, phone, email...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            // 고객 리스트
            Expanded(
              child: FutureBuilder<List<Customer>>(
                future: _searchQuery.isEmpty
                    ? dao.getAllCustomers()
                    : dao.searchCustomers(_searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final customers = snapshot.data ?? [];

                  if (customers.isEmpty) {
                    return const Center(
                      child: Text(
                        'No customers found',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: customers.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: Text(
                            customer.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(customer.name),
                        subtitle: Text('${customer.phone} • ${customer.points.toInt()}P'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ref.read(selectedCustomerProvider.notifier).state = customer;
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

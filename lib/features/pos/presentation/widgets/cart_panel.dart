import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auto_promotion_provider.dart';

/// 장바구니 패널 (하단 또는 우측 사이드)
class CartPanel extends ConsumerWidget {
  /// 결제 버튼 눌릴 때 콜백
  final VoidCallback onCheckout;

  const CartPanel({
    super.key,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final isEmpty = cart.isEmpty;

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
          // ─── 장바구니 헤더 ─────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: AppTheme.textPrimary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '장바구니',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                if (!isEmpty)
                  TextButton(
                    onPressed: () => ref.read(cartProvider.notifier).clear(),
                    child: const Text(
                      '초기화',
                      style: TextStyle(fontSize: 13, color: AppTheme.error),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.divider),

          // ─── 장바구니 아이템 리스트 ─────────────
          if (isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                '장바구니가 비어있습니다',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textDisabled, fontSize: 14),
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

          // ─── 금액 요약 + 할인 + 결제 버튼 ────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 소계 행
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('소계', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                    Text('₩${_formatPrice(subtotal)}', style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                  ],
                ),

                // 할인 행 + 버튼
                const SizedBox(height: 6),
                _DiscountRow(),

                // 자동 적용된 프로모션 표시
                const SizedBox(height: 6),
                _AutoPromotionsSection(),

                const SizedBox(height: 8),
                const Divider(height: 1, color: AppTheme.divider),
                const SizedBox(height: 8),

                // 합계 행
                _TotalRow(),

                const SizedBox(height: 12),
                // 결제 버튼
                _CheckoutButton(isEmpty: isEmpty, onCheckout: onCheckout),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 장바구니 단일 행 (상품명, 수량 조절, 소계)
class _CartItemRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const _CartItemRow({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
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
              '₩${_formatPrice(item.subtotal)}',
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

  const _QuantitySelector({
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // - 버튼
        InkWell(
          onTap: onDecrease,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.divider),
            ),
            child: const Icon(Icons.remove, size: 16, color: AppTheme.textSecondary),
          ),
        ),
        // 수량
        SizedBox(
          width: 32,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
        ),
        // + 버튼
        InkWell(
          onTap: onIncrease,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.add, size: 16, color: Colors.white),
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
    final allDiscount = ref.watch(cartAllDiscountProvider);
    final discountValue = ref.watch(discountValueProvider);
    final promoProductId = ref.watch(promotionProductIdProvider);
    final hasAny = discountValue > 0 || promoProductId != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text('할인', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
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
                      hasAny ? '수정' : '추가',
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
          hasAny ? '-₩${_formatPrice(allDiscount)}' : '₩0',
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
    final total = ref.watch(cartTotalProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('합계', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        Text('₩${_formatPrice(total)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
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
          isEmpty ? '상품을 추가해주세요' : '결제 ₩${_formatPrice(total)}',
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
                const Text('할인 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
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
                tabs: const [
                  Tab(text: '할인'),
                  Tab(text: '프로모션'),
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
    final type = ref.watch(discountTypeProvider);
    final inputVal = double.tryParse(widget.ctrl.text) ?? 0;

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
                    const Text('소계', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    Text('₩${_formatPrice(widget.subtotal)}', style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('할인', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    Text('-₩${_formatPrice(previewDiscount)}', style: const TextStyle(fontSize: 13, color: AppTheme.error)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('결제금액', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    Text('₩${_formatPrice(previewTotal)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary)),
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
              child: const Text('적용', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
          const Text('적용 상품 선택', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
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
                        '${item.quantity}개',
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
                    const Text('소계', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    Text('₩${_formatPrice(subtotal)}', style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('프로모션', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    Text('-₩${_formatPrice(promoDiscount)}', style: const TextStyle(fontSize: 13, color: AppTheme.error)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('결제금액', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    Text('₩${_formatPrice(total)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary)),
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
              child: const Text('적용', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
            const Text(
              '자동 적용된 프로모션',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.success),
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
                  '-₩${_formatPrice(promo.discountAmount)}',
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tax_provider.dart';

import '../../../database/app_database.dart';
import 'auto_promotion_provider.dart';

/// 장바구니 아이템 모델
class CartItem {
  final Product product;
  int quantity;
  final List<SelectedModifier> modifiers; // New field

  CartItem({
    required this.product,
    this.quantity = 1,
    this.modifiers = const [],
  });

  double get subtotal {
    final modifierTotal = modifiers.fold(0.0, (sum, m) => sum + m.priceAdjustment);
    return (product.price + modifierTotal) * quantity;
  }

  double get basePrice => product.price;
  double get modifierPrice => modifiers.fold(0.0, (sum, m) => sum + m.priceAdjustment);
  double get pricePerItem => basePrice + modifierPrice;

  /// Check if two cart items are identical (same product + same modifiers)
  bool isSameAs(Product p, List<SelectedModifier> mods) {
    if (product.id != p.id) return false;
    if (modifiers.length != mods.length) return false;
    
    // Sort both lists by option ID for comparison
    final sortedA = [...modifiers]..sort((a, b) => a.optionId.compareTo(b.optionId));
    final sortedB = [...mods]..sort((a, b) => a.optionId.compareTo(b.optionId));
    
    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i].optionId != sortedB[i].optionId) return false;
    }
    
    return true;
  }
}

/// Selected modifier option (for cart item)
class SelectedModifier {
  final int optionId;
  final int groupId;
  final String groupName;
  final String optionName;
  final double priceAdjustment;

  const SelectedModifier({
    required this.optionId,
    required this.groupId,
    required this.groupName,
    required this.optionName,
    required this.priceAdjustment,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectedModifier &&
          runtimeType == other.runtimeType &&
          optionId == other.optionId;

  @override
  int get hashCode => optionId.hashCode;
}

/// 장바구니 상태 관리 (Riverpod Notifier)
class CartState extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  /// 상품 추가 (modifier 포함, 같은 상품+modifier 조합이면 수량 증가)
  void addItem(Product product, {List<SelectedModifier> modifiers = const []}) {
    final existing = state.indexWhere((item) => item.isSameAs(product, modifiers));
    if (existing >= 0) {
      final updated = [...state];
      updated[existing].quantity++;
      state = updated;
    } else {
      state = [...state, CartItem(product: product, modifiers: modifiers)];
    }
  }

  /// 특정 인덱스의 아이템 제거
  void removeItemAt(int index) {
    if (index < 0 || index >= state.length) return;
    final updated = [...state];
    updated.removeAt(index);
    state = updated;
  }

  /// 상품 제거 (deprecated - use removeItemAt for modifier support)
  @Deprecated('Use removeItemAt(index) instead')
  void removeItem(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  /// 특정 인덱스의 수량 변경
  void updateQuantityAt(int index, int quantity) {
    if (index < 0 || index >= state.length) return;
    if (quantity <= 0) {
      removeItemAt(index);
      return;
    }
    final updated = [...state];
    updated[index].quantity = quantity;
    state = updated;
  }

  /// 수량 변경 (deprecated - use updateQuantityAt for modifier support)
  @Deprecated('Use updateQuantityAt(index, quantity) instead')
  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final idx = state.indexWhere((item) => item.product.id == productId);
    if (idx >= 0) {
      final updated = [...state];
      updated[idx].quantity = quantity;
      state = updated;
    }
  }

  /// 장바구니 초기화
  void clear() {
    state = [];
  }

  /// 소계
  double get subtotal {
    return state.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  /// 아이템 수
  int get itemCount {
    return state.fold(0, (sum, item) => sum + item.quantity);
  }
}

final cartProvider = NotifierProvider<CartState, List<CartItem>>(CartState.new);

/// 소계 전용 Provider
final cartSubtotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.subtotal);
});

/// 아이템 수 전용 Provider
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

// ── 프로모션 관련 Provider ───────────────────────

/// 프로모션 타입 (B1G1/B2G1 하드코딩 방식 — 레거시 호환)
enum PromotionType {
  buy1get1('B1G1', 'Buy 1 Get 1 Free'),
  buy2get1('B2G1', 'Buy 2 Get 1 Free');

  final String label;
  final String description;
  const PromotionType(this.label, this.description);
}

/// 프로모션 적용 상품 ID (null이면 프로모션 없음)
final promotionProductIdProvider = StateProvider<int?>((ref) => null);

/// 프로모션 타입 (기본값 B1G1) — 레거시
final promotionTypeProvider = StateProvider<PromotionType>((ref) => PromotionType.buy1get1);

// B-113: DB에서 선택된 프로모션 (Promotion 객체, null이면 미선택)
final selectedDbPromotionProvider = StateProvider<dynamic>((ref) => null);

/// 프로모션으로 인한 할인금액 계산
/// B-113: DB 프로모션이 선택된 경우 우선 적용
final promotionDiscountProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  final promoProductId = ref.watch(promotionProductIdProvider);
  final selectedPromotion = ref.watch(selectedDbPromotionProvider);

  // B-113: DB 프로모션 선택된 경우
  if (selectedPromotion != null) {
    double totalDiscount = 0.0;
    final promo = selectedPromotion;
    for (final item in cart) {
      switch (promo.type as String) {
        case 'buy1get1':
          totalDiscount += (item.quantity ~/ 2) * item.product.price;
        case 'buy2get1':
          totalDiscount += (item.quantity ~/ 3) * item.product.price;
        case 'percentOff':
          totalDiscount += item.subtotal * ((promo.value as double) / 100);
        case 'amountOff':
          totalDiscount += (promo.value as double).clamp(0.0, item.subtotal);
      }
    }
    return totalDiscount;
  }

  // 기존 방식 (B1G1/B2G1 수동 선택)
  if (promoProductId == null) return 0.0;

  final promoType = ref.watch(promotionTypeProvider);
  final item = cart.where((i) => i.product.id == promoProductId).firstOrNull;
  if (item == null) return 0.0;

  final freeCount = switch (promoType) {
    PromotionType.buy1get1 => item.quantity ~/ 2,
    PromotionType.buy2get1 => item.quantity ~/ 3,
  };

  return freeCount * item.product.price;
});

// ── 할인 관련 Provider ─────────────────────────

/// 할인 타입: 퍼센트(%) 또는 고정금액(won)
enum DiscountType { percent, won }

/// 현재 할인 타입
final discountTypeProvider = StateProvider<DiscountType>((ref) => DiscountType.percent);

/// 현재 할인 값 (숫자만, 타입에 따라 % 또는 원)
final discountValueProvider = StateProvider<double>((ref) => 0);

/// 실제 할인금액 (계산된 값)
final cartDiscountAmountProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final type = ref.watch(discountTypeProvider);
  final value = ref.watch(discountValueProvider);

  if (value <= 0) return 0.0;

  final amount = switch (type) {
    DiscountType.percent => subtotal * (value / 100),
    DiscountType.won => value,
  };

  // 할인금액이 소계를 초과하지 않음
  return amount.clamp(0.0, subtotal);
});

/// 프로모션 + 기존 할인 합산 금액
final cartAllDiscountProvider = Provider<double>((ref) {
  final promoDiscount = ref.watch(promotionDiscountProvider);
  final manualDiscount = ref.watch(cartDiscountAmountProvider);
  final autoPromoDiscount = ref.watch(autoPromotionDiscountProvider);
  return promoDiscount + manualDiscount + autoPromoDiscount;
});

/// 최종 결제금액 (소계 - 할인 + 세금(exclusive만))
final cartTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final allDiscount = ref.watch(cartAllDiscountProvider);
  final taxAmount = ref.watch(cartTaxAmountProvider);
  final taxInclusive = ref.watch(taxInclusiveProvider);
  
  if (taxInclusive) {
    // Tax inclusive: total = subtotal - discount (tax already included)
    return (subtotal - allDiscount).clamp(0.0, subtotal);
  } else {
    // Tax exclusive: total = subtotal - discount + tax
    return (subtotal - allDiscount + taxAmount).clamp(0.0, double.infinity);
  }
});

// ── 로열티 관련 Provider ────────────────────────

// Note: selectedCustomerProvider is defined in customers_provider.dart
// Import from there to avoid duplication

/// 사용할 포인트 (결제 시)
final pointsToUseProvider = StateProvider<int>((ref) => 0);

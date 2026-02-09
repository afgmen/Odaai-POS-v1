import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import 'auto_promotion_provider.dart';

/// 장바구니 아이템 모델
class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get subtotal => product.price * quantity;
}

/// 장바구니 상태 관리 (Riverpod Notifier)
class CartState extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  /// 상품 추가 (중복 시 수량 증가)
  void addItem(Product product) {
    final existing = state.indexWhere((item) => item.product.id == product.id);
    if (existing >= 0) {
      final updated = [...state];
      updated[existing].quantity++;
      state = updated;
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  /// 상품 제거
  void removeItem(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  /// 수량 변경
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

/// 프로모션 타입
enum PromotionType {
  buy1get1('B1G1', '1개 사면 1개 무료'),
  buy2get1('B2G1', '2개 사면 1개 무료');

  final String label;
  final String description;
  const PromotionType(this.label, this.description);
}

/// 프로모션 적용 상품 ID (null이면 프로모션 없음)
final promotionProductIdProvider = StateProvider<int?>((ref) => null);

/// 프로모션 타입 (기본값 B1G1)
final promotionTypeProvider = StateProvider<PromotionType>((ref) => PromotionType.buy1get1);

/// 프로모션으로 인한 할인금액 계산
final promotionDiscountProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  final promoProductId = ref.watch(promotionProductIdProvider);
  final promoType = ref.watch(promotionTypeProvider);

  if (promoProductId == null) return 0.0;

  final item = cart.where((i) => i.product.id == promoProductId).firstOrNull;
  if (item == null) return 0.0;

  // 무료 개수 계산
  final freeCount = switch (promoType) {
    PromotionType.buy1get1 => item.quantity ~/ 2,      // 2개마다 1개 무료
    PromotionType.buy2get1 => item.quantity ~/ 3,      // 3개마다 1개 무료
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

/// 최종 결제금액 (소계 - 프로모션 - 할인)
final cartTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final allDiscount = ref.watch(cartAllDiscountProvider);
  return (subtotal - allDiscount).clamp(0.0, subtotal);
});

// ── 로열티 관련 Provider ────────────────────────

// Note: selectedCustomerProvider is defined in customers_provider.dart
// Import from there to avoid duplication

/// 사용할 포인트 (결제 시)
final pointsToUseProvider = StateProvider<int>((ref) => 0);

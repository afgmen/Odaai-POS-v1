import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';
import '../../promotions/providers/promotions_provider.dart';
import 'cart_provider.dart';

/// 장바구니 상품별 적용 가능한 프로모션 맵
/// Map<productId, List<Promotion>>
final applicablePromotionsProvider = StreamProvider<Map<int, List<Promotion>>>((ref) async* {
  final cart = ref.watch(cartProvider);
  final db = ref.watch(databaseProvider);

  if (cart.isEmpty) {
    yield {};
    return;
  }

  // 모든 장바구니 상품의 적용 가능한 프로모션 조회
  final Map<int, List<Promotion>> promoMap = {};

  for (final item in cart) {
    final productId = item.product.id;
    final now = DateTime.now();

    // 해당 상품에 적용 가능한 활성 프로모션 조회
    final promotions = await (db.select(db.promotions)
          ..where((p) =>
              p.isActive.equals(true) &
              (p.productId.isNull() | p.productId.equals(productId)) &
              (p.startDate.isNull() | p.startDate.isSmallerOrEqualValue(now)) &
              (p.endDate.isNull() | p.endDate.isBiggerOrEqualValue(now))))
        .get();

    if (promotions.isNotEmpty) {
      promoMap[productId] = promotions;
    }
  }

  yield promoMap;
});

/// 프로모션 자동 적용된 총 할인 금액
final autoPromotionDiscountProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  final promoMapAsync = ref.watch(applicablePromotionsProvider);

  return promoMapAsync.when(
    data: (promoMap) {
      double totalDiscount = 0.0;

      for (final item in cart) {
        final productId = item.product.id;
        final promotions = promoMap[productId];

        if (promotions == null || promotions.isEmpty) continue;

        // 가장 유리한 프로모션 선택 (할인 금액 기준)
        double maxDiscount = 0.0;

        for (final promo in promotions) {
          final discount = _calculatePromoDiscount(promo, item);
          if (discount > maxDiscount) {
            maxDiscount = discount;
          }
        }

        totalDiscount += maxDiscount;
      }

      return totalDiscount;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// 프로모션별 할인 금액 계산
double _calculatePromoDiscount(Promotion promo, CartItem item) {
  switch (promo.type) {
    case 'buy1get1':
      // 2개마다 1개 무료
      final freeCount = item.quantity ~/ 2;
      return freeCount * item.product.price;

    case 'buy2get1':
      // 3개마다 1개 무료
      final freeCount = item.quantity ~/ 3;
      return freeCount * item.product.price;

    case 'percentOff':
      // 퍼센트 할인
      final discountRate = promo.value / 100;
      return item.subtotal * discountRate;

    case 'amountOff':
      // 고정 금액 할인 (단, 소계를 초과하지 않음)
      return promo.value.clamp(0.0, item.subtotal);

    default:
      return 0.0;
  }
}

/// 상품별 적용된 프로모션 정보 (UI 표시용)
class AppliedPromotion {
  final int productId;
  final String promotionName;
  final double discountAmount;

  AppliedPromotion({
    required this.productId,
    required this.promotionName,
    required this.discountAmount,
  });
}

/// 적용된 프로모션 목록 Provider
final appliedPromotionsListProvider = Provider<List<AppliedPromotion>>((ref) {
  final cart = ref.watch(cartProvider);
  final promoMapAsync = ref.watch(applicablePromotionsProvider);

  return promoMapAsync.when(
    data: (promoMap) {
      final List<AppliedPromotion> applied = [];

      for (final item in cart) {
        final productId = item.product.id;
        final promotions = promoMap[productId];

        if (promotions == null || promotions.isEmpty) continue;

        // 가장 유리한 프로모션 찾기
        Promotion? bestPromo;
        double maxDiscount = 0.0;

        for (final promo in promotions) {
          final discount = _calculatePromoDiscount(promo, item);
          if (discount > maxDiscount) {
            maxDiscount = discount;
            bestPromo = promo;
          }
        }

        if (bestPromo != null && maxDiscount > 0) {
          applied.add(AppliedPromotion(
            productId: productId,
            promotionName: bestPromo.name,
            discountAmount: maxDiscount,
          ));
        }
      }

      return applied;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

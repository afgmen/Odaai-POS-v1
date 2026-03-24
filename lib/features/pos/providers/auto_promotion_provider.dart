import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';
import '../../promotions/data/promotions_dao.dart';
import 'cart_provider.dart';

/// 장바구니 상품별 적용 가능한 프로모션 맵
/// `Map<productId, List<Promotion>>`
/// B-UAT: PromotionsDao.getApplicablePromotions() 사용 (applyToAll 포함)
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
    // PromotionsDao의 getApplicablePromotions 사용 (applyToAll 포함)
    final promotions = await db.promotionsDao.getApplicablePromotions(productId);
    if (promotions.isNotEmpty) {
      promoMap[productId] = promotions;
    }
  }

  yield promoMap;
});

/// 프로모션 자동 적용된 총 할인 금액
/// B-UAT: 동일 프로모션(applyToAll)이 여러 상품에 중복 적용되지 않도록 처리
final autoPromotionDiscountProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  final promoMapAsync = ref.watch(applicablePromotionsProvider);

  return promoMapAsync.when(
    data: (promoMap) {
      double totalDiscount = 0.0;
      // applyToAll 프로모션은 cart 전체에 한 번만 적용
      final Set<int> appliedGlobalPromoIds = {};

      for (final item in cart) {
        final productId = item.product.id;
        final promotions = promoMap[productId];

        if (promotions == null || promotions.isEmpty) continue;

        // 가장 유리한 프로모션 선택 (할인 금액 기준)
        double maxDiscount = 0.0;
        Promotion? bestPromo;

        for (final promo in promotions) {
          // applyToAll 프로모션은 이미 다른 상품에서 적용됐으면 스킵
          if (promo.applyToAllProducts && appliedGlobalPromoIds.contains(promo.id)) continue;
          final discount = _calculatePromoDiscount(promo, item);
          if (discount > maxDiscount) {
            maxDiscount = discount;
            bestPromo = promo;
          }
        }

        if (bestPromo != null && maxDiscount > 0) {
          if (bestPromo.applyToAllProducts) {
            appliedGlobalPromoIds.add(bestPromo.id);
          }
          totalDiscount += maxDiscount;
        }
      }

      return totalDiscount;
    },
    loading: () => 0.0,
    error: (_, _) => 0.0,
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
/// B-UAT: applyToAll 프로모션은 합산하여 1개 항목으로 표시 (중복 제거)
final appliedPromotionsListProvider = Provider<List<AppliedPromotion>>((ref) {
  final cart = ref.watch(cartProvider);
  final promoMapAsync = ref.watch(applicablePromotionsProvider);

  return promoMapAsync.when(
    data: (promoMap) {
      final List<AppliedPromotion> applied = [];
      // applyToAll 프로모션 집계 (promotionId → 할인 합산)
      final Map<int, ({String name, double discount})> globalPromoAggregated = {};
      // applyToAll 프로모션 중 이미 처리된 ID 추적
      final Set<int> appliedGlobalPromoIds = {};

      for (final item in cart) {
        final productId = item.product.id;
        final promotions = promoMap[productId];

        if (promotions == null || promotions.isEmpty) continue;

        // 가장 유리한 프로모션 찾기
        Promotion? bestPromo;
        double maxDiscount = 0.0;

        for (final promo in promotions) {
          // applyToAll 프로모션은 이미 다른 상품에서 선택됐으면 스킵
          if (promo.applyToAllProducts && appliedGlobalPromoIds.contains(promo.id)) continue;
          final discount = _calculatePromoDiscount(promo, item);
          if (discount > maxDiscount) {
            maxDiscount = discount;
            bestPromo = promo;
          }
        }

        if (bestPromo != null && maxDiscount > 0) {
          if (bestPromo.applyToAllProducts) {
            // applyToAll 프로모션은 집계 맵에 추가 (나중에 단일 항목으로 표시)
            appliedGlobalPromoIds.add(bestPromo.id);
            final existing = globalPromoAggregated[bestPromo.id];
            if (existing != null) {
              globalPromoAggregated[bestPromo.id] = (
                name: existing.name,
                discount: existing.discount + maxDiscount,
              );
            } else {
              globalPromoAggregated[bestPromo.id] = (
                name: bestPromo.name,
                discount: maxDiscount,
              );
            }
          } else {
            // 특정 상품 전용 프로모션은 개별 항목으로 표시
            applied.add(AppliedPromotion(
              productId: productId,
              promotionName: bestPromo.name,
              discountAmount: maxDiscount,
            ));
          }
        }
      }

      // applyToAll 프로모션들을 합산하여 단일 항목으로 추가
      for (final entry in globalPromoAggregated.entries) {
        applied.add(AppliedPromotion(
          productId: -1, // 전체 상품 대상은 productId -1 사용
          promotionName: entry.value.name,
          discountAmount: entry.value.discount,
        ));
      }

      return applied;
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

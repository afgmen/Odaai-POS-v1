import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/promotions.dart';
import '../../../database/tables/promotion_products.dart';
import '../../../database/tables/products.dart';

part 'promotions_dao.g.dart';

/// 프로모션 데이터 액세스 객체 (B-082)
@DriftAccessor(tables: [Promotions, PromotionProducts, Products])
class PromotionsDao extends DatabaseAccessor<AppDatabase> with _$PromotionsDaoMixin {
  PromotionsDao(AppDatabase db) : super(db);

  /// 활성화된 모든 프로모션 조회
  Future<List<Promotion>> getActivePromotions() {
    return (select(promotions)..where((p) => p.isActive.equals(true))).get();
  }

  /// 특정 프로모션에 연결된 제품 목록 조회
  Future<List<Product>> getPromotionProducts(int promotionId) async {
    final query = select(products).join([
      innerJoin(
        promotionProducts,
        promotionProducts.productId.equalsExp(products.id),
      ),
    ])
      ..where(promotionProducts.promotionId.equals(promotionId));

    final results = await query.get();
    return results.map((row) => row.readTable(products)).toList();
  }

  /// 프로모션에 제품 추가 (다중)
  Future<void> addProductsToPromotion(int promotionId, List<int> productIds) async {
    await batch((batch) {
      batch.insertAll(
        promotionProducts,
        productIds.map((productId) => PromotionProductsCompanion.insert(
          promotionId: promotionId,
          productId: productId,
        )),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  /// 프로모션에서 제품 제거 (다중)
  Future<void> removeProductsFromPromotion(int promotionId, List<int> productIds) async {
    await (delete(promotionProducts)
      ..where((pp) => 
        pp.promotionId.equals(promotionId) & 
        pp.productId.isIn(productIds)
      )
    ).go();
  }

  /// 프로모션의 모든 제품 연결 제거
  Future<void> clearPromotionProducts(int promotionId) async {
    await (delete(promotionProducts)
      ..where((pp) => pp.promotionId.equals(promotionId))
    ).go();
  }

  /// 프로모션 생성 + 제품 연결
  Future<int> createPromotionWithProducts({
    required PromotionsCompanion promotion,
    required bool applyToAll,
    List<int> productIds = const [],
  }) async {
    return await transaction(() async {
      // 1. 프로모션 생성
      final promotionId = await into(promotions).insert(promotion);

      // 2. 제품 연결 (applyToAll이 false일 때만)
      if (!applyToAll && productIds.isNotEmpty) {
        await addProductsToPromotion(promotionId, productIds);
      }

      return promotionId;
    });
  }

  /// 프로모션 수정 + 제품 연결 업데이트
  Future<void> updatePromotionWithProducts({
    required int promotionId,
    required PromotionsCompanion promotion,
    required bool applyToAll,
    List<int> productIds = const [],
  }) async {
    await transaction(() async {
      // 1. 프로모션 정보 업데이트
      await (update(promotions)..where((p) => p.id.equals(promotionId)))
          .write(promotion);

      // 2. 기존 제품 연결 제거
      await clearPromotionProducts(promotionId);

      // 3. 새 제품 연결 (applyToAll이 false일 때만)
      if (!applyToAll && productIds.isNotEmpty) {
        await addProductsToPromotion(promotionId, productIds);
      }
    });
  }

  /// 특정 제품에 적용 가능한 프로모션 조회 (B-082)
  Future<List<Promotion>> getApplicablePromotions(int productId) async {
    final now = DateTime.now();

    // 1. 모든 제품에 적용되는 프로모션
    final allProductsQuery = select(promotions)
      ..where((p) =>
        p.isActive.equals(true) &
        p.applyToAllProducts.equals(true) &
        (p.startDate.isNull() | p.startDate.isSmallerOrEqualValue(now)) &
        (p.endDate.isNull() | p.endDate.isBiggerOrEqualValue(now))
      );

    // 2. 특정 제품에만 적용되는 프로모션
    final specificQuery = select(promotions).join([
      innerJoin(
        promotionProducts,
        promotionProducts.promotionId.equalsExp(promotions.id),
      ),
    ])
      ..where(
        promotions.isActive.equals(true) &
        promotions.applyToAllProducts.equals(false) &
        promotionProducts.productId.equals(productId) &
        (promotions.startDate.isNull() | promotions.startDate.isSmallerOrEqualValue(now)) &
        (promotions.endDate.isNull() | promotions.endDate.isBiggerOrEqualValue(now))
      );

    final allResults = await allProductsQuery.get();
    final specificResults = await specificQuery.get();
    final specificPromotions = specificResults.map((row) => row.readTable(promotions)).toList();

    // 중복 제거 후 반환
    final allIds = allResults.map((p) => p.id).toSet();
    final specificFiltered = specificPromotions.where((p) => !allIds.contains(p.id)).toList();

    return [...allResults, ...specificFiltered];
  }

  /// 프로모션 삭제
  Future<void> deletePromotion(int promotionId) async {
    await transaction(() async {
      // 1. 제품 연결 삭제 (cascade delete로 자동 처리되지만 명시적으로)
      await clearPromotionProducts(promotionId);
      
      // 2. 프로모션 삭제
      await (delete(promotions)..where((p) => p.id.equals(promotionId))).go();
    });
  }
}

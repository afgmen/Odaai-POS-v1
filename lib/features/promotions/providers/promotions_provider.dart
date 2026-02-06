import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';

/// 활성 프로모션 목록 Provider
final activePromotionsProvider = StreamProvider<List<Promotion>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.promotions)
        ..where((p) => p.isActive.equals(true))
        ..orderBy([(p) => OrderingTerm.asc(p.name)]))
      .watch();
});

/// 모든 프로모션 목록 Provider
final allPromotionsProvider = StreamProvider<List<Promotion>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.promotions)..orderBy([(p) => OrderingTerm.desc(p.createdAt)])).watch();
});

/// 프로모션 서비스 (CRUD)
class PromotionService {
  final AppDatabase _db;

  PromotionService(this._db);

  /// 프로모션 생성
  Future<Promotion> createPromotion({
    required String name,
    required String type,
    required double value,
    int? productId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final id = await _db.into(_db.promotions).insert(
          PromotionsCompanion.insert(
            name: name,
            type: type,
            value: Value(value),
            productId: Value(productId),
            startDate: Value(startDate),
            endDate: Value(endDate),
          ),
        );
    return (_db.select(_db.promotions)..where((p) => p.id.equals(id))).getSingle();
  }

  /// 프로모션 수정
  Future<bool> updatePromotion(Promotion promotion) async {
    final count = await (_db.update(_db.promotions)..where((p) => p.id.equals(promotion.id))).write(
      PromotionsCompanion(
        name: Value(promotion.name),
        type: Value(promotion.type),
        value: Value(promotion.value),
        productId: Value(promotion.productId),
        startDate: Value(promotion.startDate),
        endDate: Value(promotion.endDate),
        isActive: Value(promotion.isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return count > 0;
  }

  /// 프로모션 활성/비활성 토글
  Future<bool> toggleActive(int id, bool isActive) async {
    final count = await (_db.update(_db.promotions)..where((p) => p.id.equals(id))).write(
      PromotionsCompanion(
        isActive: Value(isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return count > 0;
  }

  /// 프로모션 삭제
  Future<int> deletePromotion(int id) async {
    return await (_db.delete(_db.promotions)..where((p) => p.id.equals(id))).go();
  }

  /// 특정 상품에 적용 가능한 프로모션 조회
  Future<List<Promotion>> getApplicablePromotions(int productId) async {
    final now = DateTime.now();
    return await (_db.select(_db.promotions)
          ..where((p) =>
              p.isActive.equals(true) &
              (p.productId.isNull() | p.productId.equals(productId)) &
              (p.startDate.isNull() | p.startDate.isSmallerOrEqualValue(now)) &
              (p.endDate.isNull() | p.endDate.isBiggerOrEqualValue(now))))
        .get();
  }
}

/// 프로모션 서비스 Provider
final promotionServiceProvider = Provider<PromotionService>((ref) {
  final db = ref.watch(databaseProvider);
  return PromotionService(db);
});

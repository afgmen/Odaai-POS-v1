import 'package:drift/drift.dart';

import 'promotions.dart';
import 'products.dart';

/// 프로모션-제품 다대다 연결 테이블 (B-082)
/// 하나의 프로모션이 여러 제품에 적용될 수 있도록 지원
class PromotionProducts extends Table {
  /// 프로모션 ID (외래키)
  IntColumn get promotionId => integer().references(Promotions, #id, onDelete: KeyAction.cascade)();
  
  /// 제품 ID (외래키)
  IntColumn get productId => integer().references(Products, #id, onDelete: KeyAction.cascade)();
  
  /// 생성 시간
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// 복합 기본키 (promotionId + productId 조합이 유일해야 함)
  @override
  Set<Column> get primaryKey => {promotionId, productId};
}

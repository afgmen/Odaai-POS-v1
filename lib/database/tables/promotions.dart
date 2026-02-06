import 'package:drift/drift.dart';

import 'products.dart';

/// 프로모션 마스터 테이블
class Promotions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // 프로모션 이름 (예: "오렌지주스 1+1 이벤트")
  TextColumn get type => text()(); // 'buy1get1' | 'buy2get1' | 'percentOff' | 'amountOff'
  RealColumn get value => real().withDefault(const Constant(0))(); // 타입별 값 (10% → 10, 1000원 → 1000)
  IntColumn get productId => integer().nullable().references(Products, #id)(); // null이면 전체 상품 대상
  DateTimeColumn get startDate => dateTime().nullable()(); // 시작일 (null이면 즉시 시작)
  DateTimeColumn get endDate => dateTime().nullable()(); // 종료일 (null이면 무제한)
  BoolColumn get isActive => boolean().withDefault(const Constant(true))(); // 활성화 여부
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

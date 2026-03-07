import 'package:drift/drift.dart';

import 'products.dart';

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get saleNumber => text().unique()();
  DateTimeColumn get saleDate => dateTime().withDefault(currentDateAndTime)();
  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get tax => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get total => real().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text()(); // 'cash' | 'card' | 'qr' | 'transfer'
  TextColumn get paymentReference => text().nullable()(); // 결제 참조번호 (카드승인번호, 이체참조 등)
  IntColumn get employeeId => integer().nullable()();
  IntColumn get customerId => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('completed'))();

  // ── Phase 1: POS UX 개편 컬럼 ──
  /// 주문 유형: dineIn | takeaway | phoneDelivery | platformDelivery
  TextColumn get orderType => text().withDefault(const Constant('dineIn'))();

  /// 연결된 테이블 ID (매장 식사 시)
  IntColumn get tableId => integer().nullable()();

  /// 고객명 (배달/포장 시)
  TextColumn get customerName => text().nullable()();

  /// 배달 주소 (배달 주문 시)
  TextColumn get deliveryAddress => text().nullable()();

  /// 배달 연락처 (배달 주문 시)
  TextColumn get deliveryPhone => text().nullable()();

  /// Open Tab 여부 (매장 식사: 추가 주문 가능 상태)
  BoolColumn get isOpenTab => boolean().withDefault(const Constant(false))();

  /// 취소 사유 (취소 시)
  TextColumn get cancellationReason => text().nullable()();

  /// 취소 시각 (취소 시)
  DateTimeColumn get cancelledAt => dateTime().nullable()();

  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()();
  TextColumn get sku => text()();
  RealColumn get unitPrice => real()();
  IntColumn get quantity => integer()();
  RealColumn get total => real()();
  IntColumn get roundNumber => integer().withDefault(const Constant(1))();
}

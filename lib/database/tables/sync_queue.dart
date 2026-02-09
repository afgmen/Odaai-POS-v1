import 'package:drift/drift.dart';

/// 고객 테이블 (CRM)
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  RealColumn get balance => real().withDefault(const Constant(0))();
  IntColumn get points => integer().withDefault(const Constant(0))(); // 적립 포인트

  // 로열티 프로그램 필드 (v5)
  TextColumn get membershipTier => text().named('membership_tier').withDefault(const Constant('bronze'))(); // 'bronze', 'silver', 'gold', 'platinum'
  IntColumn get totalSpent => integer().named('total_spent').withDefault(const Constant(0))(); // 누적 구매액 (원 단위)
  DateTimeColumn get birthDate => dateTime().nullable().named('birth_date')(); // 생년월일
  DateTimeColumn get lastPurchaseAt => dateTime().nullable().named('last_purchase_at')(); // 마지막 구매 일시
  IntColumn get purchaseCount => integer().named('purchase_count').withDefault(const Constant(0))(); // 총 구매 횟수

  TextColumn get note => text().nullable()(); // 메모
  BoolColumn get isActive => boolean().named('is_active').withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(currentDateAndTime)(); // v5 추가
}

/// 동기화 큐
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // 'product' | 'sale' | 'employee'
  IntColumn get entityId => integer()();
  TextColumn get action => text()(); // 'create' | 'update' | 'delete'
  TextColumn get payload => text()(); // JSON
  TextColumn get status => text().withDefault(const Constant('pending'))(); // 'pending' | 'synced' | 'failed'
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get syncedAt => dateTime().nullable()();
}

/// 테이블/좌석 관리
class StoreTables extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // '테이블 1', 'A-1' 등
  IntColumn get seats => integer().withDefault(const Constant(4))();
  TextColumn get zone => text().nullable()(); // '홀', '테라스', '룸'
  TextColumn get status => text().withDefault(const Constant('available'))(); // 'available' | 'occupied' | 'reserved'
  IntColumn get currentSaleId => integer().nullable()();
  DateTimeColumn get occupiedAt => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 시재 관리 (Cash Drawer)
class CashDrawerLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'open' | 'close' | 'deposit' | 'withdraw' | 'sale' | 'refund'
  RealColumn get amount => real()();
  RealColumn get balanceBefore => real()();
  RealColumn get balanceAfter => real()();
  TextColumn get note => text().nullable()();
  IntColumn get employeeId => integer().nullable()();
  IntColumn get saleId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 환불 기록
class Refunds extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get originalSaleId => integer()();
  TextColumn get originalSaleNumber => text()();
  RealColumn get refundAmount => real()();
  TextColumn get reason => text().nullable()();
  TextColumn get refundType => text()(); // 'full' | 'partial'
  TextColumn get status => text().withDefault(const Constant('completed'))();
  IntColumn get employeeId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 환불 항목 (부분 환불 시)
class RefundItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get refundId => integer()();
  IntColumn get saleItemId => integer()();
  IntColumn get productId => integer()();
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
  RealColumn get total => real()();
}

import 'package:drift/drift.dart';

class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get name => text()();
  TextColumn get passwordHash => text()(); // 레거시 (사용 안 함)

  // 권한 시스템 필드 (레거시)
  TextColumn get role => text().withDefault(const Constant('CASHIER'))(); // 'MANAGER' | 'CASHIER' | 'KITCHEN'
  TextColumn get pinHash => text().nullable()(); // SHA-256 해시된 PIN
  DateTimeColumn get pinChangedAt => dateTime().nullable()(); // PIN 변경 시간
  DateTimeColumn get lastLoginAt => dateTime().nullable()(); // 최종 로그인 시간
  TextColumn get sessionToken => text().nullable()(); // 세션 토큰 (UUID)
  DateTimeColumn get sessionExpiresAt => dateTime().nullable()(); // 세션 만료 시간

  // RBAC 시스템 필드 (새로운 권한 시스템)
  TextColumn get defaultRole => text().withDefault(const Constant('STAFF'))(); // OWNER | AREA_MANAGER | STORE_MANAGER | STAFF
  TextColumn get storeScope => text().withDefault(const Constant('OWN_STORE'))(); // ALL_STORES | ASSIGNED_STORES | OWN_STORE
  TextColumn get primaryStoreId => text().nullable()(); // 주 근무 매장 ID

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

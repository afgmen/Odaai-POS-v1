import 'package:drift/drift.dart';

import 'sales.dart';

class KitchenOrders extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Foreign Key
  IntColumn get saleId => integer().references(Sales, #id, onDelete: KeyAction.cascade)();

  // Status & Priority
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
    // 'PENDING' | 'PREPARING' | 'READY' | 'SERVED' | 'CANCELLED'

  TextColumn get priority => text().withDefault(const Constant('NORMAL'))();
    // 'NORMAL' | 'URGENT'

  // Additional Info
  TextColumn get specialInstructions => text().nullable()();
  TextColumn get tableNumber => text().nullable()(); // 테이블 번호

  // Timestamps
  DateTimeColumn get startedAt => dateTime().nullable()(); // 조리 시작
  DateTimeColumn get readyAt => dateTime().nullable()();   // 완료
  DateTimeColumn get servedAt => dateTime().nullable()();  // 서빙
  DateTimeColumn get cancelledAt => dateTime().nullable()(); // 취소

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

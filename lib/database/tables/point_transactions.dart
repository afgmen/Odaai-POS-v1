import 'package:drift/drift.dart';
import 'sales.dart';
import 'employees.dart';

/// 포인트 트랜잭션 테이블
/// 고객의 포인트 적립/사용 이력을 추적합니다.
class PointTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 관계
  IntColumn get customerId => integer().named('customer_id')();
  IntColumn get saleId => integer().nullable().named('sale_id').references(Sales, #id, onDelete: KeyAction.setNull)();
  IntColumn get employeeId => integer().nullable().named('employee_id').references(Employees, #id, onDelete: KeyAction.setNull)();

  // 트랜잭션 정보
  IntColumn get amount => integer()(); // 양수: 적립, 음수: 사용
  TextColumn get transactionType => text().named('transaction_type')(); // 'earn', 'redeem', 'adjust', 'expire', 'bonus'
  TextColumn get description => text()();
  IntColumn get balanceAfter => integer().named('balance_after')(); // 트랜잭션 후 잔액 (검증용)

  // 메타데이터
  TextColumn get metadata => text().nullable()(); // JSON: { "promotion": "2x", "reason": "..." }
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
}

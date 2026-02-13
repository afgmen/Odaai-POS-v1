import 'package:drift/drift.dart';
import 'employees.dart';

/// 일일 마감 테이블
class DailyClosings extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 마감 기본 정보
  DateTimeColumn get closingDate => dateTime()(); // 마감 대상 날짜 (yyyy-MM-dd)
  DateTimeColumn get closedAt => dateTime()(); // 실제 마감 수행 시각

  // 매출 집계
  RealColumn get totalSales => real()(); // 총 매출
  IntColumn get totalTransactions => integer()(); // 총 거래 건수

  // 결제 수단별 매출
  RealColumn get cashSales => real().withDefault(const Constant(0.0))();
  RealColumn get cardSales => real().withDefault(const Constant(0.0))();
  RealColumn get qrSales => real().withDefault(const Constant(0.0))();
  RealColumn get transferSales => real().withDefault(const Constant(0.0))();

  // 세금 및 할인
  RealColumn get totalTax => real().withDefault(const Constant(0.0))();
  RealColumn get totalDiscount => real().withDefault(const Constant(0.0))();
  RealColumn get averageTransaction => real()(); // 평균 거래 금액

  // 시재 관리
  RealColumn get expectedCash => real()(); // 예상 현금 (cashSales)
  RealColumn get actualCash => real().nullable()(); // 실제 현금
  RealColumn get cashDifference => real().nullable()(); // 차액 (actual - expected)

  // 메타데이터
  IntColumn get closedByEmployeeId =>
      integer().references(Employees, #id, onDelete: KeyAction.setNull)();
  TextColumn get notes => text().nullable()(); // 특이사항 메모
  TextColumn get metadata => text().nullable()(); // JSON: 추가 정보
}

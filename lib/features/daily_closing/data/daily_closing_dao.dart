import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/daily_closings.dart';
import '../../../database/tables/sales.dart';
import '../../../database/tables/employees.dart';
import '../domain/constants/closing_constants.dart';

part 'daily_closing_dao.g.dart';

@DriftAccessor(tables: [DailyClosings, Sales, Employees])
class DailyClosingDao extends DatabaseAccessor<AppDatabase>
    with _$DailyClosingDaoMixin {
  DailyClosingDao(super.db);

  // ═══════════════════════════════════════════════════════
  // 매출 집계
  // ═══════════════════════════════════════════════════════

  /// 특정 날짜의 매출 집계 데이터 조회
  Future<SalesAggregation?> aggregateSalesForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await customSelect(
      '''
      SELECT
        COUNT(*) as total_transactions,
        COALESCE(SUM(total), 0.0) as total_sales,
        COALESCE(SUM(tax), 0.0) as total_tax,
        COALESCE(SUM(discount), 0.0) as total_discount,
        COALESCE(SUM(CASE WHEN payment_method = ? THEN total ELSE 0 END), 0.0) as cash_sales,
        COALESCE(SUM(CASE WHEN payment_method = ? THEN total ELSE 0 END), 0.0) as card_sales,
        COALESCE(SUM(CASE WHEN payment_method = ? THEN total ELSE 0 END), 0.0) as qr_sales,
        COALESCE(SUM(CASE WHEN payment_method = ? THEN total ELSE 0 END), 0.0) as transfer_sales,
        COALESCE(AVG(total), 0.0) as average_transaction
      FROM sales
      WHERE sale_date >= ? AND sale_date < ?
      ''',
      variables: [
        Variable.withString('CASH'),
        Variable.withString('CARD'),
        Variable.withString('QR'),
        Variable.withString('TRANSFER'),
        Variable.withInt(startOfDay.millisecondsSinceEpoch),
        Variable.withInt(endOfDay.millisecondsSinceEpoch),
      ],
    ).getSingleOrNull();

    if (result == null) return null;

    return SalesAggregation(
      totalTransactions: result.read<int>('total_transactions'),
      totalSales: result.read<double>('total_sales'),
      totalTax: result.read<double>('total_tax'),
      totalDiscount: result.read<double>('total_discount'),
      cashSales: result.read<double>('cash_sales'),
      cardSales: result.read<double>('card_sales'),
      qrSales: result.read<double>('qr_sales'),
      transferSales: result.read<double>('transfer_sales'),
      averageTransaction: result.read<double>('average_transaction'),
    );
  }

  /// 특정 기간의 일별 매출 목록
  Future<List<DailySalesSummary>> getDailySalesRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final results = await customSelect(
      '''
      SELECT
        DATE(sale_date / 1000, 'unixepoch', 'localtime') as sale_date,
        COUNT(*) as total_transactions,
        SUM(total) as total_sales
      FROM sales
      WHERE sale_date >= ? AND sale_date < ?
      GROUP BY DATE(sale_date / 1000, 'unixepoch', 'localtime')
      ORDER BY sale_date DESC
      ''',
      variables: [
        Variable.withInt(startDate.millisecondsSinceEpoch),
        Variable.withInt(endDate.millisecondsSinceEpoch),
      ],
    ).get();

    return results.map((row) {
      return DailySalesSummary(
        date: DateTime.parse(row.read<String>('sale_date')),
        totalTransactions: row.read<int>('total_transactions'),
        totalSales: row.read<double>('total_sales'),
      );
    }).toList();
  }

  // ═══════════════════════════════════════════════════════
  // 마감 데이터 관리
  // ═══════════════════════════════════════════════════════

  /// 일일 마감 생성
  Future<int> createDailyClosing({
    required DateTime closingDate,
    required SalesAggregation aggregation,
    required int employeeId,
    double? actualCash,
    String? notes,
  }) async {
    final cashDifference = actualCash != null
        ? actualCash - aggregation.cashSales
        : null;

    return await into(dailyClosings).insert(
      DailyClosingsCompanion.insert(
        closingDate: closingDate,
        closedAt: DateTime.now(),
        totalSales: aggregation.totalSales,
        totalTransactions: aggregation.totalTransactions,
        cashSales: Value(aggregation.cashSales),
        cardSales: Value(aggregation.cardSales),
        qrSales: Value(aggregation.qrSales),
        transferSales: Value(aggregation.transferSales),
        totalTax: Value(aggregation.totalTax),
        totalDiscount: Value(aggregation.totalDiscount),
        averageTransaction: aggregation.averageTransaction,
        expectedCash: aggregation.cashSales,
        actualCash: Value(actualCash),
        cashDifference: Value(cashDifference),
        closedByEmployeeId: employeeId,
        notes: Value(notes),
      ),
    );
  }

  /// 특정 날짜의 마감 데이터 조회
  Future<DailyClosing?> getClosingByDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return (select(dailyClosings)
          ..where((c) => c.closingDate.equals(targetDate)))
        .getSingleOrNull();
  }

  /// 마감 존재 여부 확인
  Future<bool> hasClosingForDate(DateTime date) async {
    final closing = await getClosingByDate(date);
    return closing != null;
  }

  /// 최근 마감 목록 조회 (페이지네이션)
  Future<List<DailyClosing>> getRecentClosings({
    int limit = 30,
    int offset = 0,
  }) {
    return (select(dailyClosings)
          ..orderBy([(c) => OrderingTerm.desc(c.closingDate)])
          ..limit(limit, offset: offset))
        .get();
  }

  /// 마감 데이터와 직원 정보 조인 조회
  Future<List<ClosingWithEmployee>> getClosingsWithEmployee({
    int limit = 30,
  }) async {
    final query = select(dailyClosings).join([
      leftOuterJoin(
        employees,
        employees.id.equalsExp(dailyClosings.closedByEmployeeId),
      ),
    ])
      ..orderBy([OrderingTerm.desc(dailyClosings.closingDate)])
      ..limit(limit);

    final results = await query.get();
    return results.map((row) {
      return ClosingWithEmployee(
        closing: row.readTable(dailyClosings),
        employee: row.readTableOrNull(employees),
      );
    }).toList();
  }

  /// 특정 기간의 매출 합계
  Future<PeriodSummary> getPeriodSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await customSelect(
      '''
      SELECT
        COUNT(*) as closing_count,
        SUM(total_sales) as total_sales,
        SUM(total_transactions) as total_transactions,
        AVG(average_transaction) as avg_transaction,
        SUM(total_tax) as total_tax,
        SUM(total_discount) as total_discount
      FROM daily_closings
      WHERE closing_date >= ? AND closing_date < ?
      ''',
      variables: [
        Variable.withInt(startDate.millisecondsSinceEpoch),
        Variable.withInt(endDate.millisecondsSinceEpoch),
      ],
    ).getSingleOrNull();

    if (result == null) {
      return PeriodSummary.empty();
    }

    return PeriodSummary(
      closingCount: result.read<int>('closing_count'),
      totalSales: result.read<double>('total_sales'),
      totalTransactions: result.read<int>('total_transactions'),
      avgTransaction: result.read<double>('avg_transaction'),
      totalTax: result.read<double>('total_tax'),
      totalDiscount: result.read<double>('total_discount'),
    );
  }

  /// 시재 차이가 있는 마감 조회
  Future<List<DailyClosing>> getClosingsWithCashDifference({
    double minDifference = ClosingConstants.acceptableCashDifference,
  }) {
    return (select(dailyClosings)
          ..where((c) =>
              c.cashDifference.isNotNull() &
              c.cashDifference.abs().isBiggerOrEqualValue(minDifference))
          ..orderBy([(c) => OrderingTerm.desc(c.closingDate)]))
        .get();
  }

  /// 마감 노트 업데이트
  Future<void> updateClosingNotes(int closingId, String notes) {
    return (update(dailyClosings)..where((c) => c.id.equals(closingId)))
        .write(DailyClosingsCompanion(notes: Value(notes)));
  }

  /// 실제 현금 입력 (추후 보완)
  Future<void> updateActualCash(int closingId, double actualCash) async {
    final closing = await (select(dailyClosings)
          ..where((c) => c.id.equals(closingId)))
        .getSingle();

    final difference = actualCash - closing.expectedCash;

    await (update(dailyClosings)..where((c) => c.id.equals(closingId)))
        .write(DailyClosingsCompanion(
      actualCash: Value(actualCash),
      cashDifference: Value(difference),
    ));
  }
}

// ═══════════════════════════════════════════════════════
// 데이터 모델
// ═══════════════════════════════════════════════════════

class SalesAggregation {
  final int totalTransactions;
  final double totalSales;
  final double totalTax;
  final double totalDiscount;
  final double cashSales;
  final double cardSales;
  final double qrSales;
  final double transferSales;
  final double averageTransaction;

  SalesAggregation({
    required this.totalTransactions,
    required this.totalSales,
    required this.totalTax,
    required this.totalDiscount,
    required this.cashSales,
    required this.cardSales,
    required this.qrSales,
    required this.transferSales,
    required this.averageTransaction,
  });
}

class DailySalesSummary {
  final DateTime date;
  final int totalTransactions;
  final double totalSales;

  DailySalesSummary({
    required this.date,
    required this.totalTransactions,
    required this.totalSales,
  });
}

class ClosingWithEmployee {
  final DailyClosing closing;
  final Employee? employee;

  ClosingWithEmployee({
    required this.closing,
    required this.employee,
  });
}

class PeriodSummary {
  final int closingCount;
  final double totalSales;
  final int totalTransactions;
  final double avgTransaction;
  final double totalTax;
  final double totalDiscount;

  PeriodSummary({
    required this.closingCount,
    required this.totalSales,
    required this.totalTransactions,
    required this.avgTransaction,
    required this.totalTax,
    required this.totalDiscount,
  });

  factory PeriodSummary.empty() {
    return PeriodSummary(
      closingCount: 0,
      totalSales: 0.0,
      totalTransactions: 0,
      avgTransaction: 0.0,
      totalTax: 0.0,
      totalDiscount: 0.0,
    );
  }
}

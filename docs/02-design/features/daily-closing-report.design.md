# Design: 일일 마감 리포트

**Feature ID:** FEAT-002
**Plan 문서:** [daily-closing-report.plan.md](../../01-plan/features/daily-closing-report.plan.md)
**작성일:** 2026-02-09
**작성자:** Development Team

---

## 📋 목차
1. [아키텍처 개요](#아키텍처-개요)
2. [데이터베이스 설계](#데이터베이스-설계)
3. [DAO 설계](#dao-설계)
4. [비즈니스 로직 설계](#비즈니스-로직-설계)
5. [상태 관리 설계](#상태-관리-설계)
6. [UI 설계](#ui-설계)
7. [PDF 생성 설계](#pdf-생성-설계)
8. [구현 순서](#구현-순서)
9. [테스트 시나리오](#테스트-시나리오)

---

## 아키텍처 개요

### 레이어 구조
```
┌─────────────────────────────────────────┐
│          Presentation Layer             │
│  - Screens (closing_screen.dart)        │
│  - Widgets (closing_summary_card.dart)  │
│  - Dialogs (cash_count_dialog.dart)     │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Provider Layer (Riverpod)       │
│  - daily_closing_provider.dart          │
│  - closing_report_provider.dart         │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│           Service Layer                 │
│  - closing_service.dart                 │
│  - report_generator_service.dart        │
│  - pdf_export_service.dart              │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│             DAO Layer                   │
│  - daily_closing_dao.dart (신규)        │
│  - sales_dao.dart (확장)                │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│          Database Layer (Drift)         │
│  - DailyClosings (신규)                 │
│  - Sales (기존)                         │
└─────────────────────────────────────────┘
```

### 디렉토리 구조
```
lib/features/daily_closing/
├── data/
│   └── daily_closing_dao.dart
├── domain/
│   ├── models/
│   │   ├── daily_closing_summary.dart
│   │   ├── payment_breakdown.dart
│   │   └── cash_reconciliation.dart
│   └── services/
│       ├── closing_service.dart
│       ├── report_generator_service.dart
│       └── pdf_export_service.dart
├── providers/
│   ├── daily_closing_provider.dart
│   └── closing_report_provider.dart
└── presentation/
    ├── screens/
    │   ├── daily_closing_screen.dart
    │   └── closing_history_screen.dart
    └── widgets/
        ├── closing_summary_card.dart
        ├── payment_breakdown_widget.dart
        ├── cash_count_dialog.dart
        └── report_action_buttons.dart
```

---

## 데이터베이스 설계

### 1. DailyClosings 테이블 (신규)

```dart
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
  IntColumn get closedByEmployeeId => integer().references(Employees, #id, onDelete: KeyAction.setNull)();
  TextColumn get notes => text().nullable()(); // 특이사항 메모
  TextColumn get metadata => text().nullable()(); // JSON: 추가 정보

  @override
  Set<Column> get primaryKey => {id};
}
```

**인덱스:**
```dart
// app_database.dart의 onUpgrade에 추가
await customStatement(
  'CREATE UNIQUE INDEX idx_daily_closings_date '
  'ON daily_closings(closing_date)'
);
await customStatement(
  'CREATE INDEX idx_daily_closings_employee '
  'ON daily_closings(closed_by_employee_id)'
);
```

**스키마 버전:** v6 (v5 → v6 마이그레이션)

### 2. Sales 테이블 (확장 불필요)

기존 Sales 테이블 구조 활용:
- `saleDate`: 판매 날짜
- `total`: 최종 결제 금액
- `subtotal`: 상품 합계
- `tax`: 세금
- `discount`: 할인 금액
- `paymentMethod`: 결제 수단 (CASH, CARD, QR, TRANSFER)

**집계 쿼리:**
```sql
-- 특정 날짜의 매출 집계
SELECT
  COUNT(*) as total_transactions,
  SUM(total) as total_sales,
  SUM(tax) as total_tax,
  SUM(discount) as total_discount,
  SUM(CASE WHEN payment_method = 'CASH' THEN total ELSE 0 END) as cash_sales,
  SUM(CASE WHEN payment_method = 'CARD' THEN total ELSE 0 END) as card_sales,
  SUM(CASE WHEN payment_method = 'QR' THEN total ELSE 0 END) as qr_sales,
  SUM(CASE WHEN payment_method = 'TRANSFER' THEN total ELSE 0 END) as transfer_sales,
  AVG(total) as average_transaction
FROM sales
WHERE DATE(sale_date) = ?
```

---

## DAO 설계

### 1. DailyClosingDao (신규)

**파일:** `lib/features/daily_closing/data/daily_closing_dao.dart`

```dart
import 'package:drift/drift.dart';
import '../../../database/app_database.dart';

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
    double minDifference = 1000.0,
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
```

---

## 비즈니스 로직 설계

### 1. ClosingService

**파일:** `lib/features/daily_closing/domain/services/closing_service.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/daily_closing_dao.dart';
import '../../../auth/providers/auth_provider.dart';

/// ClosingService Provider
final closingServiceProvider = Provider<ClosingService>((ref) {
  final dao = ref.watch(dailyClosingDaoProvider);
  final authNotifier = ref.watch(authProvider.notifier);
  return ClosingService(dao, authNotifier);
});

/// 마감 비즈니스 로직
class ClosingService {
  final DailyClosingDao _dao;
  final dynamic _authNotifier;

  ClosingService(this._dao, this._authNotifier);

  /// 마감 가능 여부 확인
  Future<ClosingValidationResult> validateClosing(DateTime date) async {
    // 1. 이미 마감된 날짜인지 확인
    final hasClosing = await _dao.hasClosingForDate(date);
    if (hasClosing) {
      return ClosingValidationResult(
        canClose: false,
        reason: '이미 마감된 날짜입니다.',
      );
    }

    // 2. 미래 날짜인지 확인
    final now = DateTime.now();
    if (date.isAfter(DateTime(now.year, now.month, now.day))) {
      return ClosingValidationResult(
        canClose: false,
        reason: '미래 날짜는 마감할 수 없습니다.',
      );
    }

    // 3. 해당 날짜에 매출이 있는지 확인
    final aggregation = await _dao.aggregateSalesForDate(date);
    if (aggregation == null || aggregation.totalTransactions == 0) {
      return ClosingValidationResult(
        canClose: false,
        reason: '해당 날짜에 판매 내역이 없습니다.',
      );
    }

    return ClosingValidationResult(
      canClose: true,
      aggregation: aggregation,
    );
  }

  /// 일일 마감 수행
  Future<ClosingResult> performClosing({
    required DateTime date,
    double? actualCash,
    String? notes,
  }) async {
    try {
      // 1. 검증
      final validation = await validateClosing(date);
      if (!validation.canClose) {
        return ClosingResult(
          success: false,
          message: validation.reason ?? '마감할 수 없습니다.',
        );
      }

      // 2. 현재 직원 ID 확인
      final currentSession = _authNotifier.currentSession;
      if (currentSession == null) {
        return ClosingResult(
          success: false,
          message: '로그인이 필요합니다.',
        );
      }

      // 3. 마감 데이터 생성
      final closingId = await _dao.createDailyClosing(
        closingDate: date,
        aggregation: validation.aggregation!,
        employeeId: currentSession.employeeId,
        actualCash: actualCash,
        notes: notes,
      );

      return ClosingResult(
        success: true,
        closingId: closingId,
        message: '마감이 완료되었습니다.',
      );
    } catch (e) {
      return ClosingResult(
        success: false,
        message: '마감 처리 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// 오늘 마감 가능 여부 확인
  Future<bool> canCloseToday() async {
    final today = DateTime.now();
    final targetDate = DateTime(today.year, today.month, today.day);
    return !(await _dao.hasClosingForDate(targetDate));
  }

  /// 시재 차액 계산
  double calculateCashDifference({
    required double expectedCash,
    required double actualCash,
  }) {
    return actualCash - expectedCash;
  }

  /// 시재 차액 허용 범위 확인
  bool isCashDifferenceAcceptable(double difference) {
    const acceptableRange = 1000.0; // 1,000원까지 허용
    return difference.abs() <= acceptableRange;
  }
}

// ═══════════════════════════════════════════════════════
// 결과 모델
// ═══════════════════════════════════════════════════════

class ClosingValidationResult {
  final bool canClose;
  final String? reason;
  final SalesAggregation? aggregation;

  ClosingValidationResult({
    required this.canClose,
    this.reason,
    this.aggregation,
  });
}

class ClosingResult {
  final bool success;
  final int? closingId;
  final String message;

  ClosingResult({
    required this.success,
    this.closingId,
    required this.message,
  });
}
```

### 2. PdfExportService

**파일:** `lib/features/daily_closing/domain/services/pdf_export_service.dart`

```dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../../../database/app_database.dart';
import '../../data/daily_closing_dao.dart';

/// PDF 리포트 생성 서비스
class PdfExportService {
  final currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');
  final dateFormat = DateFormat('yyyy-MM-dd');
  final timeFormat = DateFormat('HH:mm');

  /// 일일 마감 PDF 생성
  Future<File> generateClosingReport(
    DailyClosing closing,
    Employee? employee,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 제목
              pw.Header(
                level: 0,
                child: pw.Text(
                  '일일 마감 리포트',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // 마감 정보
              _buildInfoSection(closing, employee),
              pw.SizedBox(height: 20),

              // 매출 요약
              _buildSalesSummary(closing),
              pw.SizedBox(height: 20),

              // 결제 수단별 매출
              _buildPaymentBreakdown(closing),
              pw.SizedBox(height: 20),

              // 시재 관리
              if (closing.actualCash != null)
                _buildCashReconciliation(closing),

              // 특이사항
              if (closing.notes != null && closing.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildNotes(closing),
              ],

              pw.Spacer(),

              // 서명란
              _buildSignatureSection(employee),
            ],
          );
        },
      ),
    );

    // 파일 저장
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'closing_${dateFormat.format(closing.closingDate)}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// 정보 섹션
  pw.Widget _buildInfoSection(DailyClosing closing, Employee? employee) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRow('마감 날짜', dateFormat.format(closing.closingDate)),
          _buildInfoRow('마감 시각',
              '${dateFormat.format(closing.closedAt)} ${timeFormat.format(closing.closedAt)}'),
          _buildInfoRow('마감 담당', employee?.name ?? '알 수 없음'),
        ],
      ),
    );
  }

  /// 매출 요약
  pw.Widget _buildSalesSummary(DailyClosing closing) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '매출 요약',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow('총 거래 건수', '${closing.totalTransactions}건'),
            _buildTableRow('총 매출', currencyFormat.format(closing.totalSales)),
            _buildTableRow('평균 거래 금액',
                currencyFormat.format(closing.averageTransaction)),
            _buildTableRow('총 세금', currencyFormat.format(closing.totalTax)),
            _buildTableRow('총 할인', currencyFormat.format(closing.totalDiscount)),
          ],
        ),
      ],
    );
  }

  /// 결제 수단별 매출
  pw.Widget _buildPaymentBreakdown(DailyClosing closing) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '결제 수단별 매출',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow('현금', currencyFormat.format(closing.cashSales)),
            _buildTableRow('카드', currencyFormat.format(closing.cardSales)),
            _buildTableRow('QR 결제', currencyFormat.format(closing.qrSales)),
            _buildTableRow('계좌이체', currencyFormat.format(closing.transferSales)),
          ],
        ),
      ],
    );
  }

  /// 시재 관리
  pw.Widget _buildCashReconciliation(DailyClosing closing) {
    final isDifferenceAcceptable =
        (closing.cashDifference?.abs() ?? 0) <= 1000.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '시재 관리',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            _buildTableRow('예상 현금',
                currencyFormat.format(closing.expectedCash)),
            _buildTableRow('실제 현금',
                currencyFormat.format(closing.actualCash!)),
            _buildTableRow(
              '차액',
              currencyFormat.format(closing.cashDifference!),
              valueColor: isDifferenceAcceptable
                  ? PdfColors.green
                  : PdfColors.red,
            ),
          ],
        ),
      ],
    );
  }

  /// 특이사항
  pw.Widget _buildNotes(DailyClosing closing) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '특이사항',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Text(closing.notes!),
        ),
      ],
    );
  }

  /// 서명란
  pw.Widget _buildSignatureSection(Employee? employee) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('마감 담당자:'),
            pw.SizedBox(height: 30),
            pw.Text('서명: _________________'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('확인자:'),
            pw.SizedBox(height: 30),
            pw.Text('서명: _________________'),
          ],
        ),
      ],
    );
  }

  // 헬퍼 메서드
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  pw.TableRow _buildTableRow(
    String label,
    String value, {
    PdfColor? valueColor,
  }) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: valueColor,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }
}
```

---

## 상태 관리 설계

### DailyClosingProvider

**파일:** `lib/features/daily_closing/providers/daily_closing_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';
import '../data/daily_closing_dao.dart';
import '../domain/services/closing_service.dart';

/// DailyClosingDao Provider
final dailyClosingDaoProvider = Provider<DailyClosingDao>((ref) {
  return ref.watch(databaseProvider).dailyClosingDao;
});

/// 특정 날짜의 마감 데이터
final closingByDateProvider = FutureProvider.family<DailyClosing?, DateTime>(
  (ref, date) {
    return ref.watch(dailyClosingDaoProvider).getClosingByDate(date);
  },
);

/// 오늘 마감 가능 여부
final canCloseTodayProvider = FutureProvider<bool>((ref) {
  return ref.watch(closingServiceProvider).canCloseToday();
});

/// 특정 날짜의 매출 집계
final salesAggregationProvider = FutureProvider.family<SalesAggregation?, DateTime>(
  (ref, date) {
    return ref.watch(dailyClosingDaoProvider).aggregateSalesForDate(date);
  },
);

/// 최근 마감 목록
final recentClosingsProvider = FutureProvider.family<List<ClosingWithEmployee>, int>(
  (ref, limit) {
    return ref.watch(dailyClosingDaoProvider).getClosingsWithEmployee(limit: limit);
  },
);

/// 특정 기간 요약
final periodSummaryProvider = FutureProvider.family<PeriodSummary, DateRange>(
  (ref, range) {
    return ref.watch(dailyClosingDaoProvider).getPeriodSummary(
      startDate: range.startDate,
      endDate: range.endDate,
    );
  },
);

/// 시재 차이가 있는 마감 목록
final closingsWithCashDifferenceProvider = FutureProvider<List<DailyClosing>>((ref) {
  return ref.watch(dailyClosingDaoProvider).getClosingsWithCashDifference();
});

// ═══════════════════════════════════════════════════════
// 헬퍼 클래스
// ═══════════════════════════════════════════════════════

class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  DateRange({
    required this.startDate,
    required this.endDate,
  });
}
```

---

## UI 설계

### 1. 일일 마감 화면

**파일:** `lib/features/daily_closing/presentation/screens/daily_closing_screen.dart`

**화면 구성:**
```
┌─────────────────────────────────────────┐
│  일일 마감              [이력 보기]      │
├─────────────────────────────────────────┤
│  📅 마감 날짜 선택                       │
│  [2026-02-09 ▼]                         │
│                                          │
│  📊 매출 요약                            │
│  ┌──────────────────────────────────┐  │
│  │ 총 거래 건수:    47건             │  │
│  │ 총 매출:        1,245,000원       │  │
│  │ 평균 거래액:      26,489원        │  │
│  │ 총 세금:         113,182원        │  │
│  │ 총 할인:          45,000원        │  │
│  └──────────────────────────────────┘  │
│                                          │
│  💳 결제 수단별 매출                     │
│  ┌──────────────────────────────────┐  │
│  │ 현금:      450,000원 (36%)       │  │
│  │ 카드:      685,000원 (55%)       │  │
│  │ QR결제:     85,000원 (7%)        │  │
│  │ 계좌이체:   25,000원 (2%)        │  │
│  └──────────────────────────────────┘  │
│                                          │
│  💰 시재 관리                            │
│  ┌──────────────────────────────────┐  │
│  │ 예상 현금:  450,000원             │  │
│  │ 실제 현금:  [__________] 원       │  │
│  │ (미입력)                          │  │
│  └──────────────────────────────────┘  │
│                                          │
│  📝 특이사항                             │
│  [________________________________]   │
│                                          │
│  [PDF 저장]        [마감 완료] 🔒       │
└─────────────────────────────────────────┘
```

### 2. 마감 이력 화면

**화면 구성:**
```
┌─────────────────────────────────────────┐
│  마감 이력          [기간▼] [엑셀▼]     │
├─────────────────────────────────────────┤
│  📊 2026-02-09                          │
│  ├ 총 매출: 1,245,000원 (47건)          │
│  ├ 시재 차액: +500원                    │
│  └ 담당: 홍길동         [PDF] [상세]    │
│  ─────────────────────────────────────  │
│  📊 2026-02-08                          │
│  ├ 총 매출: 987,500원 (38건)            │
│  ├ 시재 차액: -2,000원 ⚠️                │
│  └ 담당: 김철수         [PDF] [상세]    │
│  ─────────────────────────────────────  │
│  📊 2026-02-07                          │
│  ├ 총 매출: 1,456,000원 (52건)          │
│  ├ 시재 차액: 0원                       │
│  └ 담당: 홍길동         [PDF] [상세]    │
│  ─────────────────────────────────────  │
│  ...                                     │
└─────────────────────────────────────────┘
```

### 3. 현금 입력 다이얼로그

**파일:** `lib/features/daily_closing/presentation/widgets/cash_count_dialog.dart`

**UI 구성:**
```
┌─────────────────────────────────────────┐
│  시재 확인                               │
├─────────────────────────────────────────┤
│  예상 현금:  450,000원                   │
│                                          │
│  실제 현금 입력:                         │
│  ┌──────────────────────────────────┐  │
│  │ [__________] 원                   │  │
│  └──────────────────────────────────┘  │
│                                          │
│  차액: (계산 후 표시)                    │
│                                          │
│  [취소]                    [확인]        │
└─────────────────────────────────────────┘
```

---

## PDF 생성 설계

### PDF 구성 요소

1. **Header**
   - 리포트 제목: "일일 마감 리포트"
   - 생성 날짜 및 시각

2. **마감 정보**
   - 마감 날짜
   - 마감 시각
   - 마감 담당자

3. **매출 요약 테이블**
   - 총 거래 건수
   - 총 매출
   - 평균 거래 금액
   - 총 세금
   - 총 할인

4. **결제 수단별 매출 테이블**
   - 현금 / 카드 / QR / 계좌이체
   - 각 금액 및 비율

5. **시재 관리 (선택)**
   - 예상 현금
   - 실제 현금
   - 차액 (색상 표시: 허용 범위 내/외)

6. **특이사항 (선택)**
   - 메모 내용

7. **서명란**
   - 마감 담당자 서명
   - 확인자 서명

### PDF 패키지 의존성

```yaml
dependencies:
  pdf: ^3.10.0
  path_provider: ^2.1.0
  intl: ^0.18.0
```

---

## 구현 순서

### Phase 1: 데이터베이스 및 DAO (30분)
1. ✅ DailyClosings 테이블 정의
   - [ ] 테이블 클래스 작성
   - [ ] 인덱스 설정
   - [ ] 스키마 버전 업데이트 (v6)

2. ✅ DailyClosingDao 구현
   - [ ] 매출 집계 메서드
   - [ ] 마감 CRUD 메서드
   - [ ] 통계 조회 메서드
   - [ ] 코드 생성 (`build_runner`)

### Phase 2: 비즈니스 로직 (30분)
3. ✅ ClosingService 구현
   - [ ] 마감 검증 로직
   - [ ] 마감 수행 로직
   - [ ] 시재 차액 계산

4. ✅ PdfExportService 구현
   - [ ] PDF 생성 로직
   - [ ] 레이아웃 구성
   - [ ] 파일 저장

### Phase 3: 상태 관리 (15분)
5. ✅ Provider 구현
   - [ ] `daily_closing_provider.dart`
   - [ ] `closing_report_provider.dart`

### Phase 4: UI 구현 (30분)
6. ✅ 위젯 개발
   - [ ] `ClosingSummaryCard`
   - [ ] `PaymentBreakdownWidget`
   - [ ] `CashCountDialog`

7. ✅ 화면 개발
   - [ ] `DailyClosingScreen`
   - [ ] `ClosingHistoryScreen`

### Phase 5: 테스트 (15분)
8. ✅ 기능 테스트
   - [ ] 마감 수행 테스트
   - [ ] PDF 생성 테스트
   - [ ] 이력 조회 테스트

---

## 테스트 시나리오

### 시나리오 1: 정상 마감
1. 관리자 로그인
2. 일일 마감 화면 진입
3. 오늘 날짜 선택
4. 매출 데이터 자동 집계 확인
5. 실제 현금 입력 (예상과 동일)
6. 특이사항 미입력
7. "마감 완료" 클릭
8. 성공 메시지 표시
9. PDF 자동 생성 및 저장

### 시나리오 2: 시재 차액 발생
1. 관리자 로그인
2. 일일 마감 화면 진입
3. 오늘 날짜 선택
4. 예상 현금: 450,000원
5. 실제 현금 입력: 448,500원
6. 차액: -1,500원 (허용 범위 외)
7. 경고 메시지 표시
8. 특이사항 입력: "5천원권 1장, 백원 5개 부족"
9. "마감 완료" 클릭
10. PDF에 시재 차액 빨간색 표시

### 시나리오 3: 과거 날짜 마감
1. 관리자 로그인
2. 일일 마감 화면 진입
3. 어제 날짜 선택
4. 매출 데이터 집계 확인
5. 실제 현금 미입력 (선택)
6. "마감 완료" 클릭
7. 성공 메시지 표시

### 시나리오 4: 중복 마감 방지
1. 관리자 로그인
2. 이미 마감된 날짜 선택
3. "이미 마감된 날짜입니다" 메시지 표시
4. "마감 완료" 버튼 비활성화

### 시나리오 5: 마감 이력 조회
1. 관리자 로그인
2. "이력 보기" 클릭
3. 최근 30일 마감 목록 표시
4. 특정 마감 선택
5. PDF 다운로드 또는 상세 보기

### 시나리오 6: 기간별 요약
1. 관리자 로그인
2. 마감 이력 화면
3. 기간 선택: 2026-02-01 ~ 2026-02-28
4. 총 마감 횟수, 총 매출, 평균 거래액 표시
5. CSV 내보내기

---

## 에러 처리

### 1. 데이터베이스 오류
- 트랜잭션 실패 시 롤백
- 사용자에게 명확한 오류 메시지 표시
- 로그 기록

### 2. PDF 생성 오류
- 파일 저장 실패 시 재시도
- 권한 오류 처리
- 사용자에게 알림

### 3. 권한 오류
- 관리자 권한 확인
- 비관리자 접근 시 오류 화면 표시

### 4. 데이터 검증 오류
- 입력값 검증 (실제 현금, 날짜 등)
- 명확한 검증 메시지 표시

---

## 보안 고려사항

1. **권한 관리**
   - 관리자만 마감 수행 가능
   - 권한 확인 시 PermissionProvider 활용

2. **데이터 무결성**
   - 트랜잭션 사용으로 원자성 보장
   - 중복 마감 방지 (UNIQUE INDEX)

3. **감사 로그**
   - 마감 수행자 기록
   - 마감 시각 기록

---

**Design 작성 완료일:** 2026-02-09
**다음 단계:** 구현 시작 (`/pdca do daily-closing-report`)

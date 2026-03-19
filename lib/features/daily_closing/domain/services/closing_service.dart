import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';
import '../../data/daily_closing_dao.dart';
import '../../providers/daily_closing_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../constants/closing_constants.dart';

/// ClosingService Provider
final closingServiceProvider = Provider<ClosingService>((ref) {
  final dao = ref.watch(dailyClosingDaoProvider);
  final authNotifier = ref.watch(authProvider.notifier);
  final db = ref.watch(databaseProvider);
  return ClosingService(dao, authNotifier, db);
});

/// 마감 비즈니스 로직
class ClosingService {
  final DailyClosingDao _dao;
  final dynamic _authNotifier;
  final AppDatabase _db;

  ClosingService(this._dao, this._authNotifier, this._db);

  /// 마감 가능 여부 확인
  Future<ClosingValidationResult> validateClosing(DateTime date) async {
    // 1. 이미 마감된 날짜인지 확인
    final hasClosing = await _dao.hasClosingForDate(date);
    if (hasClosing) {
      return ClosingValidationResult(
        canClose: false,
        reason: 'This date has already been closed.',
      );
    }

    // 2. 미래 날짜인지 확인
    final now = DateTime.now();
    if (date.isAfter(DateTime(now.year, now.month, now.day))) {
      return ClosingValidationResult(
        canClose: false,
        reason: 'Cannot close a future date.',
      );
    }

    // 3. 미결제(Open Tab) 주문 확인
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final openTabs = await (_db.select(_db.sales)
          ..where((s) =>
              s.isOpenTab.equals(true) &
              s.status.equals('open') &
              s.saleDate.isBiggerOrEqualValue(startOfDay) &
              s.saleDate.isSmallerThanValue(endOfDay)))
        .get();
    if (openTabs.isNotEmpty) {
      return ClosingValidationResult(
        canClose: false,
        reason: 'There are ${openTabs.length} unpaid open tab order(s) remaining.\n'
            'Please complete or cancel all open orders before closing.',
        failCode: ClosingFailCode.openTabsExist,
        openTabCount: openTabs.length,
      );
    }

    // 4. 미결제 상태 주문 확인 (status = 'open' but not open tab)
    final openOrders = await (_db.select(_db.sales)
          ..where((s) =>
              s.status.equals('open') &
              s.isOpenTab.equals(false) &
              s.saleDate.isBiggerOrEqualValue(startOfDay) &
              s.saleDate.isSmallerThanValue(endOfDay)))
        .get();
    if (openOrders.isNotEmpty) {
      return ClosingValidationResult(
        canClose: false,
        reason: 'There are ${openOrders.length} unpaid order(s) remaining.\n'
            'Please complete or cancel all pending orders before closing.',
        failCode: ClosingFailCode.unpaidOrdersExist,
        openTabCount: openOrders.length,
      );
    }

    // 5. 매출 집계 (매출 없어도 마감 허용 - issue #13)
    final aggregation = await _dao.aggregateSalesForDate(date);
    final finalAggregation = aggregation ??
        SalesAggregation(
          totalTransactions: 0,
          totalSales: 0,
          totalTax: 0,
          totalDiscount: 0,
          cashSales: 0,
          cardSales: 0,
          qrSales: 0,
          transferSales: 0,
          averageTransaction: 0,
        );

    return ClosingValidationResult(
      canClose: true,
      aggregation: finalAggregation,
      failCode: finalAggregation.totalTransactions == 0 ? ClosingFailCode.noSales : null,
      reason: finalAggregation.totalTransactions == 0 ? 'No sales for this date.' : null,
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
          message: validation.reason ?? 'Cannot perform closing.',
        );
      }

      // 2. 현재 직원 ID 확인
      final currentSession = _authNotifier.currentSession;
      if (currentSession == null) {
        return ClosingResult(
          success: false,
          message: 'Login required.',
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
        message: 'Closing completed successfully.',
      );
    } catch (e) {
      debugPrint('[ClosingService] Error: $e');
      final detail = e.toString().replaceFirst('Exception: ', '');
      return ClosingResult(
        success: false,
        message: 'Closing failed: $detail',
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
    return difference.abs() <= ClosingConstants.acceptableCashDifference;
  }
}

// ═══════════════════════════════════════════════════════
// 결과 모델
// ═══════════════════════════════════════════════════════

/// 마감 실패 원인 코드
enum ClosingFailCode {
  alreadyClosed,
  futureDate,
  openTabsExist,
  unpaidOrdersExist,
  noSales,
  notLoggedIn,
  unknown,
}

class ClosingValidationResult {
  final bool canClose;
  final String? reason;
  final SalesAggregation? aggregation;
  final ClosingFailCode? failCode;
  final int? openTabCount;

  ClosingValidationResult({
    required this.canClose,
    this.reason,
    this.aggregation,
    this.failCode,
    this.openTabCount,
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

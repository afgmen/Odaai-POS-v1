import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/daily_closing_dao.dart';
import '../../providers/daily_closing_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../providers/database_providers.dart';
import '../constants/closing_constants.dart';

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
      // TODO: Log error for debugging: $e
      return ClosingResult(
        success: false,
        message: '마감 처리 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
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

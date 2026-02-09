import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/loyalty_dao.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';

/// 로열티 서비스 Provider
final loyaltyServiceProvider = Provider<LoyaltyService>((ref) {
  final dao = ref.watch(loyaltyDaoProvider);
  return LoyaltyService(dao);
});

/// 로열티 DAO Provider
final loyaltyDaoProvider = Provider<LoyaltyDao>((ref) {
  return ref.watch(databaseProvider).loyaltyDao;
});

/// 로열티 비즈니스 로직
class LoyaltyService {
  final LoyaltyDao _dao;
  AppDatabase get _db => _dao.attachedDatabase as AppDatabase;

  LoyaltyService(this._dao);

  /// 판매 완료 시 포인트 자동 적립
  Future<PointEarnResult> earnPointsForSale({
    required int customerId,
    required int saleId,
    required double saleAmount,
    int? employeeId,
    double? promotionMultiplier,
  }) async {
    try {
      // 1. 고객의 현재 등급 조회
      final tier = await _dao.getCustomerTier(customerId);

      // 2. 적립률 계산
      final baseRate = tier.pointRate;
      final finalRate = baseRate * (promotionMultiplier ?? 1.0);

      // 3. 적립 포인트 계산 (소수점 버림)
      final pointsToEarn = (saleAmount * finalRate).floor();

      if (pointsToEarn <= 0) {
        return PointEarnResult(success: false, message: '적립 포인트가 0입니다');
      }

      // 4. 포인트 적립
      final metadata = promotionMultiplier != null && promotionMultiplier > 1.0
          ? '{"promotion_multiplier": $promotionMultiplier}'
          : null;

      await _dao.earnPoints(
        customerId: customerId,
        amount: pointsToEarn,
        description: '구매 적립 (판매 #$saleId)',
        saleId: saleId,
        employeeId: employeeId,
        metadata: metadata,
      );

      // 5. 등급 승급 확인
      final wasUpgraded = await _dao.checkAndUpgradeTier(customerId);

      // 6. 현재 포인트 조회
      final newBalance = await _getCustomerPoints(customerId);

      return PointEarnResult(
        success: true,
        pointsEarned: pointsToEarn,
        newBalance: newBalance,
        wasUpgraded: wasUpgraded,
        newTierCode: wasUpgraded ? (await _dao.getCustomerTier(customerId)).tierCode : null,
      );
    } catch (e) {
      return PointEarnResult(success: false, message: '적립 실패: $e');
    }
  }

  /// 포인트 사용 가능 여부 및 금액 검증
  Future<PointRedeemValidation> validatePointRedeem({
    required int customerId,
    required int pointsToUse,
    required double saleAmount,
  }) async {
    try {
      // 1. 고객 포인트 잔액 조회
      final customerPoints = await _getCustomerPoints(customerId);

      // 2. 설정값 조회
      final settings = await _dao.getAllSettings();
      final minPoints = int.parse(settings['min_redeem_points'] ?? '1000');
      final maxPercent = int.parse(settings['max_redeem_percent'] ?? '50');
      final pointUnit = int.parse(settings['point_unit'] ?? '100');

      // 3. 검증
      if (pointsToUse < minPoints) {
        return PointRedeemValidation(
          isValid: false,
          message: '최소 ${minPoints}P 이상 사용 가능합니다',
        );
      }

      if (pointsToUse > customerPoints) {
        return PointRedeemValidation(
          isValid: false,
          message: '보유 포인트가 부족합니다 (보유: ${customerPoints}P)',
        );
      }

      if (pointsToUse % pointUnit != 0) {
        return PointRedeemValidation(
          isValid: false,
          message: '${pointUnit}P 단위로 사용 가능합니다',
        );
      }

      final maxAllowedPoints = (saleAmount * maxPercent / 100).floor();
      if (pointsToUse > maxAllowedPoints) {
        return PointRedeemValidation(
          isValid: false,
          message: '결제 금액의 ${maxPercent}%까지 사용 가능합니다 (최대: ${maxAllowedPoints}P)',
        );
      }

      return PointRedeemValidation(
        isValid: true,
        discountAmount: pointsToUse.toDouble(), // 1P = 1원
      );
    } catch (e) {
      return PointRedeemValidation(isValid: false, message: '검증 실패: $e');
    }
  }

  /// 포인트 사용
  Future<PointRedeemResult> redeemPoints({
    required int customerId,
    required int pointsToUse,
    required int saleId,
    int? employeeId,
  }) async {
    try {
      final success = await _dao.redeemPoints(
        customerId: customerId,
        amount: pointsToUse,
        description: '구매 사용 (판매 #$saleId)',
        saleId: saleId,
        employeeId: employeeId,
      );

      if (!success) {
        return PointRedeemResult(success: false, message: '포인트 사용 실패');
      }

      final newBalance = await _getCustomerPoints(customerId);

      return PointRedeemResult(
        success: true,
        pointsRedeemed: pointsToUse,
        newBalance: newBalance,
      );
    } catch (e) {
      return PointRedeemResult(success: false, message: '사용 실패: $e');
    }
  }

  /// 생일 보너스 포인트 지급
  Future<void> grantBirthdayBonus(int customerId, int employeeId) async {
    final settings = await _dao.getAllSettings();
    final bonusPoints = int.parse(settings['birthday_bonus_points'] ?? '1000');

    await _dao.earnPoints(
      customerId: customerId,
      amount: bonusPoints,
      description: '생일 축하 보너스',
      employeeId: employeeId,
    );
  }

  /// 관리자 포인트 조정
  Future<void> adjustPoints({
    required int customerId,
    required int amount,
    required String reason,
    required int employeeId,
  }) async {
    await _dao.adjustPoints(
      customerId: customerId,
      amount: amount,
      reason: reason,
      employeeId: employeeId,
    );
  }

  /// 고객 포인트 조회 (헬퍼)
  Future<int> _getCustomerPoints(int customerId) async {
    final customer = await _db.customersDao.getCustomerById(customerId);
    return customer?.points ?? 0;
  }

  /// 포인트 이력 조회
  Future<List<PointTransaction>> getPointHistory(int customerId, {int limit = 50}) {
    return _dao.getPointHistory(customerId, limit: limit);
  }

  /// 전체 등급 조회
  Future<List<MembershipTier>> getAllTiers() {
    return _dao.getAllTiers();
  }

  /// 고객 등급 조회
  Future<MembershipTier> getCustomerTier(int customerId) {
    return _dao.getCustomerTier(customerId);
  }

  /// 다음 등급까지 필요 금액
  Future<int?> getAmountToNextTier(int customerId) {
    return _dao.getAmountToNextTier(customerId);
  }

  /// 오늘 적립 포인트 통계
  Future<int> getTotalEarnedToday() {
    return _dao.getTotalEarnedToday();
  }

  /// 오늘 사용 포인트 통계
  Future<int> getTotalRedeemedToday() {
    return _dao.getTotalRedeemedToday();
  }

  /// 등급별 고객 수
  Future<Map<String, int>> getCustomerCountByTier() {
    return _dao.getCustomerCountByTier();
  }

  /// 전체 유효 포인트
  Future<int> getTotalActivePoints() {
    return _dao.getTotalActivePoints();
  }

  /// 전체 설정 조회
  Future<Map<String, String>> getAllSettings() {
    return _dao.getAllSettings();
  }
}

// ═══════════════════════════════════════════════════════
// 결과 모델
// ═══════════════════════════════════════════════════════

class PointEarnResult {
  final bool success;
  final int? pointsEarned;
  final int? newBalance;
  final bool wasUpgraded;
  final String? newTierCode;
  final String? message;

  PointEarnResult({
    required this.success,
    this.pointsEarned,
    this.newBalance,
    this.wasUpgraded = false,
    this.newTierCode,
    this.message,
  });
}

class PointRedeemValidation {
  final bool isValid;
  final double? discountAmount;
  final String? message;

  PointRedeemValidation({
    required this.isValid,
    this.discountAmount,
    this.message,
  });
}

class PointRedeemResult {
  final bool success;
  final int? pointsRedeemed;
  final int? newBalance;
  final String? message;

  PointRedeemResult({
    required this.success,
    this.pointsRedeemed,
    this.newBalance,
    this.message,
  });
}

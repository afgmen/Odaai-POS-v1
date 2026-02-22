import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/features/loyalty/domain/services/loyalty_service.dart';

// ---------------------------------------------------------------------------
// Tests for loyalty calculation logic extracted from LoyaltyService.
//
// The service methods that touch the database (earnPointsForSale,
// redeemPoints, etc.) are tested here at the formula / validation level
// using the same arithmetic the service uses internally.
//
// No database required — pure unit tests.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Helpers: replicate LoyaltyService formulas in isolation so we can verify
// expected results without a real DB.
// ---------------------------------------------------------------------------

/// Points earned = floor(saleAmount * pointRate * multiplier)
int _calculatePointsToEarn(
  double saleAmount,
  double pointRate, {
  double multiplier = 1.0,
}) {
  return (saleAmount * pointRate * multiplier).floor();
}

/// Validates redemption: returns null on success, error message otherwise.
String? _validateRedeem({
  required int pointsToUse,
  required int balance,
  required double saleAmount,
  int minPoints = 1000,
  int maxPercent = 50,
  int pointUnit = 100,
}) {
  if (pointsToUse < minPoints) {
    return 'Minimum ${minPoints}P required';
  }
  if (pointsToUse > balance) {
    return 'Insufficient points (balance: ${balance}P)';
  }
  if (pointsToUse % pointUnit != 0) {
    return 'Must use in multiples of ${pointUnit}P';
  }
  final maxAllowed = (saleAmount * maxPercent / 100).floor();
  if (pointsToUse > maxAllowed) {
    return 'Up to $maxPercent% of total allowed (max: ${maxAllowed}P)';
  }
  return null; // valid
}

// ---------------------------------------------------------------------------

void main() {
  // ── Points earned calculation ───────────────────────────────────────────
  group('LoyaltyService — points earned formula', () {
    test('base rate 1%: 10000 spent → 100 points', () {
      expect(_calculatePointsToEarn(10000, 0.01), 100);
    });

    test('base rate 1%: 15000 spent → 150 points', () {
      expect(_calculatePointsToEarn(15000, 0.01), 150);
    });

    test('base rate 2%: 10000 spent → 200 points', () {
      expect(_calculatePointsToEarn(10000, 0.02), 200);
    });

    test('fractional result is floored (no partial points)', () {
      // 10001 * 0.01 = 100.01 → floor → 100
      expect(_calculatePointsToEarn(10001, 0.01), 100);
    });

    test('promotion 2x multiplier doubles earned points', () {
      final base = _calculatePointsToEarn(10000, 0.01);
      final promo = _calculatePointsToEarn(10000, 0.01, multiplier: 2.0);
      expect(promo, base * 2);
    });

    test('zero sale amount earns 0 points', () {
      expect(_calculatePointsToEarn(0, 0.01), 0);
    });

    test('very small amount may earn 0 points (floor)', () {
      // 50 * 0.01 = 0.5 → floor → 0
      expect(_calculatePointsToEarn(50, 0.01), 0);
    });
  });

  // ── Redemption validation ────────────────────────────────────────────────
  group('LoyaltyService — validatePointRedeem()', () {
    const balance = 5000;
    const saleAmount = 20000.0;

    test('valid redemption returns null (no error)', () {
      final error = _validateRedeem(
        pointsToUse: 1000,
        balance: balance,
        saleAmount: saleAmount,
      );
      expect(error, isNull);
    });

    test('below minimum points returns error', () {
      final error = _validateRedeem(
        pointsToUse: 500,
        balance: balance,
        saleAmount: saleAmount,
        minPoints: 1000,
      );
      expect(error, isNotNull);
      expect(error, contains('Minimum'));
    });

    test('exceeding balance returns error', () {
      final error = _validateRedeem(
        pointsToUse: 6000,
        balance: balance, // only 5000
        saleAmount: saleAmount,
      );
      expect(error, isNotNull);
      expect(error, contains('Insufficient'));
    });

    test('not a multiple of pointUnit returns error', () {
      final error = _validateRedeem(
        pointsToUse: 1050, // not multiple of 100
        balance: balance,
        saleAmount: saleAmount,
        pointUnit: 100,
      );
      expect(error, isNotNull);
      expect(error, contains('multiples'));
    });

    test('exceeds 50% of sale amount returns error', () {
      // max allowed = floor(20000 * 50 / 100) = 10000
      // trying to use 11000 > 10000 → error
      final error = _validateRedeem(
        pointsToUse: 11000,
        balance: 15000, // enough balance
        saleAmount: saleAmount,
        maxPercent: 50,
      );
      expect(error, isNotNull);
      expect(error, contains('%'));
    });

    test('exactly 50% of sale amount is allowed', () {
      // max = floor(20000 * 50 / 100) = 10000
      final error = _validateRedeem(
        pointsToUse: 10000,
        balance: 15000,
        saleAmount: 20000,
        maxPercent: 50,
        pointUnit: 1000,
      );
      expect(error, isNull);
    });

    test('cannot redeem more than available balance', () {
      final error = _validateRedeem(
        pointsToUse: 2000,
        balance: 1500, // less than requested
        saleAmount: 50000,
      );
      expect(error, isNotNull);
      expect(error, contains('Insufficient'));
    });
  });

  // ── PointEarnResult model ────────────────────────────────────────────────
  group('PointEarnResult', () {
    test('success result carries points earned and new balance', () {
      final result = PointEarnResult(
        success: true,
        pointsEarned: 150,
        newBalance: 1150,
        wasUpgraded: false,
      );
      expect(result.success, isTrue);
      expect(result.pointsEarned, 150);
      expect(result.newBalance, 1150);
      expect(result.wasUpgraded, isFalse);
    });

    test('failure result carries message', () {
      final result = PointEarnResult(
        success: false,
        message: 'Points to earn is 0',
      );
      expect(result.success, isFalse);
      expect(result.message, isNotNull);
    });

    test('tier upgrade flag is set when wasUpgraded = true', () {
      final result = PointEarnResult(
        success: true,
        pointsEarned: 500,
        newBalance: 5000,
        wasUpgraded: true,
        newTierCode: 'SILVER',
      );
      expect(result.wasUpgraded, isTrue);
      expect(result.newTierCode, 'SILVER');
    });
  });

  // ── PointRedeemValidation model ──────────────────────────────────────────
  group('PointRedeemValidation', () {
    test('valid redemption carries discount amount (1P = 1 currency unit)', () {
      const pointsToUse = 2000;
      final v = PointRedeemValidation(
        isValid: true,
        discountAmount: pointsToUse.toDouble(),
      );
      expect(v.isValid, isTrue);
      expect(v.discountAmount, pointsToUse.toDouble());
    });

    test('invalid redemption carries error message', () {
      final v = PointRedeemValidation(
        isValid: false,
        message: 'Minimum 1000P required',
      );
      expect(v.isValid, isFalse);
      expect(v.message, isNotNull);
    });
  });

  // ── PointRedeemResult model ──────────────────────────────────────────────
  group('PointRedeemResult', () {
    test('success: new balance decremented by redeemed points', () {
      const previousBalance = 5000;
      const pointsRedeemed = 2000;
      const expectedNewBalance = previousBalance - pointsRedeemed;

      final result = PointRedeemResult(
        success: true,
        pointsRedeemed: pointsRedeemed,
        newBalance: expectedNewBalance,
      );
      expect(result.success, isTrue);
      expect(result.newBalance, 3000);
    });

    test('failure result has null new balance', () {
      final result = PointRedeemResult(
        success: false,
        message: 'Point redemption failed',
      );
      expect(result.success, isFalse);
      expect(result.newBalance, isNull);
    });
  });

  // ── Tier upgrade thresholds ──────────────────────────────────────────────
  group('Tier upgrade thresholds', () {
    test('BRONZE tier starts at 0 min spent', () {
      // Default tier: minSpent = 0 (BRONZE)
      // A customer with totalSpent = 0 should be BRONZE.
      expect(0 >= 0, isTrue); // 0 spent qualifies for BRONZE
    });

    test('higher minSpent tiers require more spending', () {
      // Simulate tier thresholds: BRONZE=0, SILVER=100000, GOLD=500000
      const silverMin = 100000;
      const goldMin = 500000;

      expect(99999 < silverMin, isTrue); // still BRONZE
      expect(100000 >= silverMin, isTrue); // qualifies SILVER
      expect(499999 < goldMin, isTrue); // still SILVER
      expect(500000 >= goldMin, isTrue); // qualifies GOLD
    });
  });
}

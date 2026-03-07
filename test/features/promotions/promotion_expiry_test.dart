import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';
import 'package:oda_pos/features/promotions/providers/promotions_provider.dart';

/// B-065: Promotion Expiry Tests
void main() {
  late AppDatabase db;
  late PromotionService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = PromotionService(db);
    });

  tearDown(() async {
    await db.close();
  });

  group('Promotion Expiry Check', () {
    test('should return active promotion before expiry date', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      final promo = await service.createPromotion(
        name: 'Test Promo',
        type: 'percentOff',
        value: 10.0,
        endDate: tomorrow,
      );

      final applicable = await service.getApplicablePromotions(1);

      expect(applicable.length, 1);
      expect(applicable.first.id, promo.id);
    });

    test('should return active promotion on expiry date (same day)', () async {
      final today = DateTime.now();

      final promo = await service.createPromotion(
        name: 'Today Promo',
        type: 'percentOff',
        value: 15.0,
        endDate: today,
      );

      final applicable = await service.getApplicablePromotions(1);

      expect(applicable.length, 1);
      expect(applicable.first.id, promo.id);
    });

    test('should NOT return expired promotion', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      await service.createPromotion(
        name: 'Expired Promo',
        type: 'percentOff',
        value: 20.0,
        endDate: yesterday,
      );

      final applicable = await service.getApplicablePromotions(1);

      expect(applicable.length, 0);
    });

    test('should return promotion with null endDate (unlimited)', () async {
      final promo = await service.createPromotion(
        name: 'Unlimited Promo',
        type: 'percentOff',
        value: 25.0,
        endDate: null,
      );

      final applicable = await service.getApplicablePromotions(1);

      expect(applicable.length, 1);
      expect(applicable.first.id, promo.id);
    });

    test('should filter by startDate as well', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final nextWeek = DateTime.now().add(const Duration(days: 7));

      // Future promotion (not started yet)
      await service.createPromotion(
        name: 'Future Promo',
        type: 'percentOff',
        value: 30.0,
        startDate: tomorrow,
        endDate: nextWeek,
      );

      // Current promotion (already started)
      final currentPromo = await service.createPromotion(
        name: 'Current Promo',
        type: 'percentOff',
        value: 35.0,
        startDate: yesterday,
        endDate: nextWeek,
      );

      final applicable = await service.getApplicablePromotions(1);

      expect(applicable.length, 1);
      expect(applicable.first.id, currentPromo.id);
    });
  });

  group('Auto Expiry', () {
    test('should auto-disable expired promotions', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      await service.createPromotion(
        name: 'Expired 1',
        type: 'percentOff',
        value: 10.0,
        endDate: yesterday,
      );

      await service.createPromotion(
        name: 'Expired 2',
        type: 'percentOff',
        value: 20.0,
        endDate: yesterday,
      );

      final expiredCount = await service.expireOldPromotions();

      expect(expiredCount, 2);

      // Verify they are now inactive
      final allPromotions = await db.select(db.promotions).get();
      final activePromotions = allPromotions.where((p) => p.isActive).toList();

      expect(activePromotions.length, 0);
    });

    test('should not disable future promotions', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      await service.createPromotion(
        name: 'Future Promo',
        type: 'percentOff',
        value: 10.0,
        endDate: tomorrow,
      );

      final expiredCount = await service.expireOldPromotions();

      expect(expiredCount, 0);

      final allPromotions = await db.select(db.promotions).get();
      expect(allPromotions.first.isActive, true);
    });

    test('should not disable unlimited promotions', () async {
      await service.createPromotion(
        name: 'Unlimited Promo',
        type: 'percentOff',
        value: 10.0,
        endDate: null,
      );

      final expiredCount = await service.expireOldPromotions();

      expect(expiredCount, 0);

      final allPromotions = await db.select(db.promotions).get();
      expect(allPromotions.first.isActive, true);
    });
  });

  group('Active Promotions Query', () {
    test('should only return non-expired active promotions', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      // Expired
      await service.createPromotion(
        name: 'Expired',
        type: 'percentOff',
        value: 10.0,
        endDate: yesterday,
      );

      // Active and valid
      await service.createPromotion(
        name: 'Valid',
        type: 'percentOff',
        value: 20.0,
        endDate: tomorrow,
      );

      // Manually query with same logic as activePromotionsProvider
      final now = DateTime.now();
      final activePromotions = await (db.select(db.promotions)
            ..where((p) =>
                p.isActive.equals(true) &
                (p.endDate.isNull() | p.endDate.isBiggerOrEqualValue(now))))
          .get();

      expect(activePromotions.length, 1);
      expect(activePromotions.first.name, 'Valid');
    });
  });
}

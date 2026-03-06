import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:oda_pos/database/app_database.dart';
import 'package:oda_pos/features/promotions/providers/promotions_provider.dart';

void main() {
  group('B-065: Promotion Auto-Expiry', () {
    late AppDatabase db;
    late PromotionService service;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      service = PromotionService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Expired promotion should be set to inactive', () async {
      // Create a promotion that ended yesterday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      
      await service.createPromotion(
        name: 'Expired Promo',
        type: 'percentOff',
        value: 10,
        endDate: yesterday,
      );

      // Check that it's still active (before expiry check)
      final beforeExpiry = await db.select(db.promotions).getSingle();
      expect(beforeExpiry.isActive, true);

      // Run expiry check
      final expiredCount = await service.expireOldPromotions();

      // Should have expired 1 promotion
      expect(expiredCount, 1);

      // Verify it's now inactive
      final afterExpiry = await db.select(db.promotions).getSingle();
      expect(afterExpiry.isActive, false);
    });

    test('Active promotion with future end date should NOT expire', () async {
      // Create a promotion that ends tomorrow
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      
      await service.createPromotion(
        name: 'Future Promo',
        type: 'percentOff',
        value: 15,
        endDate: tomorrow,
      );

      // Run expiry check
      final expiredCount = await service.expireOldPromotions();

      // Should NOT expire
      expect(expiredCount, 0);

      // Verify it's still active
      final promo = await db.select(db.promotions).getSingle();
      expect(promo.isActive, true);
    });

    test('Promotion with no end date should NOT expire', () async {
      // Create a promotion with no end date (永久)
      await service.createPromotion(
        name: 'Permanent Promo',
        type: 'amountOff',
        value: 5000,
        endDate: null,
      );

      // Run expiry check
      final expiredCount = await service.expireOldPromotions();

      // Should NOT expire
      expect(expiredCount, 0);

      // Verify it's still active
      final promo = await db.select(db.promotions).getSingle();
      expect(promo.isActive, true);
    });

    test('Multiple expired promotions should all be deactivated', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));

      // Create 3 expired promotions
      await service.createPromotion(
        name: 'Expired 1',
        type: 'percentOff',
        value: 10,
        endDate: yesterday,
      );

      await service.createPromotion(
        name: 'Expired 2',
        type: 'percentOff',
        value: 20,
        endDate: twoDaysAgo,
      );

      await service.createPromotion(
        name: 'Expired 3',
        type: 'amountOff',
        value: 3000,
        endDate: weekAgo,
      );

      // Run expiry check
      final expiredCount = await service.expireOldPromotions();

      // Should have expired all 3
      expect(expiredCount, 3);

      // Verify all are inactive
      final allPromos = await db.select(db.promotions).get();
      expect(allPromos.every((p) => p.isActive == false), true);
    });

    test('Mix of expired and active promotions', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      // 2 expired
      await service.createPromotion(
        name: 'Expired 1',
        type: 'percentOff',
        value: 10,
        endDate: yesterday,
      );

      await service.createPromotion(
        name: 'Expired 2',
        type: 'percentOff',
        value: 15,
        endDate: yesterday,
      );

      // 2 active
      await service.createPromotion(
        name: 'Active 1',
        type: 'amountOff',
        value: 2000,
        endDate: tomorrow,
      );

      await service.createPromotion(
        name: 'Active 2',
        type: 'buy1get1',
        value: 0,
        endDate: null,
      );

      // Run expiry check
      final expiredCount = await service.expireOldPromotions();

      // Should have expired 2
      expect(expiredCount, 2);

      // Verify counts
      final allPromos = await db.select(db.promotions).get();
      final activeCount = allPromos.where((p) => p.isActive).length;
      final inactiveCount = allPromos.where((p) => !p.isActive).length;

      expect(activeCount, 2);
      expect(inactiveCount, 2);
    });

    test('Already inactive expired promotion should not be counted', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      // Create expired promotion
      final id = await db.into(db.promotions).insert(
        PromotionsCompanion.insert(
          name: 'Already Inactive',
          type: 'percentOff',
          value: const Value(10),
          endDate: Value(yesterday),
          isActive: const Value(false), // Already inactive
        ),
      );

      // Run expiry check
      final expiredCount = await service.expireOldPromotions();

      // Should NOT count already inactive ones
      expect(expiredCount, 0);
    });

    test('expireOldPromotions should be idempotent', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      await service.createPromotion(
        name: 'Expired Promo',
        type: 'percentOff',
        value: 10,
        endDate: yesterday,
      );

      // First run
      final firstRun = await service.expireOldPromotions();
      expect(firstRun, 1);

      // Second run (should not double-count)
      final secondRun = await service.expireOldPromotions();
      expect(secondRun, 0);

      // Verify still only 1 promotion and it's inactive
      final allPromos = await db.select(db.promotions).get();
      expect(allPromos.length, 1);
      expect(allPromos.first.isActive, false);
    });
  });
}

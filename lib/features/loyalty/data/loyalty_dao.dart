import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/point_transactions.dart';
import '../../../database/tables/membership_tiers.dart';
import '../../../database/tables/loyalty_settings.dart';
import '../../../database/tables/sync_queue.dart';
import '../../../database/tables/sales.dart';

part 'loyalty_dao.g.dart';

@DriftAccessor(tables: [
  PointTransactions,
  MembershipTiers,
  LoyaltySettings,
  Customers,
  Sales,
])
class LoyaltyDao extends DatabaseAccessor<AppDatabase> with _$LoyaltyDaoMixin {
  LoyaltyDao(super.db);

  // ═══════════════════════════════════════════════════════
  // 포인트 트랜잭션
  // ═══════════════════════════════════════════════════════

  /// 포인트 적립
  Future<int> earnPoints({
    required int customerId,
    required int amount,
    required String description,
    int? saleId,
    int? employeeId,
    String? metadata,
  }) async {
    return await transaction(() async {
      // 1. 현재 포인트 조회
      final customer = await (select(db.customers)
            ..where((c) => c.id.equals(customerId)))
          .getSingle();

      final newBalance = customer.points + amount;

      // 2. 트랜잭션 기록
      final txId = await into(pointTransactions).insert(
        PointTransactionsCompanion.insert(
          customerId: customerId,
          amount: amount,
          transactionType: 'earn',
          description: description,
          balanceAfter: newBalance,
          saleId: Value(saleId),
          employeeId: Value(employeeId),
          metadata: Value(metadata),
        ),
      );

      // 3. 고객 포인트 업데이트
      await (update(db.customers)..where((c) => c.id.equals(customerId))).write(
        CustomersCompanion(
          points: Value(newBalance),
          updatedAt: Value(DateTime.now()),
        ),
      );

      return txId;
    });
  }

  /// 포인트 사용
  Future<bool> redeemPoints({
    required int customerId,
    required int amount,
    required String description,
    int? saleId,
    int? employeeId,
  }) async {
    return await transaction(() async {
      // 1. 현재 포인트 조회
      final customer = await (select(db.customers)
            ..where((c) => c.id.equals(customerId)))
          .getSingle();

      // 2. 잔액 확인
      if (customer.points < amount) {
        return false;
      }

      final newBalance = customer.points - amount;

      // 3. 트랜잭션 기록 (음수로 저장)
      await into(pointTransactions).insert(
        PointTransactionsCompanion.insert(
          customerId: customerId,
          amount: -amount,
          transactionType: 'redeem',
          description: description,
          balanceAfter: newBalance,
          saleId: Value(saleId),
          employeeId: Value(employeeId),
        ),
      );

      // 4. 고객 포인트 업데이트
      await (update(db.customers)..where((c) => c.id.equals(customerId))).write(
        CustomersCompanion(
          points: Value(newBalance),
          updatedAt: Value(DateTime.now()),
        ),
      );

      return true;
    });
  }

  /// 관리자 포인트 조정
  Future<void> adjustPoints({
    required int customerId,
    required int amount,
    required String reason,
    required int employeeId,
  }) async {
    await transaction(() async {
      final customer = await (select(db.customers)
            ..where((c) => c.id.equals(customerId)))
          .getSingle();

      final newBalance = customer.points + amount;

      await into(pointTransactions).insert(
        PointTransactionsCompanion.insert(
          customerId: customerId,
          amount: amount,
          transactionType: 'adjust',
          description: '관리자 조정: $reason',
          balanceAfter: newBalance,
          employeeId: Value(employeeId),
        ),
      );

      await (update(db.customers)..where((c) => c.id.equals(customerId))).write(
        CustomersCompanion(
          points: Value(newBalance),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  /// 고객 포인트 이력 조회
  Future<List<PointTransaction>> getPointHistory(int customerId, {int limit = 50}) {
    return (select(pointTransactions)
          ..where((pt) => pt.customerId.equals(customerId))
          ..orderBy([(pt) => OrderingTerm.desc(pt.createdAt)])
          ..limit(limit))
        .get();
  }

  /// 포인트 이력 스트림 (실시간)
  Stream<List<PointTransaction>> watchPointHistory(int customerId) {
    return (select(pointTransactions)
          ..where((pt) => pt.customerId.equals(customerId))
          ..orderBy([(pt) => OrderingTerm.desc(pt.createdAt)])
          ..limit(50))
        .watch();
  }

  /// 판매 ID로 포인트 트랜잭션 조회
  Future<PointTransaction?> getPointTransactionBySaleId(int saleId) {
    return (select(pointTransactions)
          ..where((pt) => pt.saleId.equals(saleId)))
        .getSingleOrNull();
  }

  // ═══════════════════════════════════════════════════════
  // 멤버십 등급
  // ═══════════════════════════════════════════════════════

  /// 모든 등급 조회 (정렬됨)
  Future<List<MembershipTier>> getAllTiers() {
    return (select(membershipTiers)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]))
        .get();
  }

  /// 등급 코드로 조회
  Future<MembershipTier?> getTierByCode(String tierCode) {
    return (select(membershipTiers)
          ..where((t) => t.tierCode.equals(tierCode)))
        .getSingleOrNull();
  }

  /// 누적 구매액 기반 등급 계산
  Future<MembershipTier> calculateTierForAmount(int totalSpent) async {
    final tiers = await getAllTiers();

    // 역순으로 정렬하여 가장 높은 등급부터 확인
    tiers.sort((a, b) => b.minSpent.compareTo(a.minSpent));

    for (final tier in tiers) {
      if (totalSpent >= tier.minSpent) {
        return tier;
      }
    }

    // 기본값: 첫 번째 등급 (Bronze)
    return tiers.last;
  }

  /// 고객 등급 자동 승급 확인 및 업데이트
  Future<bool> checkAndUpgradeTier(int customerId) async {
    return await transaction(() async {
      final customer = await (select(db.customers)
            ..where((c) => c.id.equals(customerId)))
          .getSingle();

      final newTier = await calculateTierForAmount(customer.totalSpent);

      // 등급이 변경되었는지 확인
      if (customer.membershipTier != newTier.tierCode) {
        await (update(db.customers)..where((c) => c.id.equals(customerId))).write(
          CustomersCompanion(
            membershipTier: Value(newTier.tierCode),
            updatedAt: Value(DateTime.now()),
          ),
        );
        return true; // 승급됨
      }

      return false; // 변경 없음
    });
  }

  /// 고객의 현재 등급 조회
  Future<MembershipTier> getCustomerTier(int customerId) async {
    final customer = await (select(db.customers)
          ..where((c) => c.id.equals(customerId)))
        .getSingle();

    final tier = await getTierByCode(customer.membershipTier);
    if (tier != null) return tier;

    // fallback: bronze
    return (await getTierByCode('bronze'))!;
  }

  /// 다음 등급까지 필요한 금액 계산
  Future<int?> getAmountToNextTier(int customerId) async {
    final customer = await (select(db.customers)
          ..where((c) => c.id.equals(customerId)))
        .getSingle();

    final allTiers = await getAllTiers();
    final currentTier = allTiers.firstWhere(
      (t) => t.tierCode == customer.membershipTier,
      orElse: () => allTiers.first,
    );

    // 다음 등급 찾기
    final nextTierIndex = allTiers.indexWhere((t) => t.displayOrder > currentTier.displayOrder);

    if (nextTierIndex == -1) {
      return null; // 이미 최고 등급
    }

    final nextTier = allTiers[nextTierIndex];
    return nextTier.minSpent - customer.totalSpent;
  }

  // ═══════════════════════════════════════════════════════
  // 로열티 설정
  // ═══════════════════════════════════════════════════════

  /// 설정값 조회
  Future<String?> getSetting(String key) async {
    final setting = await (select(loyaltySettings)
          ..where((s) => s.settingKey.equals(key)))
        .getSingleOrNull();
    return setting?.settingValue;
  }

  /// 설정값 업데이트
  Future<void> updateSetting(String key, String value) {
    return (update(loyaltySettings)..where((s) => s.settingKey.equals(key)))
        .write(LoyaltySettingsCompanion(
      settingValue: Value(value),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// 모든 설정 조회
  Future<Map<String, String>> getAllSettings() async {
    final settings = await select(loyaltySettings).get();
    return {for (var s in settings) s.settingKey: s.settingValue};
  }

  // ═══════════════════════════════════════════════════════
  // 통계 및 대시보드
  // ═══════════════════════════════════════════════════════

  /// 총 적립 포인트 (오늘)
  Future<int> getTotalEarnedToday() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0) as total FROM point_transactions '
      'WHERE transaction_type = ? AND created_at >= ? AND amount > 0',
      variables: [
        Variable.withString('earn'),
        Variable.withInt(startOfDay.millisecondsSinceEpoch),
      ],
    ).getSingle();

    return result.read<int>('total');
  }

  /// 총 사용 포인트 (오늘)
  Future<int> getTotalRedeemedToday() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final result = await customSelect(
      'SELECT COALESCE(ABS(SUM(amount)), 0) as total FROM point_transactions '
      'WHERE transaction_type = ? AND created_at >= ?',
      variables: [
        Variable.withString('redeem'),
        Variable.withInt(startOfDay.millisecondsSinceEpoch),
      ],
    ).getSingle();

    return result.read<int>('total');
  }

  /// 등급별 고객 수
  Future<Map<String, int>> getCustomerCountByTier() async {
    final results = await customSelect(
      'SELECT membership_tier, COUNT(*) as count FROM customers '
      'WHERE is_active = 1 GROUP BY membership_tier',
    ).get();

    return {
      for (var row in results)
        row.read<String>('membership_tier'): row.read<int>('count')
    };
  }

  /// 전체 유효 포인트 잔액
  Future<int> getTotalActivePoints() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(points), 0) as total FROM customers WHERE is_active = 1',
    ).getSingle();

    return result.read<int>('total');
  }
}

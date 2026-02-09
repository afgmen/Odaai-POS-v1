import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';
import '../data/loyalty_dao.dart';
import '../domain/services/loyalty_service.dart';

/// 고객 포인트 이력 (실시간)
final pointHistoryProvider = StreamProvider.family<List<PointTransaction>, int>((ref, customerId) {
  return ref.watch(loyaltyDaoProvider).watchPointHistory(customerId);
});

/// 고객 현재 등급
final customerTierProvider = FutureProvider.family<MembershipTier, int>((ref, customerId) {
  return ref.watch(loyaltyDaoProvider).getCustomerTier(customerId);
});

/// 다음 등급까지 필요 금액
final amountToNextTierProvider = FutureProvider.family<int?, int>((ref, customerId) {
  return ref.watch(loyaltyDaoProvider).getAmountToNextTier(customerId);
});

/// 모든 멤버십 등급
final allTiersProvider = FutureProvider<List<MembershipTier>>((ref) {
  return ref.watch(loyaltyDaoProvider).getAllTiers();
});

/// 로열티 설정
final loyaltySettingsProvider = FutureProvider<Map<String, String>>((ref) {
  return ref.watch(loyaltyDaoProvider).getAllSettings();
});

/// 등급별 고객 수 (대시보드용)
final customerCountByTierProvider = FutureProvider<Map<String, int>>((ref) {
  return ref.watch(loyaltyDaoProvider).getCustomerCountByTier();
});

/// 오늘 적립/사용 포인트 통계
final todayPointStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final service = ref.watch(loyaltyServiceProvider);
  final earned = await service.getTotalEarnedToday();
  final redeemed = await service.getTotalRedeemedToday();

  return {
    'earned': earned,
    'redeemed': redeemed,
  };
});

/// 전체 유효 포인트
final totalActivePointsProvider = FutureProvider<int>((ref) {
  return ref.watch(loyaltyServiceProvider).getTotalActivePoints();
});

/// 오늘의 생일 고객
final todayBirthdayCustomersProvider = FutureProvider<List<Customer>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.customersDao.getTodayBirthdayCustomers();
});

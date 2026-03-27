import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import '../../../database/daos/customers_dao.dart';
import '../../../providers/database_providers.dart';

/// 환불 DAO Provider
final refundsDaoProvider = Provider<CustomersDao>((ref) {
  return ref.watch(databaseProvider).customersDao;
});

/// 오늘 환불 목록 (실시간)
final todayRefundsProvider = StreamProvider<List<Refund>>((ref) {
  return ref.watch(refundsDaoProvider).watchTodayRefunds();
});

/// 특정 주문의 환불 이력
final saleRefundsProvider = FutureProvider.family<List<Refund>, int>((ref, saleId) {
  return ref.watch(refundsDaoProvider).getRefundsBySaleId(saleId);
});

/// 최근 완료된 주문 목록 (환불 대상 선택용) - 최근 30건
final recentCompletedSalesProvider = StreamProvider<List<Sale>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.sales)
        ..where((s) => s.status.equals('completed'))
        ..orderBy([(s) => OrderingTerm.desc(s.saleDate)])
        ..limit(30))
      .watch();
});

/// B-UAT: 기간별 환불 총액 스트림 Provider
/// dashboard에서 순 매출(총 매출 - 환불) 계산에 사용
final refundTotalProvider = StreamProvider.family<double, ({DateTime from, DateTime to})>((ref, range) {
  return ref.watch(refundsDaoProvider).watchTotalRefunds(range.from, range.to);
});

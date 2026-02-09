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

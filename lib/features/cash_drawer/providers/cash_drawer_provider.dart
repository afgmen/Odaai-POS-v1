import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import '../../../database/daos/customers_dao.dart';
import '../../../providers/database_providers.dart';

/// 시재 DAO Provider
final cashDrawerDaoProvider = Provider<CustomersDao>((ref) {
  return ref.watch(databaseProvider).customersDao;
});

/// 오늘 시재 로그 (실시간)
final todayCashLogsProvider = StreamProvider<List<CashDrawerLog>>((ref) {
  return ref.watch(cashDrawerDaoProvider).watchTodayLogs();
});

/// 현재 시재 잔액
final currentDrawerBalanceProvider = FutureProvider<double>((ref) {
  return ref.watch(cashDrawerDaoProvider).getCurrentDrawerBalance();
});

/// 오늘 개점 여부
final isTodayOpenedProvider = FutureProvider<bool>((ref) async {
  final log = await ref.watch(cashDrawerDaoProvider).getTodayOpenLog();
  return log != null;
});

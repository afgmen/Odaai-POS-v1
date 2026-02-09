import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../../../database/app_database.dart';
import '../../../database/daos/customers_dao.dart';
import '../../../providers/database_providers.dart';

/// 고객 DAO Provider
final customersDaoProvider = Provider<CustomersDao>((ref) {
  return ref.watch(databaseProvider).customersDao;
});

/// 전체 고객 목록 (실시간)
final allCustomersProvider = StreamProvider<List<Customer>>((ref) {
  return ref.watch(customersDaoProvider).watchAllCustomers();
});

/// 고객 검색
final customerSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  final query = ref.watch(customerSearchQueryProvider);
  final dao = ref.watch(customersDaoProvider);
  if (query.isEmpty) return dao.getAllCustomers();
  return dao.searchCustomers(query);
});

/// 선택된 고객
final selectedCustomerProvider = StateProvider<Customer?>((ref) => null);

/// 고객 구매 이력
final customerHistoryProvider = FutureProvider.family<List<Sale>, int>((ref, customerId) {
  return ref.watch(customersDaoProvider).getCustomerPurchaseHistory(customerId);
});

/// 고객 총 사용 금액
final customerTotalSpentProvider = FutureProvider.family<double, int>((ref, customerId) {
  return ref.watch(customersDaoProvider).getCustomerTotalSpent(customerId);
});

import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sync_queue.dart';
import '../tables/sales.dart';

part 'customers_dao.g.dart';

@DriftAccessor(tables: [Customers, Sales, SaleItems, CashDrawerLogs, Refunds, RefundItems])
class CustomersDao extends DatabaseAccessor<AppDatabase> with _$CustomersDaoMixin {
  CustomersDao(super.db);

  // ─── 고객 CRUD ────────────────────────────────────

  Future<int> createCustomer(CustomersCompanion entry) =>
      into(customers).insert(entry);

  Future<List<Customer>> getAllCustomers() =>
      (select(customers)..orderBy([(c) => OrderingTerm.asc(c.name)])).get();

  Stream<List<Customer>> watchAllCustomers() =>
      (select(customers)
            ..where((c) => c.isActive.equals(true))
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .watch();

  Future<Customer?> getCustomerById(int id) =>
      (select(customers)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<Customer?> getCustomerByPhone(String phone) =>
      (select(customers)..where((c) => c.phone.equals(phone))).getSingleOrNull();

  Future<List<Customer>> searchCustomers(String query) => (select(customers)
        ..where((c) =>
            c.name.like('%$query%') |
            c.phone.like('%$query%') |
            c.email.like('%$query%'))
        ..orderBy([(c) => OrderingTerm.asc(c.name)]))
      .get();

  Future<bool> updateCustomer(CustomersCompanion entry) =>
      update(customers).replace(entry);

  Future<void> deleteCustomer(int id) =>
      (update(customers)..where((c) => c.id.equals(id)))
          .write(const CustomersCompanion(isActive: Value(false)));

  // ─── 포인트 관리 ──────────────────────────────────

  Future<void> addPoints(int customerId, int pts) async {
    final customer = await getCustomerById(customerId);
    if (customer != null) {
      await (update(customers)..where((c) => c.id.equals(customerId)))
          .write(CustomersCompanion(points: Value(customer.points + pts)));
    }
  }

  Future<bool> usePoints(int customerId, int pts) async {
    final customer = await getCustomerById(customerId);
    if (customer != null && customer.points >= pts) {
      await (update(customers)..where((c) => c.id.equals(customerId)))
          .write(CustomersCompanion(points: Value(customer.points - pts)));
      return true;
    }
    return false;
  }

  // ─── 고객 구매 이력 ───────────────────────────────

  Future<List<Sale>> getCustomerPurchaseHistory(int customerId) =>
      (select(sales)
            ..where((s) => s.customerId.equals(customerId))
            ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
          .get();

  Future<double> getCustomerTotalSpent(int customerId) async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(total), 0) as total FROM sales WHERE customer_id = ?',
      variables: [Variable.withInt(customerId)],
    ).getSingle();
    return result.read<double>('total');
  }

  // ─── 시재 관리 (Cash Drawer) ──────────────────────

  Future<int> logCashDrawer(CashDrawerLogsCompanion entry) =>
      into(cashDrawerLogs).insert(entry);

  Future<List<CashDrawerLog>> getTodayLogs() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return (select(cashDrawerLogs)
          ..where((l) => l.createdAt.isBiggerOrEqualValue(startOfDay))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
        .get();
  }

  Stream<List<CashDrawerLog>> watchTodayLogs() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return (select(cashDrawerLogs)
          ..where((l) => l.createdAt.isBiggerOrEqualValue(startOfDay))
          ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
        .watch();
  }

  Future<double> getCurrentDrawerBalance() async {
    final logs = await getTodayLogs();
    if (logs.isEmpty) return 0;
    return logs.first.balanceAfter;
  }

  Future<CashDrawerLog?> getTodayOpenLog() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return (select(cashDrawerLogs)
          ..where((l) =>
              l.createdAt.isBiggerOrEqualValue(startOfDay) & l.type.equals('open'))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<CashDrawerLog>> getLogsByDateRange(DateTime from, DateTime to) =>
      (select(cashDrawerLogs)
            ..where((l) =>
                l.createdAt.isBiggerOrEqualValue(from) &
                l.createdAt.isSmallerOrEqualValue(to))
            ..orderBy([(l) => OrderingTerm.desc(l.createdAt)]))
          .get();

  // ─── 환불 관리 ────────────────────────────────────

  Future<int> createRefund(RefundsCompanion entry) =>
      into(refunds).insert(entry);

  Future<void> insertRefundItems(List<RefundItemsCompanion> items) async {
    await batch((b) => b.insertAll(refundItems, items));
  }

  Future<List<Refund>> getRefundsBySaleId(int saleId) =>
      (select(refunds)..where((r) => r.originalSaleId.equals(saleId))).get();

  Future<List<RefundItem>> getRefundItems(int refundId) =>
      (select(refundItems)..where((ri) => ri.refundId.equals(refundId))).get();

  Stream<List<Refund>> watchTodayRefunds() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return (select(refunds)
          ..where((r) => r.createdAt.isBiggerOrEqualValue(startOfDay))
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .watch();
  }

  // ─── 로열티 프로그램 (v5) ─────────────────────────────

  /// 누적 구매액 업데이트
  Future<void> updateTotalSpent(int customerId, int amount) async {
    final customer = await getCustomerById(customerId);
    if (customer != null) {
      await (update(customers)..where((c) => c.id.equals(customerId))).write(
        CustomersCompanion(
          totalSpent: Value(customer.totalSpent + amount),
          purchaseCount: Value(customer.purchaseCount + 1),
          lastPurchaseAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// 등급별 고객 조회
  Future<List<Customer>> getCustomersByTier(String tierCode) {
    return (select(customers)
          ..where((c) => c.membershipTier.equals(tierCode) & c.isActive.equals(true))
          ..orderBy([(c) => OrderingTerm.desc(c.totalSpent)]))
        .get();
  }

  /// 생일인 고객 조회 (오늘)
  Future<List<Customer>> getTodayBirthdayCustomers() async {
    final today = DateTime.now();
    final allCustomers = await (select(customers)
          ..where((c) => c.isActive.equals(true) & c.birthDate.isNotNull())
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();

    // 월-일만 비교
    return allCustomers.where((c) {
      if (c.birthDate == null) return false;
      return c.birthDate!.month == today.month && c.birthDate!.day == today.day;
    }).toList();
  }

  /// 고객 멤버십 등급 업데이트
  Future<void> updateMembershipTier(int customerId, String tierCode) {
    return (update(customers)..where((c) => c.id.equals(customerId))).write(
      CustomersCompanion(
        membershipTier: Value(tierCode),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

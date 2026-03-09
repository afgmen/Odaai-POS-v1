import 'package:drift/drift.dart';
import '../../../database/app_database.dart';

part 'refunds_dao.g.dart';

@DriftAccessor(tables: [Refunds, RefundItems, Sales])
class RefundsDao extends DatabaseAccessor<AppDatabase> with _$RefundsDaoMixin {
  RefundsDao(AppDatabase db) : super(db);

  Future<List<Refund>> getAllRefunds() {
    return (select(refunds)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])).get();
  }

  Future<List<Refund>> getTodayRefunds() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(refunds)..where((r) => r.createdAt.isBiggerOrEqualValue(startOfDay) & r.createdAt.isSmallerThanValue(endOfDay))).get();
  }

  Future<List<Sale>> searchSales({required String query, int limit = 20}) async {
    final q = query.trim().toLowerCase();
    return (select(sales)
      ..where((s) =>
        (s.saleNumber.lower().like('%' + q + '%')) |
        (s.customerName.lower().like('%' + q + '%')) |
        (s.total.equals(double.tryParse(query) ?? -1))
      )
      ..where((s) => s.status.equals('completed'))
      ..orderBy([(s) => OrderingTerm(expression: s.completedAt, mode: OrderingMode.desc)])
      ..limit(limit)
    ).get();
  }

  Future<int> createRefund(RefundsCompanion refund) {
    return into(refunds).insert(refund);
  }

  Future<void> insertRefundItems(List<RefundItemsCompanion> items) {
    return batch((batch) => batch.insertAll(refundItems, items, mode: InsertMode.insertOrIgnore));
  }
}

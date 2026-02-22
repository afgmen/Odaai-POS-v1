import 'package:drift/drift.dart';
import '../../../database/app_database.dart';
import '../../../database/tables/delivery_orders.dart';

part 'delivery_orders_dao.g.dart';

/// DAO for delivery orders — handles all local SQLite operations.
@DriftAccessor(tables: [DeliveryOrders])
class DeliveryOrdersDao extends DatabaseAccessor<AppDatabase>
    with _$DeliveryOrdersDaoMixin {
  DeliveryOrdersDao(super.db);

  // ──────────────────────────────────────────────
  // CREATE
  // ──────────────────────────────────────────────

  Future<int> insertOrder(DeliveryOrdersCompanion order) {
    return into(deliveryOrders).insert(order);
  }

  // ──────────────────────────────────────────────
  // READ — single
  // ──────────────────────────────────────────────

  Future<DeliveryOrder?> getOrderById(int id) {
    return (select(deliveryOrders)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<DeliveryOrder?> getOrderByPlatformId(String platformOrderId) {
    return (select(deliveryOrders)
          ..where((t) => t.platformOrderId.equals(platformOrderId)))
        .getSingleOrNull();
  }

  /// Find the delivery order linked to a KDS kitchen order.
  Future<DeliveryOrder?> getOrderByKitchenOrderId(int kitchenOrderId) {
    return (select(deliveryOrders)
          ..where((t) => t.kitchenOrderId.equals(kitchenOrderId)))
        .getSingleOrNull();
  }

  // ──────────────────────────────────────────────
  // READ — list / stream
  // ──────────────────────────────────────────────

  Future<List<DeliveryOrder>> getAllOrders() {
    return (select(deliveryOrders)
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Stream<List<DeliveryOrder>> watchAllOrders() {
    return (select(deliveryOrders)
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<DeliveryOrder>> watchActiveOrders() {
    return (select(deliveryOrders)
          ..where((t) => t.status.isIn([
                'NEW',
                'ACCEPTED',
                'PREPARING',
                'READY_FOR_PICKUP',
              ]))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<DeliveryOrder>> watchOrdersByStatus(String status) {
    return (select(deliveryOrders)
          ..where((t) => t.status.equals(status))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<DeliveryOrder>> watchOrdersByPlatform(String platform) {
    return (select(deliveryOrders)
          ..where((t) => t.platform.equals(platform))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<int> watchNewOrderCount() {
    final query = selectOnly(deliveryOrders)
      ..addColumns([deliveryOrders.id.count()])
      ..where(deliveryOrders.status.equals('NEW'));
    return query
        .map((row) => row.read(deliveryOrders.id.count()) ?? 0)
        .watchSingle();
  }

  // ──────────────────────────────────────────────
  // UPDATE
  // ──────────────────────────────────────────────

  Future<bool> updateStatus(int id, String newStatus) {
    return (update(deliveryOrders)..where((t) => t.id.equals(id)))
        .write(DeliveryOrdersCompanion(
          status: Value(newStatus),
          updatedAt: Value(DateTime.now()),
        ))
        .then((n) => n > 0);
  }

  Future<bool> updateDriverInfo(int id, String? driverInfoJson) {
    return (update(deliveryOrders)..where((t) => t.id.equals(id)))
        .write(DeliveryOrdersCompanion(
          driverInfoJson: Value(driverInfoJson),
          updatedAt: Value(DateTime.now()),
        ))
        .then((n) => n > 0);
  }

  Future<bool> linkKitchenOrder(int deliveryOrderId, int kitchenOrderId) {
    return (update(deliveryOrders)
          ..where((t) => t.id.equals(deliveryOrderId)))
        .write(DeliveryOrdersCompanion(
          kitchenOrderId: Value(kitchenOrderId),
          updatedAt: Value(DateTime.now()),
        ))
        .then((n) => n > 0);
  }

  // ──────────────────────────────────────────────
  // DELETE
  // ──────────────────────────────────────────────

  Future<int> deleteOrder(int id) {
    return (delete(deliveryOrders)..where((t) => t.id.equals(id))).go();
  }

  Future<int> cleanupOldCompletedOrders({int daysOld = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: daysOld));
    return (delete(deliveryOrders)
          ..where((t) =>
              t.status.isIn(['COMPLETED', 'CANCELLED']) &
              t.updatedAt.isSmallerThanValue(cutoff)))
        .go();
  }

  // ──────────────────────────────────────────────
  // STATISTICS
  // ──────────────────────────────────────────────

  Future<int> countByStatus(String status) {
    final query = selectOnly(deliveryOrders)
      ..addColumns([deliveryOrders.id.count()])
      ..where(deliveryOrders.status.equals(status));
    return query
        .map((row) => row.read(deliveryOrders.id.count()) ?? 0)
        .getSingle();
  }

  Future<int> countByPlatform(String platform) {
    final query = selectOnly(deliveryOrders)
      ..addColumns([deliveryOrders.id.count()])
      ..where(deliveryOrders.platform.equals(platform));
    return query
        .map((row) => row.read(deliveryOrders.id.count()) ?? 0)
        .getSingle();
  }

  // ──────────────────────────────────────────────
  // REPORT QUERIES
  // ──────────────────────────────────────────────

  /// Count non-cancelled orders per platform in a date range.
  Future<Map<String, int>> countByPlatformInRange(
      DateTime from, DateTime to) async {
    final query = selectOnly(deliveryOrders)
      ..addColumns([deliveryOrders.platform, deliveryOrders.id.count()])
      ..where(deliveryOrders.createdAt.isBetweenValues(from, to) &
          deliveryOrders.status.isNotIn(['CANCELLED']))
      ..groupBy([deliveryOrders.platform]);

    final rows = await query.get();
    final result = <String, int>{};
    for (final row in rows) {
      final platform = row.read(deliveryOrders.platform) ?? '';
      final count = row.read(deliveryOrders.id.count()) ?? 0;
      result[platform] = count;
    }
    return result;
  }

  /// Total revenue per platform in a date range (non-cancelled).
  Future<Map<String, double>> revenueByPlatformInRange(
      DateTime from, DateTime to) async {
    final query = selectOnly(deliveryOrders)
      ..addColumns([deliveryOrders.platform, deliveryOrders.totalAmount.sum()])
      ..where(deliveryOrders.createdAt.isBetweenValues(from, to) &
          deliveryOrders.status.isNotIn(['CANCELLED']))
      ..groupBy([deliveryOrders.platform]);

    final rows = await query.get();
    final result = <String, double>{};
    for (final row in rows) {
      final platform = row.read(deliveryOrders.platform) ?? '';
      final sum = row.read(deliveryOrders.totalAmount.sum()) ?? 0.0;
      result[platform] = sum;
    }
    return result;
  }

  /// Count orders with a specific status in a date range.
  Future<int> countByStatusInRange(
      DateTime from, DateTime to, String status) async {
    final query = selectOnly(deliveryOrders)
      ..addColumns([deliveryOrders.id.count()])
      ..where(deliveryOrders.createdAt.isBetweenValues(from, to) &
          deliveryOrders.status.equals(status));
    return query
        .map((row) => row.read(deliveryOrders.id.count()) ?? 0)
        .getSingle();
  }

  /// Average prep time in minutes for COMPLETED orders in a date range.
  Future<double> averagePrepMinutes(DateTime from, DateTime to) async {
    final completedOrders = await (select(deliveryOrders)
          ..where((t) =>
              t.createdAt.isBetweenValues(from, to) &
              t.status.equals('COMPLETED')))
        .get();

    if (completedOrders.isEmpty) return 0;

    final totalMinutes = completedOrders.fold<double>(0, (sum, o) {
      final diff = o.updatedAt.difference(o.createdAt).inSeconds / 60.0;
      return sum + diff;
    });
    return totalMinutes / completedOrders.length;
  }

  /// Daily order counts and revenue per platform for the chart.
  Future<List<DeliveryDailyPlatformRow>> getDailyOrdersByPlatform(
      DateTime from, DateTime to) async {
    final orders = await (select(deliveryOrders)
          ..where((t) =>
              t.createdAt.isBetweenValues(from, to) &
              t.status.isNotIn(['CANCELLED'])))
        .get();

    // Group in Dart (avoids complex raw SQL grouping for cross-platform compat)
    final Map<String, Map<String, _Agg>> grouped = {};
    for (final o in orders) {
      final dateKey =
          '${o.createdAt.year}-${o.createdAt.month.toString().padLeft(2, '0')}'
          '-${o.createdAt.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(dateKey, () => {});
      final platMap = grouped[dateKey]!;
      platMap.putIfAbsent(o.platform, () => _Agg());
      platMap[o.platform]!.count++;
      platMap[o.platform]!.revenue += o.totalAmount;
    }

    final rows = <DeliveryDailyPlatformRow>[];
    for (final dateKey in grouped.keys) {
      final parts = dateKey.split('-');
      final date = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      for (final entry in grouped[dateKey]!.entries) {
        rows.add(DeliveryDailyPlatformRow(
          date: date,
          platform: entry.key,
          orderCount: entry.value.count,
          revenue: entry.value.revenue,
        ));
      }
    }
    rows.sort((a, b) => a.date.compareTo(b.date));
    return rows;
  }
}

// ──────────────────────────────────────────────
// Helper classes for report queries
// ──────────────────────────────────────────────

class _Agg {
  int count = 0;
  double revenue = 0;
}

/// Row returned by [DeliveryOrdersDao.getDailyOrdersByPlatform].
class DeliveryDailyPlatformRow {
  final DateTime date;
  final String platform;
  final int orderCount;
  final double revenue;

  const DeliveryDailyPlatformRow({
    required this.date,
    required this.platform,
    required this.orderCount,
    required this.revenue,
  });
}

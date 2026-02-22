import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/delivery_orders_dao.dart';
import '../../data/delivery_orders_providers.dart';
import '../../../reports/providers/reports_provider.dart';

// ──────────────────────────────────────────────
// Models
// ──────────────────────────────────────────────

/// Aggregated delivery stats for a time period.
class DeliveryReportData {
  final int totalOrders;
  final double totalRevenue;
  final int grabOrders;
  final double grabRevenue;
  final int shopeeFoodOrders;
  final double shopeeFoodRevenue;
  final int manualOrders;
  final double manualRevenue;
  final int cancelledOrders;
  final double averagePrepMinutes;

  const DeliveryReportData({
    required this.totalOrders,
    required this.totalRevenue,
    required this.grabOrders,
    required this.grabRevenue,
    required this.shopeeFoodOrders,
    required this.shopeeFoodRevenue,
    required this.manualOrders,
    required this.manualRevenue,
    required this.cancelledOrders,
    required this.averagePrepMinutes,
  });

  /// Delivery revenue as a fraction of [dineInRevenue] (0.0 – 1.0+).
  double deliveryFraction(double dineInRevenue) {
    final total = dineInRevenue + totalRevenue;
    if (total <= 0) return 0;
    return totalRevenue / total;
  }

  static const empty = DeliveryReportData(
    totalOrders: 0,
    totalRevenue: 0,
    grabOrders: 0,
    grabRevenue: 0,
    shopeeFoodOrders: 0,
    shopeeFoodRevenue: 0,
    manualOrders: 0,
    manualRevenue: 0,
    cancelledOrders: 0,
    averagePrepMinutes: 0,
  );
}

/// Per-platform daily row for the bar chart.
class DeliveryDailyRow {
  final DateTime date;
  final int orderCount;
  final double revenue;
  final String platform;

  const DeliveryDailyRow({
    required this.date,
    required this.orderCount,
    required this.revenue,
    required this.platform,
  });
}

// ──────────────────────────────────────────────
// Providers
// ──────────────────────────────────────────────

/// Aggregated delivery report for the currently selected date range.
final deliveryReportProvider = FutureProvider<DeliveryReportData>((ref) async {
  final dao = ref.watch(deliveryOrdersDaoProvider);
  final range = ref.watch(reportDateRangeProvider);
  return _buildReport(dao, range.from, range.to);
});

/// Per-platform daily data for the stacked bar chart.
final deliveryDailyChartProvider =
    FutureProvider<List<DeliveryDailyRow>>((ref) async {
  final dao = ref.watch(deliveryOrdersDaoProvider);
  final range = ref.watch(reportDateRangeProvider);
  return _buildDailyRows(dao, range.from, range.to);
});

// ──────────────────────────────────────────────
// Query helpers
// ──────────────────────────────────────────────

Future<DeliveryReportData> _buildReport(
  DeliveryOrdersDao dao,
  DateTime from,
  DateTime to,
) async {
  // All non-cancelled orders in range
  final counts = await _countByPlatformInRange(dao, from, to);
  final revenue = await _revenueByPlatformInRange(dao, from, to);
  final cancelledCount = await _countByStatusInRange(dao, from, to, 'CANCELLED');

  final grabOrders = counts['grab'] ?? 0;
  final shopeeFoodOrders = counts['shopeefood'] ?? 0;
  final manualOrders = counts['manual'] ?? 0;

  final grabRevenue = revenue['grab'] ?? 0.0;
  final shopeeFoodRevenue = revenue['shopeefood'] ?? 0.0;
  final manualRevenue = revenue['manual'] ?? 0.0;

  // Average prep time: time from createdAt → READY_FOR_PICKUP (updatedAt)
  // Approximated as average (updatedAt - createdAt) for COMPLETED orders.
  final avgPrep = await _averagePrepMinutes(dao, from, to);

  return DeliveryReportData(
    totalOrders: grabOrders + shopeeFoodOrders + manualOrders,
    totalRevenue: grabRevenue + shopeeFoodRevenue + manualRevenue,
    grabOrders: grabOrders,
    grabRevenue: grabRevenue,
    shopeeFoodOrders: shopeeFoodOrders,
    shopeeFoodRevenue: shopeeFoodRevenue,
    manualOrders: manualOrders,
    manualRevenue: manualRevenue,
    cancelledOrders: cancelledCount,
    averagePrepMinutes: avgPrep,
  );
}

Future<List<DeliveryDailyRow>> _buildDailyRows(
  DeliveryOrdersDao dao,
  DateTime from,
  DateTime to,
) async {
  final rows = await dao.getDailyOrdersByPlatform(from, to);
  return rows.map((r) {
    return DeliveryDailyRow(
      date: r.date,
      orderCount: r.orderCount,
      revenue: r.revenue,
      platform: r.platform,
    );
  }).toList();
}

// Low-level query wrappers — delegate to the DAO
Future<Map<String, int>> _countByPlatformInRange(
    DeliveryOrdersDao dao, DateTime from, DateTime to) async {
  return dao.countByPlatformInRange(from, to);
}

Future<Map<String, double>> _revenueByPlatformInRange(
    DeliveryOrdersDao dao, DateTime from, DateTime to) async {
  return dao.revenueByPlatformInRange(from, to);
}

Future<int> _countByStatusInRange(
    DeliveryOrdersDao dao, DateTime from, DateTime to, String status) async {
  return dao.countByStatusInRange(from, to, status);
}

Future<double> _averagePrepMinutes(
    DeliveryOrdersDao dao, DateTime from, DateTime to) async {
  return dao.averagePrepMinutes(from, to);
}

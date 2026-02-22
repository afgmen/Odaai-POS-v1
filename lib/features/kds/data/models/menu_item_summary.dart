/// Aggregated summary of a single menu item across all active orders.
///
/// Provides at-a-glance information about how many units of a menu item
/// are currently in each status (pending, preparing, ready).
class MenuItemSummary {
  final String productName;

  /// Total quantity across all active orders
  final int totalQuantity;

  /// Quantity breakdown by order status
  final int pendingQuantity;
  final int preparingQuantity;
  final int readyQuantity;

  /// Number of distinct orders containing this item
  final int orderCount;

  const MenuItemSummary({
    required this.productName,
    required this.totalQuantity,
    required this.pendingQuantity,
    required this.preparingQuantity,
    required this.readyQuantity,
    required this.orderCount,
  });

  /// Percentage of total that is currently being prepared or ready
  double get progressPercent {
    if (totalQuantity == 0) return 0;
    return (preparingQuantity + readyQuantity) / totalQuantity;
  }

  /// Whether any quantity is still pending
  bool get hasPending => pendingQuantity > 0;

  /// Whether any quantity is currently being prepared
  bool get hasPreparing => preparingQuantity > 0;

  /// Whether any quantity is ready
  bool get hasReady => readyQuantity > 0;

  /// Dominant status based on the largest quantity
  String get dominantStatus {
    if (readyQuantity >= preparingQuantity && readyQuantity >= pendingQuantity) {
      if (readyQuantity > 0) return 'READY';
    }
    if (preparingQuantity >= pendingQuantity) {
      if (preparingQuantity > 0) return 'PREPARING';
    }
    return 'PENDING';
  }
}

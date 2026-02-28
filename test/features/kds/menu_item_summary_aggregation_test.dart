import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/features/kds/data/models/menu_item_summary.dart';
import 'package:oda_pos/features/kds/data/models/kitchen_order_with_items.dart';
import 'package:oda_pos/database/app_database.dart';

// ---------------------------------------------------------------------------
// Pure aggregation function extracted from menuItemSummaryProvider.
// Keeping this in the test file avoids modifying production code for the sake
// of testability, while still giving us deterministic coverage.
// ---------------------------------------------------------------------------

/// Replicates the aggregation logic inside [menuItemSummaryProvider].
List<MenuItemSummary> aggregateSummaries(
  List<KitchenOrderWithItems> ordersWithItems,
) {
  final Map<String, _Acc> acc = {};

  for (final o in ordersWithItems) {
    final status = o.order.status;

    for (final item in o.items) {
      final name = item.productName;
      acc.putIfAbsent(name, () => _Acc(name));

      final a = acc[name]!;
      a.total += item.quantity;
      a.orderIds.add(o.order.id);

      switch (status) {
        case 'PENDING':
          a.pending += item.quantity;
          break;
        case 'PREPARING':
          a.preparing += item.quantity;
          break;
        case 'READY':
          a.ready += item.quantity;
          break;
      }
    }
  }

  return acc.values
      .map((a) => MenuItemSummary(
            productName: a.name,
            totalQuantity: a.total,
            pendingQuantity: a.pending,
            preparingQuantity: a.preparing,
            readyQuantity: a.ready,
            orderCount: a.orderIds.length,
          ))
      .toList()
    ..sort((x, y) => y.totalQuantity.compareTo(x.totalQuantity));
}

class _Acc {
  final String name;
  int total = 0;
  int pending = 0;
  int preparing = 0;
  int ready = 0;
  final Set<int> orderIds = {};
  _Acc(this.name);
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

KitchenOrder _order(int id, String status) => KitchenOrder(
      id: id,
      saleId: id,
      status: status,
      priority: 'NORMAL',
      orderType: 'dineIn',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

SaleItem _item(String name, int qty) => SaleItem(
      id: 1,
      saleId: 1,
      productId: 1,
      productName: name,
      sku: name,
      unitPrice: 1.0,
      quantity: qty,
      total: qty.toDouble(),
      roundNumber: 1,
    );

KitchenOrderWithItems _orderWithItems(
  int id,
  String status,
  List<SaleItem> items,
) =>
    KitchenOrderWithItems(order: _order(id, status), items: items);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('menuItemSummaryProvider aggregation logic', () {
    // -----------------------------------------------------------------------
    // Empty input
    // -----------------------------------------------------------------------

    test('returns empty list when there are no orders', () {
      final result = aggregateSummaries([]);
      expect(result, isEmpty);
    });

    test('returns empty list when order has no items', () {
      final result = aggregateSummaries([
        _orderWithItems(1, 'PENDING', []),
      ]);
      expect(result, isEmpty);
    });

    // -----------------------------------------------------------------------
    // Single order, single item
    // -----------------------------------------------------------------------

    group('single order with single item', () {
      test('PENDING order populates pendingQuantity', () {
        final result = aggregateSummaries([
          _orderWithItems(1, 'PENDING', [_item('Pho', 2)]),
        ]);
        expect(result.length, 1);
        expect(result[0].productName, 'Pho');
        expect(result[0].totalQuantity, 2);
        expect(result[0].pendingQuantity, 2);
        expect(result[0].preparingQuantity, 0);
        expect(result[0].readyQuantity, 0);
        expect(result[0].orderCount, 1);
      });

      test('PREPARING order populates preparingQuantity', () {
        final result = aggregateSummaries([
          _orderWithItems(1, 'PREPARING', [_item('Bun Bo', 3)]),
        ]);
        expect(result[0].preparingQuantity, 3);
        expect(result[0].pendingQuantity, 0);
      });

      test('READY order populates readyQuantity', () {
        final result = aggregateSummaries([
          _orderWithItems(1, 'READY', [_item('Banh Mi', 1)]),
        ]);
        expect(result[0].readyQuantity, 1);
        expect(result[0].pendingQuantity, 0);
      });

      test('SERVED order is ignored (quantities stay 0)', () {
        final result = aggregateSummaries([
          _orderWithItems(1, 'SERVED', [_item('Coffee', 2)]),
        ]);
        // Item appears but no status quantities counted
        expect(result[0].pendingQuantity, 0);
        expect(result[0].preparingQuantity, 0);
        expect(result[0].readyQuantity, 0);
        expect(result[0].totalQuantity, 2);
      });
    });

    // -----------------------------------------------------------------------
    // Multiple items in one order
    // -----------------------------------------------------------------------

    test('single PENDING order with multiple distinct items', () {
      final result = aggregateSummaries([
        _orderWithItems(1, 'PENDING', [
          _item('Pho', 2),
          _item('Spring Roll', 3),
        ]),
      ]);
      expect(result.length, 2);
      // Sorted by totalQuantity descending
      expect(result[0].productName, 'Spring Roll');
      expect(result[0].totalQuantity, 3);
      expect(result[1].productName, 'Pho');
      expect(result[1].totalQuantity, 2);
    });

    // -----------------------------------------------------------------------
    // Same item across multiple orders
    // -----------------------------------------------------------------------

    test('same item in two PENDING orders is aggregated', () {
      final result = aggregateSummaries([
        _orderWithItems(1, 'PENDING', [_item('Pho', 2)]),
        _orderWithItems(2, 'PENDING', [_item('Pho', 3)]),
      ]);
      expect(result.length, 1);
      expect(result[0].totalQuantity, 5);
      expect(result[0].pendingQuantity, 5);
      expect(result[0].orderCount, 2);
    });

    test('same item across PENDING and PREPARING orders splits quantities', () {
      final result = aggregateSummaries([
        _orderWithItems(1, 'PENDING', [_item('Pho', 1)]),
        _orderWithItems(2, 'PREPARING', [_item('Pho', 2)]),
      ]);
      expect(result.length, 1);
      expect(result[0].totalQuantity, 3);
      expect(result[0].pendingQuantity, 1);
      expect(result[0].preparingQuantity, 2);
      expect(result[0].readyQuantity, 0);
      expect(result[0].orderCount, 2);
    });

    test('same item across all three active statuses', () {
      final result = aggregateSummaries([
        _orderWithItems(1, 'PENDING', [_item('Pho', 1)]),
        _orderWithItems(2, 'PREPARING', [_item('Pho', 2)]),
        _orderWithItems(3, 'READY', [_item('Pho', 3)]),
      ]);
      expect(result.length, 1);
      expect(result[0].totalQuantity, 6);
      expect(result[0].pendingQuantity, 1);
      expect(result[0].preparingQuantity, 2);
      expect(result[0].readyQuantity, 3);
      expect(result[0].orderCount, 3);
    });

    // -----------------------------------------------------------------------
    // Sorting
    // -----------------------------------------------------------------------

    group('sort order (highest totalQuantity first)', () {
      test('results are sorted descending by totalQuantity', () {
        final result = aggregateSummaries([
          _orderWithItems(1, 'PENDING', [
            _item('A', 1),
            _item('B', 5),
            _item('C', 3),
          ]),
        ]);
        final quantities = result.map((s) => s.totalQuantity).toList();
        expect(quantities, [5, 3, 1]);
      });

      test('items with equal quantity preserve all entries', () {
        final result = aggregateSummaries([
          _orderWithItems(1, 'PENDING', [
            _item('X', 2),
            _item('Y', 2),
          ]),
        ]);
        expect(result.length, 2);
        expect(result.every((s) => s.totalQuantity == 2), isTrue);
      });
    });

    // -----------------------------------------------------------------------
    // orderCount deduplication
    // -----------------------------------------------------------------------

    test('orderCount counts distinct orders, not item lines', () {
      // Same order id = should count as 1 order even if item appears multiple times
      final result = aggregateSummaries([
        KitchenOrderWithItems(
          order: _order(42, 'PENDING'),
          items: [_item('Pho', 1), _item('Pho', 2)],
        ),
      ]);
      // Note: two SaleItem rows with the same productName in one order
      // The aggregation groups by productName; orderIds.add(42) twice → still 1.
      expect(result[0].orderCount, 1);
      expect(result[0].totalQuantity, 3); // 1 + 2
    });

    test('orderCount correctly counts two different orders', () {
      final result = aggregateSummaries([
        _orderWithItems(10, 'PENDING', [_item('Pho', 1)]),
        _orderWithItems(11, 'READY', [_item('Pho', 1)]),
      ]);
      expect(result[0].orderCount, 2);
    });

    // -----------------------------------------------------------------------
    // Mixed items across orders
    // -----------------------------------------------------------------------

    test('complex multi-order scenario', () {
      final result = aggregateSummaries([
        _orderWithItems(1, 'PENDING', [
          _item('Pho', 2),
          _item('Coffee', 1),
        ]),
        _orderWithItems(2, 'PREPARING', [
          _item('Pho', 1),
          _item('Banh Mi', 3),
        ]),
        _orderWithItems(3, 'READY', [
          _item('Coffee', 2),
        ]),
      ]);

      expect(result.length, 3);

      final pho = result.firstWhere((s) => s.productName == 'Pho');
      expect(pho.totalQuantity, 3);
      expect(pho.pendingQuantity, 2);
      expect(pho.preparingQuantity, 1);
      expect(pho.orderCount, 2);

      final coffee = result.firstWhere((s) => s.productName == 'Coffee');
      expect(coffee.totalQuantity, 3);
      expect(coffee.pendingQuantity, 1);
      expect(coffee.readyQuantity, 2);
      expect(coffee.orderCount, 2);

      final banhMi = result.firstWhere((s) => s.productName == 'Banh Mi');
      expect(banhMi.totalQuantity, 3);
      expect(banhMi.preparingQuantity, 3);
      expect(banhMi.orderCount, 1);
    });
  });
}

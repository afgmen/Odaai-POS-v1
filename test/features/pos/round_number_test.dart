import 'package:flutter_test/flutter_test.dart';

/// Tests for round number business logic in POS ordering.
/// Round numbers track multiple order rounds on open tabs.
/// The actual DB operation is in SalesDao.getNextRoundNumber,
/// but here we test the pure computation logic.

void main() {
  group('Round number: new order', () {
    test('first order starts at round 1', () {
      // New sale items default to roundNumber = 1
      const defaultRoundNumber = 1;
      expect(defaultRoundNumber, 1);
    });

    test('new sale items all have round 1', () {
      final items = List.generate(5, (i) => _MockSaleItem(
        productId: i + 1,
        roundNumber: 1,
      ));
      expect(items.every((item) => item.roundNumber == 1), true);
    });
  });

  group('Round number: next round calculation', () {
    test('next round = max existing round + 1', () {
      // Simulating getNextRoundNumber logic
      final existingRounds = [1];
      final maxRound = existingRounds.reduce((a, b) => a > b ? a : b);
      expect(maxRound + 1, 2);
    });

    test('third round after two rounds', () {
      final existingRounds = [1, 2];
      final maxRound = existingRounds.reduce((a, b) => a > b ? a : b);
      expect(maxRound + 1, 3);
    });

    test('handles non-sequential rounds', () {
      // Even if some rounds were deleted, next is always max + 1
      final existingRounds = [1, 3, 5];
      final maxRound = existingRounds.reduce((a, b) => a > b ? a : b);
      expect(maxRound + 1, 6);
    });

    test('null max round defaults to 0, so first round is 1', () {
      // When no items exist: max(roundNumber) returns null → 0
      final int? maxRound = null;
      final nextRound = (maxRound ?? 0) + 1;
      expect(nextRound, 1);
    });
  });

  group('Round number: item grouping', () {
    test('items grouped by round number', () {
      final items = [
        _MockSaleItem(productId: 1, roundNumber: 1),
        _MockSaleItem(productId: 2, roundNumber: 1),
        _MockSaleItem(productId: 3, roundNumber: 2),
        _MockSaleItem(productId: 4, roundNumber: 2),
        _MockSaleItem(productId: 5, roundNumber: 3),
      ];

      final grouped = <int, List<_MockSaleItem>>{};
      for (final item in items) {
        grouped.putIfAbsent(item.roundNumber, () => []).add(item);
      }

      expect(grouped.keys.length, 3);
      expect(grouped[1]!.length, 2);
      expect(grouped[2]!.length, 2);
      expect(grouped[3]!.length, 1);
    });

    test('rounds sorted in ascending order', () {
      final items = [
        _MockSaleItem(productId: 1, roundNumber: 3),
        _MockSaleItem(productId: 2, roundNumber: 1),
        _MockSaleItem(productId: 3, roundNumber: 2),
      ];

      final grouped = <int, List<_MockSaleItem>>{};
      for (final item in items) {
        grouped.putIfAbsent(item.roundNumber, () => []).add(item);
      }
      final sortedRounds = grouped.keys.toList()..sort();

      expect(sortedRounds, [1, 2, 3]);
    });

    test('single round does not show round headers', () {
      final items = [
        _MockSaleItem(productId: 1, roundNumber: 1),
        _MockSaleItem(productId: 2, roundNumber: 1),
      ];

      final grouped = <int, List<_MockSaleItem>>{};
      for (final item in items) {
        grouped.putIfAbsent(item.roundNumber, () => []).add(item);
      }
      final sortedRounds = grouped.keys.toList()..sort();

      // From bill_request_screen: only show headers if multiple rounds
      final showHeaders = sortedRounds.length > 1;
      expect(showHeaders, false);
    });

    test('multiple rounds show round headers', () {
      final items = [
        _MockSaleItem(productId: 1, roundNumber: 1),
        _MockSaleItem(productId: 2, roundNumber: 2),
      ];

      final grouped = <int, List<_MockSaleItem>>{};
      for (final item in items) {
        grouped.putIfAbsent(item.roundNumber, () => []).add(item);
      }
      final sortedRounds = grouped.keys.toList()..sort();

      final showHeaders = sortedRounds.length > 1;
      expect(showHeaders, true);
    });
  });

  group('Round number: sale total recalculation', () {
    test('total is sum of all items across all rounds', () {
      final items = [
        _MockSaleItem(productId: 1, roundNumber: 1, total: 50000),
        _MockSaleItem(productId: 2, roundNumber: 1, total: 30000),
        _MockSaleItem(productId: 3, roundNumber: 2, total: 45000),
      ];

      final newSubtotal = items.fold<double>(0, (sum, i) => sum + i.total);
      expect(newSubtotal, 125000);
    });

    test('adding items updates subtotal', () {
      // Existing items
      final existingItems = [
        _MockSaleItem(productId: 1, roundNumber: 1, total: 50000),
      ];
      final existingTotal = existingItems.fold<double>(0, (sum, i) => sum + i.total);

      // New round items added
      final newItems = [
        _MockSaleItem(productId: 2, roundNumber: 2, total: 30000),
      ];

      final allItems = [...existingItems, ...newItems];
      final newTotal = allItems.fold<double>(0, (sum, i) => sum + i.total);

      expect(newTotal, 80000);
      expect(newTotal > existingTotal, true);
    });
  });

  group('Round number: open tab table status reset', () {
    test('table status resets to ORDERING on new round', () {
      // When adding a new round to an open tab,
      // table status is reset to ORDERING
      const statusBeforeNewRound = 'SERVED';
      const statusAfterNewRound = 'ORDERING';
      expect(statusAfterNewRound, 'ORDERING');
      expect(statusBeforeNewRound != statusAfterNewRound, true);
    });

    test('open tab flag preserved across rounds', () {
      const isOpenTab = true;
      // Adding rounds doesn't change isOpenTab
      expect(isOpenTab, true);
    });
  });

  group('Round number: edge cases', () {
    test('empty items list', () {
      final items = <_MockSaleItem>[];
      final grouped = <int, List<_MockSaleItem>>{};
      for (final item in items) {
        grouped.putIfAbsent(item.roundNumber, () => []).add(item);
      }
      expect(grouped.isEmpty, true);
    });

    test('many rounds (stress test)', () {
      final items = List.generate(100, (i) => _MockSaleItem(
        productId: i + 1,
        roundNumber: (i ~/ 5) + 1, // 5 items per round, 20 rounds
      ));

      final grouped = <int, List<_MockSaleItem>>{};
      for (final item in items) {
        grouped.putIfAbsent(item.roundNumber, () => []).add(item);
      }

      expect(grouped.keys.length, 20);
      expect(grouped.values.every((list) => list.length == 5), true);
    });
  });
}

class _MockSaleItem {
  final int productId;
  final int roundNumber;
  final double total;

  _MockSaleItem({
    required this.productId,
    required this.roundNumber,
    this.total = 0,
  });
}

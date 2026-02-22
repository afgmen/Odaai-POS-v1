import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/features/kds/data/models/menu_item_summary.dart';

void main() {
  group('MenuItemSummary', () {
    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    MenuItemSummary make({
      String productName = 'Pho',
      int total = 0,
      int pending = 0,
      int preparing = 0,
      int ready = 0,
      int orderCount = 1,
    }) {
      return MenuItemSummary(
        productName: productName,
        totalQuantity: total,
        pendingQuantity: pending,
        preparingQuantity: preparing,
        readyQuantity: ready,
        orderCount: orderCount,
      );
    }

    // -----------------------------------------------------------------------
    // progressPercent
    // -----------------------------------------------------------------------

    group('progressPercent', () {
      test('returns 0 when totalQuantity is 0', () {
        final s = make(total: 0, preparing: 0, ready: 0);
        expect(s.progressPercent, 0.0);
      });

      test('returns 0 when all units are pending', () {
        final s = make(total: 4, pending: 4);
        expect(s.progressPercent, 0.0);
      });

      test('returns 1.0 when all units are ready', () {
        final s = make(total: 3, ready: 3);
        expect(s.progressPercent, 1.0);
      });

      test('returns 1.0 when all units are preparing', () {
        final s = make(total: 5, preparing: 5);
        expect(s.progressPercent, 1.0);
      });

      test('returns correct ratio for mixed status', () {
        // 2 pending, 1 preparing, 1 ready → (1+1)/4 = 0.5
        final s = make(total: 4, pending: 2, preparing: 1, ready: 1);
        expect(s.progressPercent, 0.5);
      });

      test('returns correct ratio when only preparing and ready', () {
        // 3 preparing, 2 ready → 5/5 = 1.0
        final s = make(total: 5, preparing: 3, ready: 2);
        expect(s.progressPercent, 1.0);
      });
    });

    // -----------------------------------------------------------------------
    // hasPending / hasPreparing / hasReady
    // -----------------------------------------------------------------------

    group('status presence flags', () {
      test('hasPending is true when pendingQuantity > 0', () {
        expect(make(pending: 1).hasPending, isTrue);
      });

      test('hasPending is false when pendingQuantity == 0', () {
        expect(make(pending: 0).hasPending, isFalse);
      });

      test('hasPreparing is true when preparingQuantity > 0', () {
        expect(make(preparing: 2).hasPreparing, isTrue);
      });

      test('hasPreparing is false when preparingQuantity == 0', () {
        expect(make(preparing: 0).hasPreparing, isFalse);
      });

      test('hasReady is true when readyQuantity > 0', () {
        expect(make(ready: 3).hasReady, isTrue);
      });

      test('hasReady is false when readyQuantity == 0', () {
        expect(make(ready: 0).hasReady, isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // dominantStatus
    // -----------------------------------------------------------------------

    group('dominantStatus', () {
      test('returns READY when readyQuantity is highest', () {
        final s = make(total: 6, pending: 1, preparing: 2, ready: 3);
        expect(s.dominantStatus, 'READY');
      });

      test('returns READY when readyQuantity ties with others and is > 0', () {
        // ready == preparing, ready > pending → READY wins
        final s = make(total: 6, pending: 1, preparing: 2, ready: 3);
        expect(s.dominantStatus, 'READY');
      });

      test('returns PREPARING when preparingQuantity is highest (no ready)', () {
        final s = make(total: 5, pending: 2, preparing: 3, ready: 0);
        expect(s.dominantStatus, 'PREPARING');
      });

      test('returns PENDING when all quantities are 0', () {
        final s = make(total: 0, pending: 0, preparing: 0, ready: 0);
        expect(s.dominantStatus, 'PENDING');
      });

      test('returns PENDING when only pendingQuantity is > 0', () {
        final s = make(total: 4, pending: 4, preparing: 0, ready: 0);
        expect(s.dominantStatus, 'PENDING');
      });

      test('returns READY when ready ties with preparing and both beat pending', () {
        final s = make(total: 6, pending: 0, preparing: 3, ready: 3);
        expect(s.dominantStatus, 'READY');
      });
    });

    // -----------------------------------------------------------------------
    // Edge cases
    // -----------------------------------------------------------------------

    group('edge cases', () {
      test('single unit all pending', () {
        final s = make(total: 1, pending: 1, preparing: 0, ready: 0);
        expect(s.hasPending, isTrue);
        expect(s.hasPreparing, isFalse);
        expect(s.hasReady, isFalse);
        expect(s.progressPercent, 0.0);
        expect(s.dominantStatus, 'PENDING');
      });

      test('single unit all ready', () {
        final s = make(total: 1, pending: 0, preparing: 0, ready: 1);
        expect(s.hasReady, isTrue);
        expect(s.progressPercent, 1.0);
        expect(s.dominantStatus, 'READY');
      });

      test('large quantities compute correctly', () {
        final s = make(
          total: 1000,
          pending: 200,
          preparing: 300,
          ready: 500,
        );
        expect(s.progressPercent, 0.8);
        expect(s.dominantStatus, 'READY');
      });

      test('productName is preserved', () {
        final s = make(productName: 'Bánh mì đặc biệt');
        expect(s.productName, 'Bánh mì đặc biệt');
      });

      test('orderCount is preserved', () {
        final s = make(orderCount: 7);
        expect(s.orderCount, 7);
      });
    });
  });
}

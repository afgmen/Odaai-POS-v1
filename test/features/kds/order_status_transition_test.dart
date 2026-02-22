import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/features/kds/domain/enums/order_status.dart';

void main() {
  group('OrderStatus — canTransitionTo()', () {
    // ── Valid forward transitions ──────────────────────────────────
    group('valid transitions', () {
      test('PENDING → PREPARING is allowed', () {
        expect(
          OrderStatus.pending.canTransitionTo(OrderStatus.preparing),
          isTrue,
        );
      });

      test('PENDING → CANCELLED is allowed', () {
        expect(
          OrderStatus.pending.canTransitionTo(OrderStatus.cancelled),
          isTrue,
        );
      });

      test('PREPARING → READY is allowed', () {
        expect(
          OrderStatus.preparing.canTransitionTo(OrderStatus.ready),
          isTrue,
        );
      });

      test('PREPARING → CANCELLED is allowed', () {
        expect(
          OrderStatus.preparing.canTransitionTo(OrderStatus.cancelled),
          isTrue,
        );
      });

      test('READY → SERVED is allowed', () {
        expect(
          OrderStatus.ready.canTransitionTo(OrderStatus.served),
          isTrue,
        );
      });
    });

    // ── Invalid / skipped transitions ─────────────────────────────
    group('invalid transitions', () {
      test('PENDING → READY is not allowed', () {
        expect(
          OrderStatus.pending.canTransitionTo(OrderStatus.ready),
          isFalse,
        );
      });

      test('PENDING → SERVED is not allowed', () {
        expect(
          OrderStatus.pending.canTransitionTo(OrderStatus.served),
          isFalse,
        );
      });

      test('PREPARING → PENDING is not allowed', () {
        expect(
          OrderStatus.preparing.canTransitionTo(OrderStatus.pending),
          isFalse,
        );
      });

      test('PREPARING → SERVED is not allowed', () {
        expect(
          OrderStatus.preparing.canTransitionTo(OrderStatus.served),
          isFalse,
        );
      });

      test('READY → PENDING is not allowed', () {
        expect(
          OrderStatus.ready.canTransitionTo(OrderStatus.pending),
          isFalse,
        );
      });

      test('READY → PREPARING is not allowed', () {
        expect(
          OrderStatus.ready.canTransitionTo(OrderStatus.preparing),
          isFalse,
        );
      });

      test('READY → CANCELLED is not allowed', () {
        expect(
          OrderStatus.ready.canTransitionTo(OrderStatus.cancelled),
          isFalse,
        );
      });
    });

    // ── Terminal states cannot transition at all ───────────────────
    group('terminal states block all transitions', () {
      test('SERVED → PENDING is not allowed', () {
        expect(
          OrderStatus.served.canTransitionTo(OrderStatus.pending),
          isFalse,
        );
      });

      test('SERVED → PREPARING is not allowed', () {
        expect(
          OrderStatus.served.canTransitionTo(OrderStatus.preparing),
          isFalse,
        );
      });

      test('SERVED → READY is not allowed', () {
        expect(
          OrderStatus.served.canTransitionTo(OrderStatus.ready),
          isFalse,
        );
      });

      test('SERVED → CANCELLED is not allowed', () {
        expect(
          OrderStatus.served.canTransitionTo(OrderStatus.cancelled),
          isFalse,
        );
      });

      test('CANCELLED → PENDING is not allowed', () {
        expect(
          OrderStatus.cancelled.canTransitionTo(OrderStatus.pending),
          isFalse,
        );
      });

      test('CANCELLED → PREPARING is not allowed', () {
        expect(
          OrderStatus.cancelled.canTransitionTo(OrderStatus.preparing),
          isFalse,
        );
      });

      test('CANCELLED → READY is not allowed', () {
        expect(
          OrderStatus.cancelled.canTransitionTo(OrderStatus.ready),
          isFalse,
        );
      });

      test('CANCELLED → SERVED is not allowed', () {
        expect(
          OrderStatus.cancelled.canTransitionTo(OrderStatus.served),
          isFalse,
        );
      });
    });
  });

  // ── isActive / isCompleted helpers ────────────────────────────────
  group('OrderStatus — isActive / isCompleted', () {
    test('PENDING is active', () {
      expect(OrderStatus.pending.isActive, isTrue);
      expect(OrderStatus.pending.isCompleted, isFalse);
    });

    test('PREPARING is active', () {
      expect(OrderStatus.preparing.isActive, isTrue);
      expect(OrderStatus.preparing.isCompleted, isFalse);
    });

    test('READY is active', () {
      expect(OrderStatus.ready.isActive, isTrue);
      expect(OrderStatus.ready.isCompleted, isFalse);
    });

    test('SERVED is completed', () {
      expect(OrderStatus.served.isActive, isFalse);
      expect(OrderStatus.served.isCompleted, isTrue);
    });

    test('CANCELLED is completed', () {
      expect(OrderStatus.cancelled.isActive, isFalse);
      expect(OrderStatus.cancelled.isCompleted, isTrue);
    });
  });

  // ── fromString ────────────────────────────────────────────────────
  group('OrderStatus — fromString()', () {
    test('parses PENDING', () {
      expect(OrderStatus.fromString('PENDING'), OrderStatus.pending);
    });

    test('parses PREPARING', () {
      expect(OrderStatus.fromString('PREPARING'), OrderStatus.preparing);
    });

    test('parses READY', () {
      expect(OrderStatus.fromString('READY'), OrderStatus.ready);
    });

    test('parses SERVED', () {
      expect(OrderStatus.fromString('SERVED'), OrderStatus.served);
    });

    test('parses CANCELLED', () {
      expect(OrderStatus.fromString('CANCELLED'), OrderStatus.cancelled);
    });

    test('unknown value defaults to PENDING', () {
      expect(OrderStatus.fromString('INVALID'), OrderStatus.pending);
    });
  });

  // ── value / displayName ───────────────────────────────────────────
  group('OrderStatus — value strings', () {
    test('each status has the expected DB string value', () {
      expect(OrderStatus.pending.value, 'PENDING');
      expect(OrderStatus.preparing.value, 'PREPARING');
      expect(OrderStatus.ready.value, 'READY');
      expect(OrderStatus.served.value, 'SERVED');
      expect(OrderStatus.cancelled.value, 'CANCELLED');
    });
  });

  // ── KitchenService timestamp logic (pure logic layer) ─────────────
  // These tests verify the business rules that KitchenService enforces
  // without needing a real repository (rule assertions via canTransitionTo).
  group('KitchenService status method preconditions', () {
    test('startPreparing requires current status to be PENDING', () {
      // Only PENDING can transition to PREPARING
      final canStart = OrderStatus.pending.canTransitionTo(OrderStatus.preparing);
      expect(canStart, isTrue);

      // READY cannot go back to PREPARING
      final cannotStart = OrderStatus.ready.canTransitionTo(OrderStatus.preparing);
      expect(cannotStart, isFalse);
    });

    test('markAsReady requires current status to be PREPARING', () {
      final canReady = OrderStatus.preparing.canTransitionTo(OrderStatus.ready);
      expect(canReady, isTrue);

      final cannotReady = OrderStatus.pending.canTransitionTo(OrderStatus.ready);
      expect(cannotReady, isFalse);
    });

    test('markAsServed requires current status to be READY', () {
      final canServe = OrderStatus.ready.canTransitionTo(OrderStatus.served);
      expect(canServe, isTrue);

      final cannotServe = OrderStatus.preparing.canTransitionTo(OrderStatus.served);
      expect(cannotServe, isFalse);
    });

    test('cancelOrder is blocked for SERVED status', () {
      // Mirrors the explicit SERVED check in KitchenService.cancelOrder()
      final servedIsCompleted = OrderStatus.served.isCompleted;
      expect(servedIsCompleted, isTrue);
    });
  });
}

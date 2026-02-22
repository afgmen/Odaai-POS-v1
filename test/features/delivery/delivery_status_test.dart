import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/features/delivery/domain/enums/delivery_status.dart';

void main() {
  // ── Valid status transitions via nextStatus ──────────────────────────────
  group('DeliveryStatus — nextStatus (happy path)', () {
    test('NEW → ACCEPTED', () {
      expect(DeliveryStatus.newOrder.nextStatus, DeliveryStatus.accepted);
    });

    test('ACCEPTED → PREPARING', () {
      expect(DeliveryStatus.accepted.nextStatus, DeliveryStatus.preparing);
    });

    test('PREPARING → READY_FOR_PICKUP', () {
      expect(DeliveryStatus.preparing.nextStatus, DeliveryStatus.readyForPickup);
    });

    test('READY_FOR_PICKUP → PICKED_UP', () {
      expect(DeliveryStatus.readyForPickup.nextStatus, DeliveryStatus.pickedUp);
    });

    test('PICKED_UP → COMPLETED', () {
      expect(DeliveryStatus.pickedUp.nextStatus, DeliveryStatus.completed);
    });
  });

  // ── Terminal states have no next status ────────────────────────────────
  group('DeliveryStatus — terminal states (no nextStatus)', () {
    test('COMPLETED has no next status', () {
      expect(DeliveryStatus.completed.nextStatus, isNull);
    });

    test('CANCELLED has no next status', () {
      expect(DeliveryStatus.cancelled.nextStatus, isNull);
    });
  });

  // ── isTerminal / isActive ───────────────────────────────────────────────
  group('DeliveryStatus — isTerminal', () {
    test('COMPLETED is terminal', () {
      expect(DeliveryStatus.completed.isTerminal, isTrue);
    });

    test('CANCELLED is terminal', () {
      expect(DeliveryStatus.cancelled.isTerminal, isTrue);
    });

    test('NEW is not terminal', () {
      expect(DeliveryStatus.newOrder.isTerminal, isFalse);
    });

    test('ACCEPTED is not terminal', () {
      expect(DeliveryStatus.accepted.isTerminal, isFalse);
    });

    test('PREPARING is not terminal', () {
      expect(DeliveryStatus.preparing.isTerminal, isFalse);
    });

    test('READY_FOR_PICKUP is not terminal', () {
      expect(DeliveryStatus.readyForPickup.isTerminal, isFalse);
    });
  });

  group('DeliveryStatus — isActive', () {
    test('NEW is active', () {
      expect(DeliveryStatus.newOrder.isActive, isTrue);
    });

    test('ACCEPTED is active', () {
      expect(DeliveryStatus.accepted.isActive, isTrue);
    });

    test('PREPARING is active', () {
      expect(DeliveryStatus.preparing.isActive, isTrue);
    });

    test('READY_FOR_PICKUP is active', () {
      expect(DeliveryStatus.readyForPickup.isActive, isTrue);
    });

    test('PICKED_UP is not active', () {
      expect(DeliveryStatus.pickedUp.isActive, isFalse);
    });

    test('COMPLETED is not active', () {
      expect(DeliveryStatus.completed.isActive, isFalse);
    });

    test('CANCELLED is not active', () {
      expect(DeliveryStatus.cancelled.isActive, isFalse);
    });
  });

  // ── fromString ────────────────────────────────────────────────────────
  group('DeliveryStatus — fromString()', () {
    test('parses NEW', () {
      expect(DeliveryStatus.fromString('NEW'), DeliveryStatus.newOrder);
    });

    test('parses ACCEPTED', () {
      expect(DeliveryStatus.fromString('ACCEPTED'), DeliveryStatus.accepted);
    });

    test('parses PREPARING', () {
      expect(DeliveryStatus.fromString('PREPARING'), DeliveryStatus.preparing);
    });

    test('parses READY_FOR_PICKUP', () {
      expect(
        DeliveryStatus.fromString('READY_FOR_PICKUP'),
        DeliveryStatus.readyForPickup,
      );
    });

    test('parses PICKED_UP', () {
      expect(DeliveryStatus.fromString('PICKED_UP'), DeliveryStatus.pickedUp);
    });

    test('parses COMPLETED', () {
      expect(DeliveryStatus.fromString('COMPLETED'), DeliveryStatus.completed);
    });

    test('parses CANCELLED', () {
      expect(DeliveryStatus.fromString('CANCELLED'), DeliveryStatus.cancelled);
    });

    test('case-insensitive parsing', () {
      expect(DeliveryStatus.fromString('new'), DeliveryStatus.newOrder);
      expect(DeliveryStatus.fromString('Accepted'), DeliveryStatus.accepted);
    });

    test('unknown value defaults to newOrder', () {
      expect(DeliveryStatus.fromString('INVALID'), DeliveryStatus.newOrder);
    });
  });

  // ── value strings ─────────────────────────────────────────────────────
  group('DeliveryStatus — value strings', () {
    test('each status has the expected string value', () {
      expect(DeliveryStatus.newOrder.value, 'NEW');
      expect(DeliveryStatus.accepted.value, 'ACCEPTED');
      expect(DeliveryStatus.preparing.value, 'PREPARING');
      expect(DeliveryStatus.readyForPickup.value, 'READY_FOR_PICKUP');
      expect(DeliveryStatus.pickedUp.value, 'PICKED_UP');
      expect(DeliveryStatus.completed.value, 'COMPLETED');
      expect(DeliveryStatus.cancelled.value, 'CANCELLED');
    });
  });

  // ── Full workflow chain ────────────────────────────────────────────────
  group('DeliveryStatus — full workflow chain', () {
    test('can walk through the entire lifecycle from NEW to COMPLETED', () {
      DeliveryStatus? current = DeliveryStatus.newOrder;
      final visited = <DeliveryStatus>[];

      while (current != null) {
        visited.add(current);
        current = current.nextStatus;
      }

      expect(visited, [
        DeliveryStatus.newOrder,
        DeliveryStatus.accepted,
        DeliveryStatus.preparing,
        DeliveryStatus.readyForPickup,
        DeliveryStatus.pickedUp,
        DeliveryStatus.completed,
      ]);
    });

    test('chain terminates at COMPLETED with null nextStatus', () {
      DeliveryStatus? s = DeliveryStatus.newOrder;
      while (s?.nextStatus != null) {
        s = s!.nextStatus;
      }
      expect(s, DeliveryStatus.completed);
    });
  });

  // ── Cancellation can be applied from any non-terminal state ──────────
  group('DeliveryStatus — cancellation business rule', () {
    // CANCELLED is a separate terminal state (not reachable via nextStatus).
    // Business rule: orders can be cancelled unless already COMPLETED or CANCELLED.
    test('COMPLETED status cannot be cancelled (already terminal)', () {
      expect(DeliveryStatus.completed.isTerminal, isTrue);
    });

    test('CANCELLED status cannot be cancelled again (already terminal)', () {
      expect(DeliveryStatus.cancelled.isTerminal, isTrue);
    });

    test('NEW order can be cancelled (not yet terminal)', () {
      expect(DeliveryStatus.newOrder.isTerminal, isFalse);
    });

    test('PREPARING order can be cancelled (not yet terminal)', () {
      expect(DeliveryStatus.preparing.isTerminal, isFalse);
    });
  });
}

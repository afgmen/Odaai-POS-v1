import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/features/tables/domain/enums/table_status.dart';

void main() {
  group('TableStatus enum values', () {
    test('has exactly 7 statuses', () {
      expect(TableStatus.values.length, 7);
    });

    test('available has correct properties', () {
      expect(TableStatus.available.value, 'AVAILABLE');
      expect(TableStatus.available.label, 'Available');
      expect(TableStatus.available.color, const Color(0xFF4CAF50));
    });

    test('reserved has correct properties', () {
      expect(TableStatus.reserved.value, 'RESERVED');
      expect(TableStatus.reserved.label, 'Reserved');
      expect(TableStatus.reserved.color, const Color(0xFFFF9800));
    });

    test('ordering has correct properties', () {
      expect(TableStatus.ordering.value, 'ORDERING');
      expect(TableStatus.ordering.label, 'Ordering');
      expect(TableStatus.ordering.color, const Color(0xFFFFC107));
    });

    test('preparing has correct properties', () {
      expect(TableStatus.preparing.value, 'PREPARING');
      expect(TableStatus.preparing.label, 'Preparing');
      expect(TableStatus.preparing.color, const Color(0xFFFF5722));
    });

    test('served has correct properties', () {
      expect(TableStatus.served.value, 'SERVED');
      expect(TableStatus.served.label, 'Served');
      expect(TableStatus.served.color, const Color(0xFF2196F3));
    });

    test('checkout has correct properties', () {
      expect(TableStatus.checkout.value, 'CHECKOUT');
      expect(TableStatus.checkout.label, 'Checkout');
      expect(TableStatus.checkout.color, const Color(0xFF9C27B0));
    });

    test('cleaning has correct properties', () {
      expect(TableStatus.cleaning.value, 'CLEANING');
      expect(TableStatus.cleaning.label, 'Cleaning');
      expect(TableStatus.cleaning.color, const Color(0xFF00BCD4));
    });
  });

  group('TableStatus.fromString', () {
    test('converts all valid strings', () {
      for (final status in TableStatus.values) {
        expect(TableStatus.fromString(status.value), status);
      }
    });

    test('returns available for unknown string', () {
      expect(TableStatus.fromString('UNKNOWN'), TableStatus.available);
      expect(TableStatus.fromString(''), TableStatus.available);
    });
  });

  group('TableStatus state transitions', () {
    test('available can transition to reserved or ordering', () {
      expect(TableStatus.available.canTransitionTo(TableStatus.reserved), true);
      expect(TableStatus.available.canTransitionTo(TableStatus.ordering), true);
      expect(TableStatus.available.canTransitionTo(TableStatus.preparing), false);
      expect(TableStatus.available.canTransitionTo(TableStatus.served), false);
      expect(TableStatus.available.canTransitionTo(TableStatus.checkout), false);
      expect(TableStatus.available.canTransitionTo(TableStatus.cleaning), false);
    });

    test('reserved can transition to ordering or available', () {
      expect(TableStatus.reserved.canTransitionTo(TableStatus.ordering), true);
      expect(TableStatus.reserved.canTransitionTo(TableStatus.available), true);
      expect(TableStatus.reserved.canTransitionTo(TableStatus.preparing), false);
      expect(TableStatus.reserved.canTransitionTo(TableStatus.checkout), false);
    });

    test('ordering can only transition to preparing', () {
      expect(TableStatus.ordering.canTransitionTo(TableStatus.preparing), true);
      expect(TableStatus.ordering.canTransitionTo(TableStatus.available), false);
      expect(TableStatus.ordering.canTransitionTo(TableStatus.served), false);
    });

    test('preparing can only transition to served', () {
      expect(TableStatus.preparing.canTransitionTo(TableStatus.served), true);
      expect(TableStatus.preparing.canTransitionTo(TableStatus.ordering), false);
      expect(TableStatus.preparing.canTransitionTo(TableStatus.checkout), false);
    });

    test('served can transition to checkout or ordering (re-order)', () {
      expect(TableStatus.served.canTransitionTo(TableStatus.checkout), true);
      expect(TableStatus.served.canTransitionTo(TableStatus.ordering), true);
      expect(TableStatus.served.canTransitionTo(TableStatus.available), false);
      expect(TableStatus.served.canTransitionTo(TableStatus.preparing), false);
    });

    test('checkout can only transition to cleaning', () {
      expect(TableStatus.checkout.canTransitionTo(TableStatus.cleaning), true);
      expect(TableStatus.checkout.canTransitionTo(TableStatus.available), false);
      expect(TableStatus.checkout.canTransitionTo(TableStatus.served), false);
    });

    test('cleaning can only transition to available', () {
      expect(TableStatus.cleaning.canTransitionTo(TableStatus.available), true);
      expect(TableStatus.cleaning.canTransitionTo(TableStatus.ordering), false);
      expect(TableStatus.cleaning.canTransitionTo(TableStatus.checkout), false);
    });

    test('full lifecycle: available → ordering → preparing → served → checkout → cleaning → available', () {
      expect(TableStatus.available.canTransitionTo(TableStatus.ordering), true);
      expect(TableStatus.ordering.canTransitionTo(TableStatus.preparing), true);
      expect(TableStatus.preparing.canTransitionTo(TableStatus.served), true);
      expect(TableStatus.served.canTransitionTo(TableStatus.checkout), true);
      expect(TableStatus.checkout.canTransitionTo(TableStatus.cleaning), true);
      expect(TableStatus.cleaning.canTransitionTo(TableStatus.available), true);
    });
  });

  group('TableStatus auto-transitions', () {
    test('checkout auto-transitions to cleaning', () {
      expect(TableStatus.checkout.getAutoTransition(), TableStatus.cleaning);
    });

    test('cleaning auto-transitions to available', () {
      expect(TableStatus.cleaning.getAutoTransition(), TableStatus.available);
    });

    test('other statuses have no auto-transition', () {
      expect(TableStatus.available.getAutoTransition(), isNull);
      expect(TableStatus.reserved.getAutoTransition(), isNull);
      expect(TableStatus.ordering.getAutoTransition(), isNull);
      expect(TableStatus.preparing.getAutoTransition(), isNull);
      expect(TableStatus.served.getAutoTransition(), isNull);
    });
  });

  group('TableStatus auto-transition delays', () {
    test('checkout has 5 minute delay', () {
      expect(TableStatus.checkout.getAutoTransitionDelayMinutes(), 5);
    });

    test('cleaning has 10 minute delay', () {
      expect(TableStatus.cleaning.getAutoTransitionDelayMinutes(), 10);
    });

    test('other statuses have no delay', () {
      expect(TableStatus.available.getAutoTransitionDelayMinutes(), isNull);
      expect(TableStatus.ordering.getAutoTransitionDelayMinutes(), isNull);
    });
  });

  group('TableStatus icons', () {
    test('each status has a unique icon', () {
      final icons = TableStatus.values.map((s) => s.icon).toSet();
      expect(icons.length, TableStatus.values.length);
    });

    test('available icon is check_circle_outline', () {
      expect(TableStatus.available.icon, Icons.check_circle_outline);
    });

    test('checkout icon is payment', () {
      expect(TableStatus.checkout.icon, Icons.payment);
    });
  });

  group('TableStatus static lists', () {
    test('allStatuses returns all 7 statuses', () {
      expect(TableStatus.allStatuses.length, 7);
      expect(TableStatus.allStatuses, TableStatus.values);
    });

    test('activeStatuses excludes available', () {
      expect(TableStatus.activeStatuses.contains(TableStatus.available), false);
      expect(TableStatus.activeStatuses.length, 6);
    });

    test('activeStatuses includes all non-available statuses', () {
      expect(TableStatus.activeStatuses, contains(TableStatus.reserved));
      expect(TableStatus.activeStatuses, contains(TableStatus.ordering));
      expect(TableStatus.activeStatuses, contains(TableStatus.preparing));
      expect(TableStatus.activeStatuses, contains(TableStatus.served));
      expect(TableStatus.activeStatuses, contains(TableStatus.checkout));
      expect(TableStatus.activeStatuses, contains(TableStatus.cleaning));
    });
  });
}

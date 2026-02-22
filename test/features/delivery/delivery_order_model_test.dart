import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/features/delivery/data/models/delivery_order.dart';
import 'package:oda_pos/features/delivery/domain/enums/delivery_platform.dart';
import 'package:oda_pos/features/delivery/domain/enums/delivery_status.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

DeliveryOrder _baseOrder({
  String id = 'order-1',
  String platformOrderId = 'GRAB-001',
  DeliveryPlatform platform = DeliveryPlatform.grab,
  DeliveryStatus status = DeliveryStatus.newOrder,
  String customerName = 'Nguyen Van A',
  List<DeliveryOrderItem>? items,
  double? totalAmount,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2024, 6, 15, 12, 0);
  final resolvedItems = items ??
      [
        const DeliveryOrderItem(name: 'Pho Bo', quantity: 2, price: 15000),
        const DeliveryOrderItem(name: 'Spring Roll', quantity: 1, price: 8000),
      ];
  final resolvedTotal =
      totalAmount ?? resolvedItems.fold<double>(0.0, (s, i) => s + i.price * i.quantity);

  return DeliveryOrder(
    id: id,
    platformOrderId: platformOrderId,
    platform: platform,
    status: status,
    customerName: customerName,
    items: resolvedItems,
    totalAmount: resolvedTotal,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

// ---------------------------------------------------------------------------

void main() {
  // ── totalAmount / totalQuantity ─────────────────────────────────────────
  group('DeliveryOrder — totalAmount and totalQuantity', () {
    test('totalAmount is preserved as-is from constructor', () {
      final order = _baseOrder(totalAmount: 38000);
      expect(order.totalAmount, 38000.0);
    });

    test('totalQuantity is sum of all item quantities', () {
      final order = _baseOrder(
        items: [
          const DeliveryOrderItem(name: 'Pho Bo', quantity: 2, price: 15000),
          const DeliveryOrderItem(name: 'Spring Roll', quantity: 3, price: 8000),
        ],
      );
      expect(order.totalQuantity, 5); // 2 + 3
    });

    test('empty items list gives totalQuantity = 0', () {
      final order = _baseOrder(items: [], totalAmount: 0);
      expect(order.totalQuantity, 0);
    });

    test('single item order has correct totalQuantity', () {
      final order = _baseOrder(
        items: [const DeliveryOrderItem(name: 'Coffee', quantity: 1, price: 5000)],
        totalAmount: 5000,
      );
      expect(order.totalQuantity, 1);
    });
  });

  // ── elapsed time ──────────────────────────────────────────────────────
  group('DeliveryOrder — elapsed time', () {
    test('elapsedMinutes increases over time', () {
      final pastTime = DateTime.now().subtract(const Duration(minutes: 10));
      final order = _baseOrder(createdAt: pastTime, updatedAt: pastTime);
      expect(order.elapsedMinutes, greaterThanOrEqualTo(9));
    });

    test('freshly created order has near-zero elapsed time', () {
      final now = DateTime.now();
      final order = _baseOrder(createdAt: now, updatedAt: now);
      expect(order.elapsedMinutes, lessThanOrEqualTo(1));
    });
  });

  // ── copyWith ──────────────────────────────────────────────────────────
  group('DeliveryOrder — copyWith()', () {
    test('copyWith status updates only the status field', () {
      final original = _baseOrder(status: DeliveryStatus.newOrder);
      final updated = original.copyWith(status: DeliveryStatus.accepted);

      expect(updated.status, DeliveryStatus.accepted);
      expect(updated.id, original.id);
      expect(updated.customerName, original.customerName);
      expect(updated.totalAmount, original.totalAmount);
    });

    test('copyWith without arguments produces an equal copy', () {
      final original = _baseOrder();
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.platformOrderId, original.platformOrderId);
      expect(copy.platform, original.platform);
      expect(copy.status, original.status);
      expect(copy.customerName, original.customerName);
      expect(copy.totalAmount, original.totalAmount);
    });

    test('copyWith customerName creates new object with new name', () {
      final original = _baseOrder(customerName: 'Alice');
      final updated = original.copyWith(customerName: 'Bob');

      expect(updated.customerName, 'Bob');
      expect(original.customerName, 'Alice'); // immutable
    });
  });

  // ── JSON serialization ────────────────────────────────────────────────
  group('DeliveryOrder — JSON round-trip', () {
    test('toJson / fromJson preserves all fields', () {
      final original = DeliveryOrder(
        id: 'order-42',
        platformOrderId: 'GRAB-X001',
        platform: DeliveryPlatform.grab,
        status: DeliveryStatus.preparing,
        customerName: 'Tran Thi B',
        customerPhone: '0901234567',
        deliveryAddress: '123 Main St',
        items: const [
          DeliveryOrderItem(name: 'Pho Bo', quantity: 2, price: 15000),
        ],
        totalAmount: 30000,
        specialInstructions: 'Extra spicy',
        createdAt: DateTime(2024, 6, 15, 10, 0),
        updatedAt: DateTime(2024, 6, 15, 10, 5),
      );

      final json = original.toJson();
      final restored = DeliveryOrder.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.platformOrderId, original.platformOrderId);
      expect(restored.platform, original.platform);
      expect(restored.status, original.status);
      expect(restored.customerName, original.customerName);
      expect(restored.customerPhone, original.customerPhone);
      expect(restored.deliveryAddress, original.deliveryAddress);
      expect(restored.totalAmount, original.totalAmount);
      expect(restored.specialInstructions, original.specialInstructions);
      expect(restored.items.length, 1);
      expect(restored.items.first.name, 'Pho Bo');
      expect(restored.items.first.quantity, 2);
      expect(restored.items.first.price, 15000.0);
    });

    test('fromJson handles missing optional fields gracefully', () {
      final minimalJson = {
        'id': 'min-order',
        'platformOrderId': '',
        'platform': 'manual',
        'status': 'NEW',
        'customerName': 'Unknown',
        'items': <dynamic>[],
        'totalAmount': 0.0,
        'createdAt': '2024-01-01T00:00:00.000',
        'updatedAt': '2024-01-01T00:00:00.000',
      };

      final order = DeliveryOrder.fromJson(minimalJson);
      expect(order.customerPhone, isNull);
      expect(order.deliveryAddress, isNull);
      expect(order.specialInstructions, isNull);
      expect(order.driverInfo, isNull);
      expect(order.estimatedPickupTime, isNull);
      expect(order.items, isEmpty);
    });

    test('toJson produces a valid map with all required keys', () {
      final order = _baseOrder();
      final json = order.toJson();

      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('platformOrderId'), isTrue);
      expect(json.containsKey('platform'), isTrue);
      expect(json.containsKey('status'), isTrue);
      expect(json.containsKey('customerName'), isTrue);
      expect(json.containsKey('items'), isTrue);
      expect(json.containsKey('totalAmount'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
      expect(json.containsKey('updatedAt'), isTrue);
    });
  });

  // ── DeliveryOrderItem ─────────────────────────────────────────────────
  group('DeliveryOrderItem', () {
    test('fromJson parses all fields', () {
      final item = DeliveryOrderItem.fromJson({
        'name': 'Bun Bo',
        'quantity': 3,
        'price': 12000.0,
        'notes': 'No onion',
      });
      expect(item.name, 'Bun Bo');
      expect(item.quantity, 3);
      expect(item.price, 12000.0);
      expect(item.notes, 'No onion');
    });

    test('fromJson handles missing notes (null)', () {
      final item = DeliveryOrderItem.fromJson({
        'name': 'Coffee',
        'quantity': 1,
        'price': 5000.0,
      });
      expect(item.notes, isNull);
    });

    test('toJson round-trips correctly', () {
      const item = DeliveryOrderItem(
        name: 'Spring Roll',
        quantity: 2,
        price: 8000.0,
        notes: 'Extra sauce',
      );
      final json = item.toJson();
      final restored = DeliveryOrderItem.fromJson(json);
      expect(restored.name, item.name);
      expect(restored.quantity, item.quantity);
      expect(restored.price, item.price);
      expect(restored.notes, item.notes);
    });
  });

  // ── DeliveryDriverInfo ────────────────────────────────────────────────
  group('DeliveryDriverInfo', () {
    test('fromJson parses all fields', () {
      final info = DeliveryDriverInfo.fromJson({
        'name': 'John Doe',
        'phone': '0901234567',
        'licensePlate': '51G-12345',
      });
      expect(info.name, 'John Doe');
      expect(info.phone, '0901234567');
      expect(info.licensePlate, '51G-12345');
    });

    test('toJson round-trips correctly', () {
      const info = DeliveryDriverInfo(
        name: 'Jane Smith',
        phone: '0987654321',
        licensePlate: '29A-56789',
      );
      final json = info.toJson();
      final restored = DeliveryDriverInfo.fromJson(json);
      expect(restored.name, info.name);
      expect(restored.phone, info.phone);
      expect(restored.licensePlate, info.licensePlate);
    });
  });

  // ── DeliveryPlatform enum ─────────────────────────────────────────────
  group('DeliveryPlatform', () {
    test('fromString parses grab', () {
      expect(DeliveryPlatform.fromString('grab'), DeliveryPlatform.grab);
    });

    test('fromString parses shopeefood', () {
      expect(DeliveryPlatform.fromString('shopeefood'), DeliveryPlatform.shopeefood);
    });

    test('fromString defaults to manual for unknown value', () {
      expect(DeliveryPlatform.fromString('unknown'), DeliveryPlatform.manual);
    });

    test('each platform has a non-empty displayName', () {
      for (final p in DeliveryPlatform.values) {
        expect(p.displayName, isNotEmpty);
      }
    });

    test('each platform has a non-empty value string', () {
      for (final p in DeliveryPlatform.values) {
        expect(p.value, isNotEmpty);
      }
    });
  });
}

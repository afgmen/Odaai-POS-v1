import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/features/pos/data/models/order_type.dart';

void main() {
  group('OrderType enum values', () {
    test('has exactly 4 order types', () {
      expect(OrderType.values.length, 4);
    });

    test('dineIn properties', () {
      expect(OrderType.dineIn.dbValue, 'dineIn');
      expect(OrderType.dineIn.displayNameEn, 'Dine In');
      expect(OrderType.dineIn.displayNameVi, 'Ăn tại chỗ');
      expect(OrderType.dineIn.color, const Color(0xFF4CAF50));
      expect(OrderType.dineIn.icon, Icons.restaurant);
    });

    test('takeaway properties', () {
      expect(OrderType.takeaway.dbValue, 'takeaway');
      expect(OrderType.takeaway.displayNameEn, 'Takeaway');
      expect(OrderType.takeaway.displayNameVi, 'Mang đi');
      expect(OrderType.takeaway.color, const Color(0xFFFF9800));
      expect(OrderType.takeaway.icon, Icons.shopping_bag_outlined);
    });

    test('phoneDelivery properties', () {
      expect(OrderType.phoneDelivery.dbValue, 'phoneDelivery');
      expect(OrderType.phoneDelivery.displayNameEn, 'Phone Delivery');
      expect(OrderType.phoneDelivery.displayNameVi, 'Giao hàng qua điện thoại');
      expect(OrderType.phoneDelivery.color, const Color(0xFF2196F3));
      expect(OrderType.phoneDelivery.icon, Icons.phone_in_talk);
    });

    test('platformDelivery properties', () {
      expect(OrderType.platformDelivery.dbValue, 'platformDelivery');
      expect(OrderType.platformDelivery.displayNameEn, 'Platform Delivery');
      expect(OrderType.platformDelivery.displayNameVi, 'Giao hàng qua nền tảng');
      expect(OrderType.platformDelivery.color, const Color(0xFF9C27B0));
      expect(OrderType.platformDelivery.icon, Icons.delivery_dining);
    });
  });

  group('OrderType.fromDb', () {
    test('converts all valid db values', () {
      expect(OrderType.fromDb('dineIn'), OrderType.dineIn);
      expect(OrderType.fromDb('takeaway'), OrderType.takeaway);
      expect(OrderType.fromDb('phoneDelivery'), OrderType.phoneDelivery);
      expect(OrderType.fromDb('platformDelivery'), OrderType.platformDelivery);
    });

    test('defaults to dineIn for unknown value', () {
      expect(OrderType.fromDb('unknown'), OrderType.dineIn);
      expect(OrderType.fromDb(''), OrderType.dineIn);
      expect(OrderType.fromDb('DINE_IN'), OrderType.dineIn);
    });

    test('round-trip: dbValue → fromDb', () {
      for (final type in OrderType.values) {
        expect(OrderType.fromDb(type.dbValue), type);
      }
    });
  });

  group('OrderType colors are unique', () {
    test('each order type has a distinct color', () {
      final colors = OrderType.values.map((t) => t.color).toSet();
      expect(colors.length, OrderType.values.length);
    });
  });

  group('OrderType icons are unique', () {
    test('each order type has a distinct icon', () {
      final icons = OrderType.values.map((t) => t.icon).toSet();
      expect(icons.length, OrderType.values.length);
    });
  });

  group('OrderType display names', () {
    test('English names are non-empty', () {
      for (final type in OrderType.values) {
        expect(type.displayNameEn.isNotEmpty, true);
      }
    });

    test('Vietnamese names are non-empty', () {
      for (final type in OrderType.values) {
        expect(type.displayNameVi.isNotEmpty, true);
      }
    });

    test('English names are unique', () {
      final names = OrderType.values.map((t) => t.displayNameEn).toSet();
      expect(names.length, OrderType.values.length);
    });
  });

  group('OrderType dbValue format', () {
    test('all dbValues are camelCase', () {
      for (final type in OrderType.values) {
        // camelCase: starts with lowercase, no underscores, no spaces
        expect(type.dbValue[0], type.dbValue[0].toLowerCase());
        expect(type.dbValue.contains('_'), false);
        expect(type.dbValue.contains(' '), false);
      }
    });
  });
}

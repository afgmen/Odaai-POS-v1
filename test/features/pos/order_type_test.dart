import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';
import 'package:oda_pos/features/pos/data/models/order_type.dart';

/// B-074: Order Type Tests
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Order Type Storage', () {
    test('should save dineIn order type', () async {
      final saleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'DINE-001',
          paymentMethod: 'cash',
          total: const Value(100.0),
          subtotal: const Value(100.0),
          orderType: Value(OrderType.dineIn.dbValue),
        ),
      );

      final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();

      expect(sale.orderType, 'dineIn');
    });

    test('should save takeaway order type', () async {
      final saleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'TAKEAWAY-001',
          paymentMethod: 'card',
          total: const Value(150.0),
          subtotal: const Value(150.0),
          orderType: Value(OrderType.takeaway.dbValue),
        ),
      );

      final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();

      expect(sale.orderType, 'takeaway');
    });

    test('should save phoneDelivery order type', () async {
      final saleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'DELIVERY-001',
          paymentMethod: 'qr',
          total: const Value(200.0),
          subtotal: const Value(200.0),
          orderType: Value(OrderType.phoneDelivery.dbValue),
        ),
      );

      final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();

      expect(sale.orderType, 'phoneDelivery');
    });

    test('should default to dineIn if not specified', () async {
      final saleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'DEFAULT-001',
          paymentMethod: 'cash',
          total: const Value(50.0),
          subtotal: const Value(50.0),
        ),
      );

      final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();

      expect(sale.orderType, 'dineIn');
    });

    test('should save platformDelivery order type', () async {
      final saleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'PLATFORM-001',
          paymentMethod: 'transfer',
          total: const Value(300.0),
          subtotal: const Value(300.0),
          orderType: Value(OrderType.platformDelivery.dbValue),
        ),
      );

      final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();

      expect(sale.orderType, 'platformDelivery');
    });
  });

  group('Order Type Query', () {
    test('should query orders by orderType', () async {
      // Create different order types
      await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'DINE-001',
          paymentMethod: 'cash',
          total: const Value(100.0),
          subtotal: const Value(100.0),
          orderType: Value(OrderType.dineIn.dbValue),
        ),
      );

      await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'TAKEAWAY-001',
          paymentMethod: 'cash',
          total: const Value(150.0),
          subtotal: const Value(150.0),
          orderType: Value(OrderType.takeaway.dbValue),
        ),
      );

      final dineInOrders = await (db.select(db.sales)
            ..where((s) => s.orderType.equals('dineIn')))
          .get();

      expect(dineInOrders.length, 1);
      expect(dineInOrders.first.saleNumber, 'DINE-001');
    });
  });

  group('OrderType Enum', () {
    test('should convert to DB value correctly', () {
      expect(OrderType.dineIn.dbValue, 'dineIn');
      expect(OrderType.takeaway.dbValue, 'takeaway');
      expect(OrderType.phoneDelivery.dbValue, 'phoneDelivery');
      expect(OrderType.platformDelivery.dbValue, 'platformDelivery');
    });

    test('should convert from DB value correctly', () {
      expect(OrderType.fromDb('dineIn'), OrderType.dineIn);
      expect(OrderType.fromDb('takeaway'), OrderType.takeaway);
      expect(OrderType.fromDb('phoneDelivery'), OrderType.phoneDelivery);
      expect(OrderType.fromDb('platformDelivery'), OrderType.platformDelivery);
    });

    test('should default to dineIn for invalid value', () {
      expect(OrderType.fromDb('invalid'), OrderType.dineIn);
    });
  });
}

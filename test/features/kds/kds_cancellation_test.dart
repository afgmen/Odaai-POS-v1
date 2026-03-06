import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';

/// B-071: KDS Order Cancellation Tests
/// Tests for KDS cancellation reason tracking functionality
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('KDS Order Cancellation with Reason', () {
    test('should save cancellation reason when KDS order is cancelled', () async {
      // 1. Create test sale
      final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
        saleNumber: 'TEST-KDS-001',
        paymentMethod: 'cash',
        total: const Value(100.0),
        subtotal: const Value(100.0),
      ));

      // 2. Create kitchen order
      final orderId = await db.into(db.kitchenOrders).insert(KitchenOrdersCompanion.insert(
        saleId: saleId,
        status: const Value('PREPARING'),
      ));

      // 3. Cancel with reason
      const reason = 'Ingredient unavailable';
      final now = DateTime.now();
      
      await (db.update(db.kitchenOrders)..where((t) => t.id.equals(orderId))).write(
        KitchenOrdersCompanion(
          status: const Value('CANCELLED'),
          cancellationReason: const Value(reason),
          cancelledAt: Value(now),
        ),
      );

      // 4. Verify
      final order = await (db.select(db.kitchenOrders)..where((t) => t.id.equals(orderId))).getSingle();
      
      expect(order.status, 'CANCELLED');
      expect(order.cancellationReason, reason);
      expect(order.cancelledAt != null, true);
    });

    test('should accept all predefined KDS cancellation reasons', () async {
      const kdsReasons = [
        'Customer request',
        'Ingredient unavailable',
        'Kitchen overload',
        'Equipment failure',
      ];

      final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
        saleNumber: 'TEST-KDS-MULTI',
        paymentMethod: 'cash',
        total: const Value(100.0),
        subtotal: const Value(100.0),
      ));

      for (final reason in kdsReasons) {
        final orderId = await db.into(db.kitchenOrders).insert(KitchenOrdersCompanion.insert(
          saleId: saleId,
        ));

        await (db.update(db.kitchenOrders)..where((t) => t.id.equals(orderId))).write(
          KitchenOrdersCompanion(
            status: const Value('CANCELLED'),
            cancellationReason: Value(reason),
            cancelledAt: Value(DateTime.now()),
          ),
        );

        final order = await (db.select(db.kitchenOrders)..where((t) => t.id.equals(orderId))).getSingle();
        expect(order.cancellationReason, reason);
      }
    });

    test('should accept custom KDS cancellation reason', () async {
      final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
        saleNumber: 'TEST-KDS-CUSTOM',
        paymentMethod: 'cash',
        total: const Value(100.0),
        subtotal: const Value(100.0),
      ));

      final orderId = await db.into(db.kitchenOrders).insert(KitchenOrdersCompanion.insert(
        saleId: saleId,
      ));

      const customReason = 'Power outage in kitchen area';
      
      await (db.update(db.kitchenOrders)..where((t) => t.id.equals(orderId))).write(
        KitchenOrdersCompanion(
          status: const Value('CANCELLED'),
          cancellationReason: const Value(customReason),
          cancelledAt: Value(DateTime.now()),
        ),
      );

      final order = await (db.select(db.kitchenOrders)..where((t) => t.id.equals(orderId))).getSingle();
      expect(order.cancellationReason, customReason);
    });

    test('should keep cancellationReason null for active orders', () async {
      final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
        saleNumber: 'TEST-KDS-ACTIVE',
        paymentMethod: 'cash',
        total: const Value(100.0),
        subtotal: const Value(100.0),
      ));

      final orderId = await db.into(db.kitchenOrders).insert(KitchenOrdersCompanion.insert(
        saleId: saleId,
        status: const Value('PREPARING'),
      ));

      final order = await (db.select(db.kitchenOrders)..where((t) => t.id.equals(orderId))).getSingle();
      
      expect(order.status, 'PREPARING');
      expect(order.cancellationReason == null, true);
      expect(order.cancelledAt == null, true);
    });

    test('should query all cancelled KDS orders with reasons', () async {
      final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
        saleNumber: 'TEST-KDS-QUERY',
        paymentMethod: 'cash',
        total: const Value(100.0),
        subtotal: const Value(100.0),
      ));

      // Create 3 cancelled orders
      for (int i = 0; i < 3; i++) {
        final orderId = await db.into(db.kitchenOrders).insert(KitchenOrdersCompanion.insert(
          saleId: saleId,
        ));

        await (db.update(db.kitchenOrders)..where((t) => t.id.equals(orderId))).write(
          KitchenOrdersCompanion(
            status: const Value('CANCELLED'),
            cancellationReason: Value('Test reason $i'),
            cancelledAt: Value(DateTime.now()),
          ),
        );
      }

      final cancelledOrders = await (db.select(db.kitchenOrders)
            ..where((t) => t.status.equals('CANCELLED')))
          .get();

      expect(cancelledOrders.length >= 3, true);
      for (final order in cancelledOrders) {
        expect(order.cancellationReason != null, true);
        expect(order.cancelledAt != null, true);
      }
    });
  });
}

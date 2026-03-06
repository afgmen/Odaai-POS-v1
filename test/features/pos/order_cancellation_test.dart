import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';

/// B-070: POS Order Cancellation Tests
/// Tests for cancellation reason tracking functionality
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Order Cancellation with Reason', () {
    test('should save cancellation reason when order is cancelled', () async {
      // 1. Create a test sale
      final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
        saleNumber: 'TEST-001',
        paymentMethod: 'cash',
        total: const Value(100.0),
        subtotal: const Value(100.0),
      ));

      // 2. Cancel the order with reason
      const reason = 'Customer request';
      final now = DateTime.now();
      
      await (db.update(db.sales)..where((t) => t.id.equals(saleId))).write(
        SalesCompanion(
          status: const Value('cancelled'),
          cancellationReason: const Value(reason),
          cancelledAt: Value(now),
        ),
      );

      // 3. Verify cancellation is saved
      final sale = await (db.select(db.sales)..where((t) => t.id.equals(saleId))).getSingle();
      
      expect(sale.status, 'cancelled');
      expect(sale.cancellationReason, reason);
      expect(sale.cancelledAt != null, true);
      expect(sale.cancelledAt!.difference(now).inSeconds < 2, true);
    });

    test('should accept predefined cancellation reasons', () async {
      const predefinedReasons = [
        'Customer request',
        'Wrong order',
        'Kitchen cannot fulfill',
        'Payment issue',
      ];

      for (final reason in predefinedReasons) {
        final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
          saleNumber: 'TEST-${reason.hashCode}',
          paymentMethod: 'cash',
          total: const Value(50.0),
          subtotal: const Value(50.0),
        ));

        await (db.update(db.sales)..where((t) => t.id.equals(saleId))).write(
          SalesCompanion(
            status: const Value('cancelled'),
            cancellationReason: Value(reason),
            cancelledAt: Value(DateTime.now()),
          ),
        );

        final sale = await (db.select(db.sales)..where((t) => t.id.equals(saleId))).getSingle();
        expect(sale.cancellationReason, reason);
      }
    });

    test('should accept custom cancellation reason (Other)', () async {
      final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
        saleNumber: 'TEST-002',
        paymentMethod: 'card',
        total: const Value(200.0),
        subtotal: const Value(200.0),
      ));

      const customReason = 'Customer changed their mind about the spice level';
      
      await (db.update(db.sales)..where((t) => t.id.equals(saleId))).write(
        SalesCompanion(
          status: const Value('cancelled'),
          cancellationReason: const Value(customReason),
          cancelledAt: Value(DateTime.now()),
        ),
      );

      final sale = await (db.select(db.sales)..where((t) => t.id.equals(saleId))).getSingle();
      expect(sale.cancellationReason, customReason);
    });

    test('should keep cancellationReason null for non-cancelled orders', () async {
      final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
        saleNumber: 'TEST-003',
        paymentMethod: 'cash',
        total: const Value(150.0),
        subtotal: const Value(150.0),
        status: const Value('completed'),
      ));

      final sale = await (db.select(db.sales)..where((t) => t.id.equals(saleId))).getSingle();
      
      expect(sale.status, 'completed');
      expect(sale.cancellationReason == null, true);
      expect(sale.cancelledAt == null, true);
    });

    test('should query all cancelled orders with reasons', () async {
      // Create multiple cancelled orders
      for (int i = 0; i < 3; i++) {
        final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
          saleNumber: 'CANCEL-00$i',
          paymentMethod: 'cash',
          total: Value(100.0 * (i + 1)),
          subtotal: Value(100.0 * (i + 1)),
        ));

        await (db.update(db.sales)..where((t) => t.id.equals(saleId))).write(
          SalesCompanion(
            status: const Value('cancelled'),
            cancellationReason: Value('Test reason $i'),
            cancelledAt: Value(DateTime.now()),
          ),
        );
      }

      // Query all cancelled orders
      final cancelledOrders = await (db.select(db.sales)
            ..where((t) => t.status.equals('cancelled')))
          .get();

      expect(cancelledOrders.length, 3);
      for (final order in cancelledOrders) {
        expect(order.cancellationReason != null, true);
        expect(order.cancelledAt != null, true);
      }
    });
  });
}

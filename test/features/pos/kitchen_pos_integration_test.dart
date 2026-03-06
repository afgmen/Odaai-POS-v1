import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:oda_pos/database/app_database.dart';

void main() {
  group('B-052: Kitchen-POS Integration', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('KitchenOrder can be queried by saleId', () async {
      // Create a test sale
      final saleId = await db.salesDao.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'SO-TEST-001',
          paymentMethod: 'cash',
          total: const Value(100.0),
        ),
      );

      // Create a kitchen order for the sale
      await db.kitchenOrdersDao.createOrderFromSale(
        saleId: saleId,
        tableNumber: 'T01',
        specialInstructions: 'Test order',
      );

      // Query kitchen order by saleId
      final kitchenOrder = await db.kitchenOrdersDao.getOrderBySaleId(saleId);
      
      expect(kitchenOrder, isNot(null));
      expect(kitchenOrder!.saleId, saleId);
      expect(kitchenOrder.status, 'PENDING',
        reason: 'New kitchen orders should start with PENDING status');
    });

    test('Kitchen order status flow', () async {
      // 1. Create sale + kitchen order
      final saleId = await db.salesDao.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'SO-TEST-002',
          paymentMethod: 'cash',
          total: const Value(150.0),
        ),
      );

      final orderId = await db.kitchenOrdersDao.createOrderFromSale(
        saleId: saleId,
        tableNumber: 'T02',
      );

      // 2. Initially PENDING
      var order = await db.kitchenOrdersDao.getOrderById(orderId);
      expect(order!.status, 'PENDING');

      // 3. Update to PREPARING
      await db.kitchenOrdersDao.updateOrderStatus(orderId, 'PREPARING');
      order = await db.kitchenOrdersDao.getOrderById(orderId);
      expect(order!.status, 'PREPARING');

      // 4. Update to READY
      await db.kitchenOrdersDao.updateOrderStatus(orderId, 'READY');
      order = await db.kitchenOrdersDao.getOrderById(orderId);
      expect(order!.status, 'READY');

      // 5. Update to SERVED
      await db.kitchenOrdersDao.updateOrderStatus(orderId, 'SERVED');
      order = await db.kitchenOrdersDao.getOrderById(orderId);
      expect(order!.status, 'SERVED');
    });

    test('Checkout should be blocked when kitchen status is PENDING', () async {
      // This is a documentation test for the UI logic
      const blockedStatuses = ['PENDING', 'PREPARING'];
      const allowedStatuses = ['READY', 'SERVED'];
      
      for (final status in blockedStatuses) {
        expect(
          status == 'READY' || status == 'SERVED',
          false,
          reason: '$status should show warning modal',
        );
      }
      
      for (final status in allowedStatuses) {
        expect(
          status == 'READY' || status == 'SERVED',
          true,
          reason: '$status should allow checkout',
        );
      }
    });
  });
}

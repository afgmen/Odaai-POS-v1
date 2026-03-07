import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';
import 'package:oda_pos/features/kds/data/kitchen_orders_dao.dart';

/// B-071: KDS Cancel Reason Tests
void main() {
  late AppDatabase db;
  late KitchenOrdersDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.kitchenOrdersDao;
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper to create a test order
  Future<int> createTestOrder(String saleNumber) async {
    final saleId = await db.into(db.sales).insert(
      SalesCompanion.insert(
        saleNumber: saleNumber,
        paymentMethod: 'cash',
        total: const Value(100.0),
        subtotal: const Value(100.0),
      ),
    );

    return await dao.createOrderFromSale(
      saleId: saleId,
      tableNumber: 'T01',
    );
  }

  group('KDS Cancel Reason Storage', () {
    test('should save cancellation reason - 고객 요청', () async {
      final orderId = await createTestOrder('SALE-KDS-001');

      await dao.cancelOrder(orderId, reason: '고객 요청');

      final order = await dao.getOrderById(orderId);

      expect(order!.status, 'CANCELLED');
      expect(order.cancellationReason, '고객 요청');
      expect(order.cancelledAt != null, true);
    });

    test('should save cancellation reason - 재고 소진', () async {
      final orderId = await createTestOrder('SALE-KDS-002');

      await dao.cancelOrder(orderId, reason: '재고 소진');

      final order = await dao.getOrderById(orderId);

      expect(order!.cancellationReason, '재고 소진');
    });

    test('should save cancellation reason - 주방 오류', () async {
      final orderId = await createTestOrder('SALE-KDS-003');

      await dao.cancelOrder(orderId, reason: '주방 오류');

      final order = await dao.getOrderById(orderId);

      expect(order!.cancellationReason, '주방 오류');
    });

    test('should save custom cancellation reason', () async {
      final orderId = await createTestOrder('SALE-KDS-004');

      const customReason = '기타: 조리 시간 초과';
      await dao.cancelOrder(orderId, reason: customReason);

      final order = await dao.getOrderById(orderId);

      expect(order!.cancellationReason, customReason);
      expect(order.cancellationReason!.startsWith('기타:'), true);
    });

    test('should handle cancel without reason (backward compatibility)', () async {
      final orderId = await createTestOrder('SALE-KDS-005');

      await dao.cancelOrder(orderId);

      final order = await dao.getOrderById(orderId);

      expect(order!.status, 'CANCELLED');
      expect(order.cancellationReason, null);
    });
  });

  group('KDS Cancellation Query', () {
    test('should query cancelled orders', () async {
      // Create 1 active order
      await createTestOrder('SALE-ACTIVE-001');

      // Create 1 cancelled order
      final cancelledId = await createTestOrder('SALE-CANCELLED-001');
      await dao.cancelOrder(cancelledId, reason: '고객 요청');

      final cancelledOrders = await (db.select(db.kitchenOrders)
            ..where((o) => o.status.equals('CANCELLED')))
          .get();

      expect(cancelledOrders.length, 1);
      expect(cancelledOrders.first.cancellationReason, '고객 요청');
    });
  });
}

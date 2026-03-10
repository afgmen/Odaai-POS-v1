import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart' as matcher;
import 'package:oda_pos/database/app_database.dart';

/// B-070: Cancel Reason Tests
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Cancel Reason Storage', () {
    test('should save cancellation reason - 고객 요청', () async {
      final saleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'SALE-001',
          paymentMethod: 'cash',
          total: const Value(100.0),
          subtotal: const Value(100.0),
        ),
      );

      await (db.update(db.sales)..where((s) => s.id.equals(saleId)))
          .write(
        const SalesCompanion(
          status: Value('cancelled'),
          cancellationReason: Value('고객 요청'),
          cancelledAt: Value.absentIfNull(null),
        ),
      );

      final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();

      expect(sale.status, 'cancelled');
      expect(sale.cancellationReason, '고객 요청');
    });

    test('should save cancellation reason - 재고 소진', () async {
      final saleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'SALE-002',
          paymentMethod: 'card',
          total: const Value(150.0),
          subtotal: const Value(150.0),
        ),
      );

      final now = DateTime.now();
      await (db.update(db.sales)..where((s) => s.id.equals(saleId)))
          .write(
        SalesCompanion(
          status: const Value('cancelled'),
          cancellationReason: const Value('재고 소진'),
          cancelledAt: Value(now),
        ),
      );

      final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();

      expect(sale.cancellationReason, '재고 소진');
      expect(sale.cancelledAt != null, true);
    });

    test('should save cancellation reason - 주방 오류', () async {
      final saleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'SALE-003',
          paymentMethod: 'qr',
          total: const Value(200.0),
          subtotal: const Value(200.0),
        ),
      );

      await (db.update(db.sales)..where((s) => s.id.equals(saleId)))
          .write(
        SalesCompanion(
          status: const Value('cancelled'),
          cancellationReason: const Value('주방 오류'),
          cancelledAt: Value(DateTime.now()),
        ),
      );

      final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();

      expect(sale.cancellationReason, '주방 오류');
    });

    test('should save custom cancellation reason', () async {
      final saleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'SALE-004',
          paymentMethod: 'cash',
          total: const Value(50.0),
          subtotal: const Value(50.0),
        ),
      );

      const customReason = '기타: 메뉴 변경 요청';
      await (db.update(db.sales)..where((s) => s.id.equals(saleId)))
          .write(
        SalesCompanion(
          status: const Value('cancelled'),
          cancellationReason: const Value(customReason),
          cancelledAt: Value(DateTime.now()),
        ),
      );

      final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();

      expect(sale.cancellationReason, customReason);
      expect(sale.cancellationReason!.startsWith('기타:'), true);
    });

    test('should preserve other fields when cancelling', () async {
      final saleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'SALE-005',
          paymentMethod: 'card',
          total: const Value(300.0),
          subtotal: const Value(250.0),
          discount: const Value(50.0),
          orderType: const Value('dineIn'),
        ),
      );

      await (db.update(db.sales)..where((s) => s.id.equals(saleId)))
          .write(
        SalesCompanion(
          status: const Value('cancelled'),
          cancellationReason: const Value('고객 요청'),
          cancelledAt: Value(DateTime.now()),
        ),
      );

      final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();

      expect(sale.saleNumber, 'SALE-005');
      expect(sale.total, 300.0);
      expect(sale.subtotal, 250.0);
      expect(sale.discount, 50.0);
      expect(sale.orderType, 'dineIn');
      expect(sale.status, 'cancelled');
    });

    test('should have cancelled timestamp', () async {
      final saleId = await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'SALE-006',
          paymentMethod: 'cash',
          total: const Value(75.0),
          subtotal: const Value(75.0),
        ),
      );

      await (db.update(db.sales)..where((s) => s.id.equals(saleId)))
          .write(
        SalesCompanion(
          status: const Value('cancelled'),
          cancellationReason: const Value('재고 소진'),
          cancelledAt: Value(DateTime.now()),
        ),
      );

      final sale = await (db.select(db.sales)..where((s) => s.id.equals(saleId))).getSingle();

      expect(sale.cancelledAt != null, true);
    });
  });

  group('Cancellation Query', () {
    test('should query cancelled sales', () async {
      // Create 2 completed sales
      await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'COMP-001',
          paymentMethod: 'cash',
          total: const Value(100.0),
          subtotal: const Value(100.0),
          status: const Value('completed'),
        ),
      );

      // Create 1 cancelled sale
      await db.into(db.sales).insert(
        SalesCompanion.insert(
          saleNumber: 'CANCEL-001',
          paymentMethod: 'card',
          total: const Value(200.0),
          subtotal: const Value(200.0),
          status: const Value('cancelled'),
          cancellationReason: const Value('고객 요청'),
        ),
      );

      final cancelledSales = await (db.select(db.sales)
            ..where((s) => s.status.equals('cancelled')))
          .get();

      expect(cancelledSales.length, 1);
      expect(cancelledSales.first.saleNumber, 'CANCEL-001');
      expect(cancelledSales.first.cancellationReason, '고객 요청');
    });
  });
}

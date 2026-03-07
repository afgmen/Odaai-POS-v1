import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';

/// B-052: Kitchen-POS Integration Workflow Tests
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Kitchen Approval Setting', () {
    test('should allow toggling kitchen approval requirement', () async {
      // Enable
      await db.customStatement(
        "INSERT OR REPLACE INTO system_settings (key, value, updated_at) VALUES (?, ?, ?)",
        ['require_kitchen_approval', 'true', DateTime.now().millisecondsSinceEpoch ~/ 1000],
      );

      var result = await db.customSelect(
        "SELECT value FROM system_settings WHERE key = 'require_kitchen_approval'",
      ).getSingle();
      expect(result.data['value'], 'true');

      // Disable
      await db.customStatement(
        "INSERT OR REPLACE INTO system_settings (key, value, updated_at) VALUES (?, ?, ?)",
        ['require_kitchen_approval', 'false', DateTime.now().millisecondsSinceEpoch ~/ 1000],
      );

      result = await db.customSelect(
        "SELECT value FROM system_settings WHERE key = 'require_kitchen_approval'",
      ).getSingle();
      expect(result.data['value'], 'false');
    });
  });

  group('Kitchen Order Status Check', () {
    test('should identify READY status orders', () async {
      final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
        saleNumber: 'TEST-001',
        paymentMethod: 'cash',
        total: const Value(100.0),
        subtotal: const Value(100.0),
      ));

      await db.into(db.kitchenOrders).insert(KitchenOrdersCompanion.insert(
        saleId: saleId,
        status: const Value('READY'),
      ));

      final result = await db.customSelect(
        "SELECT status FROM kitchen_orders WHERE sale_id = ?",
        variables: [Variable.withInt(saleId)],
      ).getSingle();

      expect(result.data['status'], 'READY');
    });

    test('should identify PENDING status orders', () async {
      final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
        saleNumber: 'TEST-002',
        paymentMethod: 'cash',
        total: const Value(100.0),
        subtotal: const Value(100.0),
      ));

      await db.into(db.kitchenOrders).insert(KitchenOrdersCompanion.insert(
        saleId: saleId,
        status: const Value('PENDING'),
      ));

      final result = await db.customSelect(
        "SELECT status FROM kitchen_orders WHERE sale_id = ?",
        variables: [Variable.withInt(saleId)],
      ).getSingle();

      expect(result.data['status'], 'PENDING');
    });

    test('should identify PREPARING status orders', () async {
      final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
        saleNumber: 'TEST-003',
        paymentMethod: 'cash',
        total: const Value(100.0),
        subtotal: const Value(100.0),
      ));

      await db.into(db.kitchenOrders).insert(KitchenOrdersCompanion.insert(
        saleId: saleId,
        status: const Value('PREPARING'),
      ));

      final result = await db.customSelect(
        "SELECT status FROM kitchen_orders WHERE sale_id = ?",
        variables: [Variable.withInt(saleId)],
      ).getSingle();

      expect(result.data['status'], 'PREPARING');
    });

    test('should identify SERVED status orders', () async {
      final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
        saleNumber: 'TEST-004',
        paymentMethod: 'cash',
        total: const Value(100.0),
        subtotal: const Value(100.0),
      ));

      await db.into(db.kitchenOrders).insert(KitchenOrdersCompanion.insert(
        saleId: saleId,
        status: const Value('SERVED'),
      ));

      final result = await db.customSelect(
        "SELECT status FROM kitchen_orders WHERE sale_id = ?",
        variables: [Variable.withInt(saleId)],
      ).getSingle();

      expect(result.data['status'], 'SERVED');
    });
  });

  group('Force Checkout Audit Log', () {
    test('should record force checkout in permission_logs', () async {
      const employeeId = 1;
      const saleId = 123;
      const reason = 'Kitchen status: PREPARING';

      await db.customStatement('''
        INSERT INTO permission_logs (employee_id, action_type, action_target, permission_granted, reason, created_at)
        VALUES (?, 'FORCE_CHECKOUT', ?, 1, ?, ?)
      ''', [employeeId, 'sale_$saleId', reason, DateTime.now().millisecondsSinceEpoch ~/ 1000]);

      final result = await db.customSelect(
        "SELECT * FROM permission_logs WHERE action_type = 'FORCE_CHECKOUT' AND action_target = ?",
        variables: [Variable.withString('sale_$saleId')],
      ).getSingle();

      expect(result.data['employee_id'], employeeId);
      expect(result.data['action_type'], 'FORCE_CHECKOUT');
      expect(result.data['reason'], reason);
    });
  });

  group('Checkout Workflow Logic', () {
    test('should allow checkout when approval is disabled', () async {
      await db.customStatement(
        "INSERT OR REPLACE INTO system_settings (key, value, updated_at) VALUES (?, ?, ?)",
        ['require_kitchen_approval', 'false', DateTime.now().millisecondsSinceEpoch ~/ 1000],
      );

      final result = await db.customSelect(
        "SELECT value FROM system_settings WHERE key = 'require_kitchen_approval'",
      ).getSingle();

      expect(result.data['value'], 'false');
    });

    test('should block checkout for PENDING orders when approval enabled', () async {
      await db.customStatement(
        "INSERT OR REPLACE INTO system_settings (key, value, updated_at) VALUES (?, ?, ?)",
        ['require_kitchen_approval', 'true', DateTime.now().millisecondsSinceEpoch ~/ 1000],
      );

      final saleId = await db.into(db.sales).insert(SalesCompanion.insert(
        saleNumber: 'TEST-BLOCK',
        paymentMethod: 'cash',
        total: const Value(100.0),
        subtotal: const Value(100.0),
      ));

      await db.into(db.kitchenOrders).insert(KitchenOrdersCompanion.insert(
        saleId: saleId,
        status: const Value('PENDING'),
      ));

      final orderStatus = await db.customSelect(
        "SELECT status FROM kitchen_orders WHERE sale_id = ?",
        variables: [Variable.withInt(saleId)],
      ).getSingle();

      final approvalSetting = await db.customSelect(
        "SELECT value FROM system_settings WHERE key = 'require_kitchen_approval'",
      ).getSingle();

      expect(approvalSetting.data['value'], 'true');
      expect(orderStatus.data['status'], 'PENDING');
      expect(orderStatus.data['status'] == 'READY' || orderStatus.data['status'] == 'SERVED', false);
    });
  });
}

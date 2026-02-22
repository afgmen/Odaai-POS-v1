import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import '../../../database/app_database.dart' hide DeliveryOrder;
import 'delivery_orders_dao.dart';
import 'models/delivery_order.dart';
import '../domain/enums/delivery_platform.dart';
import '../domain/enums/delivery_status.dart';

/// Repository for delivery orders.
/// Converts between Drift DB rows and the app-level DeliveryOrder model.
class DeliveryOrdersRepository {
  final DeliveryOrdersDao _dao;

  DeliveryOrdersRepository(this._dao);

  // ──────────────────────────────────────────────
  // CREATE
  // ──────────────────────────────────────────────

  Future<int> saveOrder(DeliveryOrder order) {
    return _dao.insertOrder(_toCompanion(order));
  }

  // ──────────────────────────────────────────────
  // READ
  // ──────────────────────────────────────────────

  Stream<List<DeliveryOrder>> watchAllOrders() {
    return _dao.watchAllOrders().map((rows) => rows.map(_fromRow).toList());
  }

  Stream<List<DeliveryOrder>> watchActiveOrders() {
    return _dao.watchActiveOrders().map((rows) => rows.map(_fromRow).toList());
  }

  Stream<List<DeliveryOrder>> watchOrdersByPlatform(DeliveryPlatform platform) {
    return _dao
        .watchOrdersByPlatform(platform.value)
        .map((rows) => rows.map(_fromRow).toList());
  }

  Stream<List<DeliveryOrder>> watchOrdersByStatus(DeliveryStatus status) {
    return _dao
        .watchOrdersByStatus(status.value)
        .map((rows) => rows.map(_fromRow).toList());
  }

  Stream<int> watchNewOrderCount() => _dao.watchNewOrderCount();

  /// Find the delivery order that was created when a KDS order was accepted.
  Future<DeliveryOrder?> getOrderByKitchenOrderId(int kitchenOrderId) async {
    final row = await _dao.getOrderByKitchenOrderId(kitchenOrderId);
    if (row == null) return null;
    return _mapRow(row);
  }

  // ──────────────────────────────────────────────
  // UPDATE
  // ──────────────────────────────────────────────

  Future<bool> updateStatus(int id, DeliveryStatus status) {
    return _dao.updateStatus(id, status.value);
  }

  Future<bool> updateDriverInfo(int id, DeliveryDriverInfo? driver) {
    final json = driver != null ? jsonEncode(driver.toJson()) : null;
    return _dao.updateDriverInfo(id, json);
  }

  Future<bool> linkKitchenOrder(int deliveryOrderId, int kitchenOrderId) {
    return _dao.linkKitchenOrder(deliveryOrderId, kitchenOrderId);
  }

  // ──────────────────────────────────────────────
  // STATISTICS
  // ──────────────────────────────────────────────

  Future<Map<String, int>> getCountByStatus() async {
    final newCount = await _dao.countByStatus('NEW');
    final accepted = await _dao.countByStatus('ACCEPTED');
    final preparing = await _dao.countByStatus('PREPARING');
    final ready = await _dao.countByStatus('READY_FOR_PICKUP');
    final pickedUp = await _dao.countByStatus('PICKED_UP');
    final completed = await _dao.countByStatus('COMPLETED');
    final cancelled = await _dao.countByStatus('CANCELLED');
    return {
      'NEW': newCount,
      'ACCEPTED': accepted,
      'PREPARING': preparing,
      'READY_FOR_PICKUP': ready,
      'PICKED_UP': pickedUp,
      'COMPLETED': completed,
      'CANCELLED': cancelled,
    };
  }

  // ──────────────────────────────────────────────
  // Conversion helpers
  // ──────────────────────────────────────────────

  DeliveryOrder _fromRow(dynamic row) {
    return _mapRow(row);
  }

  DeliveryOrder _mapRow(dynamic row) {
    final List<dynamic> rawItems =
        jsonDecode(row.itemsJson as String) as List<dynamic>;
    final items = rawItems
        .map((e) => DeliveryOrderItem.fromJson(e as Map<String, dynamic>))
        .toList();

    DeliveryDriverInfo? driverInfo;
    if (row.driverInfoJson != null) {
      try {
        driverInfo = DeliveryDriverInfo.fromJson(
          jsonDecode(row.driverInfoJson as String) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    return DeliveryOrder(
      id: row.id.toString(),
      platformOrderId: row.platformOrderId as String,
      platform: DeliveryPlatform.fromString(row.platform as String),
      status: DeliveryStatus.fromString(row.status as String),
      customerName: row.customerName as String,
      customerPhone: row.customerPhone as String?,
      deliveryAddress: row.deliveryAddress as String?,
      items: items,
      totalAmount: (row.totalAmount as num).toDouble(),
      specialInstructions: row.specialInstructions as String?,
      estimatedPickupTime: row.estimatedPickupTime as DateTime?,
      driverInfo: driverInfo,
      createdAt: row.createdAt as DateTime,
      updatedAt: row.updatedAt as DateTime,
    );
  }

  DeliveryOrdersCompanion _toCompanion(DeliveryOrder order) {
    return DeliveryOrdersCompanion.insert(
      platformOrderId: order.platformOrderId,
      platform: order.platform.value,
      status: Value(order.status.value),
      customerName: order.customerName,
      customerPhone: Value(order.customerPhone),
      deliveryAddress: Value(order.deliveryAddress),
      itemsJson: jsonEncode(order.items.map((e) => e.toJson()).toList()),
      totalAmount: order.totalAmount,
      specialInstructions: Value(order.specialInstructions),
      estimatedPickupTime: Value(order.estimatedPickupTime),
      driverInfoJson: Value(
        order.driverInfo != null
            ? jsonEncode(order.driverInfo!.toJson())
            : null,
      ),
    );
  }
}

import 'package:drift/drift.dart';
import 'kitchen_orders.dart';
import 'sales.dart';

/// Delivery orders table — stores orders received from delivery platforms
/// (GrabFood, ShopeeFood, manual).
class DeliveryOrders extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// B-124: POS 결제 시 생성된 Sale과 연결 (nullable — 외부 플랫폼 주문은 null)
  IntColumn get saleId =>
      integer().nullable().references(Sales, #id, onDelete: KeyAction.setNull)();

  /// Platform's own order identifier (e.g. GrabFood order ID).
  TextColumn get platformOrderId => text()();

  /// Platform: 'grab' | 'shopeefood' | 'manual'
  TextColumn get platform => text()();

  /// Status: 'NEW' | 'ACCEPTED' | 'PREPARING' | 'READY_FOR_PICKUP'
  ///         | 'PICKED_UP' | 'COMPLETED' | 'CANCELLED'
  TextColumn get status => text().withDefault(const Constant('NEW'))();

  TextColumn get customerName => text()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get deliveryAddress => text().nullable()();

  /// JSON-encoded `List<DeliveryOrderItem>`
  TextColumn get itemsJson => text()();

  RealColumn get totalAmount => real()();

  TextColumn get specialInstructions => text().nullable()();
  DateTimeColumn get estimatedPickupTime => dateTime().nullable()();

  /// JSON-encoded DeliveryDriverInfo | null
  TextColumn get driverInfoJson => text().nullable()();

  /// Optional link to a KDS kitchen order created when this order is accepted.
  IntColumn get kitchenOrderId =>
      integer().nullable().references(KitchenOrders, #id)();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

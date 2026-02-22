import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/database_providers.dart';
import 'delivery_orders_dao.dart';
import 'delivery_orders_repository.dart';
import 'models/delivery_order.dart';
import '../domain/enums/delivery_platform.dart';
import '../domain/enums/delivery_status.dart';

// ──────────────────────────────────────────────
// DAO
// ──────────────────────────────────────────────

final deliveryOrdersDaoProvider = Provider<DeliveryOrdersDao>((ref) {
  final db = ref.watch(databaseProvider);
  return db.deliveryOrdersDao;
});

// ──────────────────────────────────────────────
// Repository
// ──────────────────────────────────────────────

final deliveryOrdersRepositoryProvider =
    Provider<DeliveryOrdersRepository>((ref) {
  final dao = ref.watch(deliveryOrdersDaoProvider);
  return DeliveryOrdersRepository(dao);
});

// ──────────────────────────────────────────────
// Stream providers
// ──────────────────────────────────────────────

/// All delivery orders stream (newest first).
final allDeliveryOrdersProvider =
    StreamProvider<List<DeliveryOrder>>((ref) {
  final repo = ref.watch(deliveryOrdersRepositoryProvider);
  return repo.watchAllOrders();
});

/// Active delivery orders stream (NEW, ACCEPTED, PREPARING, READY_FOR_PICKUP).
final activeDeliveryOrdersProvider =
    StreamProvider<List<DeliveryOrder>>((ref) {
  final repo = ref.watch(deliveryOrdersRepositoryProvider);
  return repo.watchActiveOrders();
});

/// Orders filtered by platform.
final deliveryOrdersByPlatformProvider =
    StreamProvider.family<List<DeliveryOrder>, DeliveryPlatform>(
        (ref, platform) {
  final repo = ref.watch(deliveryOrdersRepositoryProvider);
  return repo.watchOrdersByPlatform(platform);
});

/// Orders filtered by status.
final deliveryOrdersByStatusProvider =
    StreamProvider.family<List<DeliveryOrder>, DeliveryStatus>(
        (ref, status) {
  final repo = ref.watch(deliveryOrdersRepositoryProvider);
  return repo.watchOrdersByStatus(status);
});

/// Count of NEW orders for the navigation badge.
final newDeliveryOrderCountProvider = StreamProvider<int>((ref) {
  final dao = ref.watch(deliveryOrdersDaoProvider);
  return dao.watchNewOrderCount();
});

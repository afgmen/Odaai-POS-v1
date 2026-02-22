import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../../data/delivery_orders_repository.dart';
import '../../data/models/delivery_order.dart';
import '../enums/delivery_status.dart';
import 'websocket_service.dart';
import '../../../kds/domain/services/kitchen_service.dart';

/// Business logic for delivery orders.
///
/// Handles:
///   - Accepting / rejecting new orders
///   - Status transitions
///   - Creating KDS kitchen orders when a delivery order is accepted
///   - Audio notifications (reuses KDS pattern)
class DeliveryService {
  final DeliveryOrdersRepository _repository;
  final DeliveryWebSocketService _wsService;
  final KitchenService _kitchenService;
  final AudioPlayer _audioPlayer = AudioPlayer();

  DeliveryService({
    required DeliveryOrdersRepository repository,
    required DeliveryWebSocketService wsService,
    required KitchenService kitchenService,
  })  : _repository = repository,
        _wsService = wsService,
        _kitchenService = kitchenService;

  // ──────────────────────────────────────────────
  // Order lifecycle
  // ──────────────────────────────────────────────

  /// Persist a new incoming order and play notification sound.
  Future<int> receiveOrder(DeliveryOrder order) async {
    final id = await _repository.saveOrder(order);
    await _playNewOrderSound();
    return id;
  }

  /// Accept a delivery order:
  ///   1. Update local status to ACCEPTED
  ///   2. Send WebSocket command to server (→ GrabFood API)
  ///   3. Create a KDS kitchen order so kitchen staff see it
  Future<bool> acceptOrder(int localId, DeliveryOrder order) async {
    final success = await _repository.updateStatus(
      localId,
      DeliveryStatus.accepted,
    );
    if (!success) return false;

    // Send command to middleware server
    _wsService.acceptOrder(order.id);

    // Create KDS order — use a fake saleId of 0 for delivery orders
    // (delivery orders don't have a POS sale attached)
    try {
      final kitchenOrderId = await _kitchenService.createOrderFromSale(
        saleId: 0,
        tableNumber: 'Delivery #${order.platformOrderId}',
        specialInstructions: order.specialInstructions,
      );
      await _repository.linkKitchenOrder(localId, kitchenOrderId);
    } catch (e) {
      debugPrint('[DeliveryService] Failed to create KDS order: $e');
    }

    return true;
  }

  /// Reject a delivery order.
  Future<bool> rejectOrder(
    int localId,
    DeliveryOrder order, {
    String reason = 'Rejected by merchant',
  }) async {
    final success = await _repository.updateStatus(
      localId,
      DeliveryStatus.cancelled,
    );
    if (!success) return false;

    _wsService.rejectOrder(order.id, reason: reason);
    return true;
  }

  /// Advance the order to the next status.
  Future<bool> advanceStatus(int localId, DeliveryOrder order) async {
    final next = order.status.nextStatus;
    if (next == null) return false;
    return updateStatus(localId, order, next);
  }

  /// Update to a specific status.
  Future<bool> updateStatus(
    int localId,
    DeliveryOrder order,
    DeliveryStatus newStatus,
  ) async {
    final success = await _repository.updateStatus(localId, newStatus);
    if (!success) return false;

    _wsService.updateStatus(order.id, newStatus.value);

    if (newStatus == DeliveryStatus.readyForPickup) {
      await _playReadySound();
    }

    return true;
  }

  // ──────────────────────────────────────────────
  // KDS → Delivery bridge
  // ──────────────────────────────────────────────

  /// Called by the KDS status-change listener when a kitchen order status
  /// changes. If that kitchen order is linked to a delivery order, the new
  /// KDS status is forwarded to the middleware server so it can push the
  /// corresponding status to the delivery platform (GrabFood etc.).
  ///
  /// [kitchenOrderId]  The KDS order's local DB id.
  /// [kdsStatus]       The new KDS OrderStatus value string (e.g. 'PREPARING').
  Future<void> notifyKdsStatusChanged(int kitchenOrderId, String kdsStatus) async {
    try {
      final deliveryOrder =
          await _repository.getOrderByKitchenOrderId(kitchenOrderId);
      if (deliveryOrder == null) {
        // This kitchen order has no linked delivery order — nothing to do.
        return;
      }

      debugPrint(
        '[DeliveryService] KDS $kitchenOrderId → $kdsStatus, '
        'forwarding to delivery order ${deliveryOrder.id}',
      );

      // Fire-and-forget to the middleware server via WebSocket.
      _wsService.notifyKdsStatusUpdate(deliveryOrder.id, kdsStatus);
    } catch (e) {
      debugPrint('[DeliveryService] notifyKdsStatusChanged error: $e');
    }
  }

  // ──────────────────────────────────────────────
  // Audio notifications (reuse KDS pattern)
  // ──────────────────────────────────────────────

  Future<void> _playNewOrderSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/new_order.mp3'));
    } catch (e) {
      debugPrint('[DeliveryService] Failed to play new order sound: $e');
    }
  }

  Future<void> _playReadySound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/order_ready.mp3'));
    } catch (e) {
      debugPrint('[DeliveryService] Failed to play ready sound: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

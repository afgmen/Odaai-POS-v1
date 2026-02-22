'use strict';

const { DeliveryStatus, DeliveryPlatform } = require('../models/delivery-order');
const grabConnector = require('../connectors/grab/grab-connector');
const wsService = require('./websocket-service');
const { pushStatusWithRetry, mapKdsStatusToDeliveryStatus } = require('./status-push-service');
const logger = require('../utils/logger');

/**
 * In-memory order store.
 * Key: internal order id → DeliveryOrder
 *
 * In production you would replace this with a database (Redis / SQLite / etc.)
 * @type {Map<string, import('../models/delivery-order').DeliveryOrder>}
 */
const orderStore = new Map();

// ──────────────────────────────────────────────
// Internal helpers
// ──────────────────────────────────────────────

function _getConnector(platform) {
  switch (platform) {
    case DeliveryPlatform.GRAB:
      return grabConnector;
    default:
      return null; // Manual orders have no outbound connector
  }
}

// ──────────────────────────────────────────────
// Public API
// ──────────────────────────────────────────────

/**
 * Store a new incoming order (from webhook) and broadcast to tablets.
 * @param {import('../models/delivery-order').DeliveryOrder} order
 */
function receiveOrder(order) {
  orderStore.set(order.id, order);
  wsService.broadcastNewOrder(order);
  logger.info(`[OrderService] New order received: ${order.id} (${order.platform})`);
  return order;
}

/**
 * Return all orders (newest first).
 */
function getAllOrders() {
  return [...orderStore.values()].sort(
    (a, b) => new Date(b.createdAt) - new Date(a.createdAt),
  );
}

/**
 * Return a single order by internal id.
 * @param {string} orderId
 */
function getOrder(orderId) {
  return orderStore.get(orderId) || null;
}

/**
 * Accept an order: update status, call platform API, broadcast.
 * @param {string} orderId – internal order id
 */
async function acceptOrder(orderId) {
  const order = orderStore.get(orderId);
  if (!order) throw new Error(`Order not found: ${orderId}`);
  if (order.status !== DeliveryStatus.NEW) {
    throw new Error(`Cannot accept order in status ${order.status}`);
  }

  order.status = DeliveryStatus.ACCEPTED;
  order.updatedAt = new Date();
  orderStore.set(orderId, order);

  const connector = _getConnector(order.platform);
  if (connector) {
    await connector.acceptOrder(order.platformOrderId);
  }

  wsService.broadcastOrderUpdated(order);
  logger.info(`[OrderService] Order accepted: ${orderId}`);
  return order;
}

/**
 * Reject an order: update status, call platform API, broadcast.
 * @param {string} orderId
 * @param {string} reason
 */
async function rejectOrder(orderId, reason) {
  const order = orderStore.get(orderId);
  if (!order) throw new Error(`Order not found: ${orderId}`);
  if (order.status !== DeliveryStatus.NEW) {
    throw new Error(`Cannot reject order in status ${order.status}`);
  }

  order.status = DeliveryStatus.CANCELLED;
  order.updatedAt = new Date();
  orderStore.set(orderId, order);

  const connector = _getConnector(order.platform);
  if (connector) {
    await connector.rejectOrder(order.platformOrderId, reason);
  }

  wsService.broadcastOrderCancelled(orderId, reason);
  logger.info(`[OrderService] Order rejected: ${orderId} — ${reason}`);
  return order;
}

/**
 * Update order status.
 * Platform API call uses fire-and-forget retry (does not block the response).
 * @param {string} orderId
 * @param {string} newStatus – DeliveryStatus value
 */
async function updateStatus(orderId, newStatus) {
  const order = orderStore.get(orderId);
  if (!order) throw new Error(`Order not found: ${orderId}`);

  const previousStatus = order.status;
  order.status = newStatus;
  order.updatedAt = new Date();
  orderStore.set(orderId, order);

  const connector = _getConnector(order.platform);
  if (connector) {
    // Fire-and-forget with retry — do not await, so the WS response is immediate.
    pushStatusWithRetry({
      platformOrderId: order.platformOrderId,
      platform: order.platform,
      newStatus,
      connectorFn: (pid, status) => connector.updateOrderStatus(pid, status),
    });
  }

  // Broadcast driver assignment separately when driver info is present
  if (order.driverInfo && previousStatus !== DeliveryStatus.ACCEPTED) {
    wsService.broadcastDriverAssigned(orderId, order.driverInfo);
  }

  wsService.broadcastOrderUpdated(order);
  logger.info(`[OrderService] Order ${orderId}: ${previousStatus} → ${newStatus}`);
  return order;
}

/**
 * Handle a KDS status change for an order that is linked to a delivery order.
 *
 * Called by the WS handler when the POS tablet sends a KDS_STATUS_UPDATE command.
 * Maps KDS status to the corresponding DeliveryStatus and calls updateStatus.
 *
 * @param {string} orderId      – Delivery order internal id (not kitchen order id)
 * @param {string} kdsStatus    – KDS OrderStatus value (PREPARING / READY / SERVED / ...)
 */
async function handleKdsStatusUpdate(orderId, kdsStatus) {
  const deliveryStatus = mapKdsStatusToDeliveryStatus(kdsStatus);
  if (!deliveryStatus) {
    logger.debug(`[OrderService] KDS status ${kdsStatus} has no delivery mapping — skipping push`);
    return null;
  }

  const order = orderStore.get(orderId);
  if (!order) {
    logger.warn(`[OrderService] KDS status update received for unknown order: ${orderId}`);
    return null;
  }

  logger.info(
    `[OrderService] KDS→Delivery status: ${kdsStatus} → ${deliveryStatus} for order ${orderId}`,
  );
  return updateStatus(orderId, deliveryStatus);
}

/**
 * Update driver info on an existing order and broadcast.
 * @param {string} orderId
 * @param {import('../models/delivery-order').DriverInfo} driverInfo
 */
function updateDriverInfo(orderId, driverInfo) {
  const order = orderStore.get(orderId);
  if (!order) throw new Error(`Order not found: ${orderId}`);

  order.driverInfo = driverInfo;
  order.updatedAt = new Date();
  orderStore.set(orderId, order);

  wsService.broadcastDriverAssigned(orderId, driverInfo);
  wsService.broadcastOrderUpdated(order);
  return order;
}

module.exports = {
  receiveOrder,
  getAllOrders,
  getOrder,
  acceptOrder,
  rejectOrder,
  updateStatus,
  updateDriverInfo,
  handleKdsStatusUpdate,
};

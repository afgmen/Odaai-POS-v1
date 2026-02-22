'use strict';

const express = require('express');
const router = express.Router();

const { verifyGrabSignature } = require('../../utils/crypto');
const { mapGrabOrderToDeliveryOrder } = require('../../connectors/grab/grab-order-mapper');
const orderService = require('../../services/order-service');
const config = require('../../config');
const logger = require('../../utils/logger');

/**
 * POST /webhooks/grab
 *
 * Receives webhook events from GrabFood.
 * Verifies HMAC-SHA256 signature, maps the payload to a DeliveryOrder,
 * then broadcasts it to connected POS tablets via WebSocket.
 *
 * Note: Express must be configured with express.raw() for this route
 * so we have access to the raw body for signature verification.
 */
router.post(
  '/',
  express.raw({ type: '*/*' }),
  (req, res) => {
    // ── 1. Signature verification ──────────────────
    const signature = req.headers['x-grabfood-signature'];
    const rawBody = req.body; // Buffer because of express.raw()

    if (config.grab.webhookSecret) {
      const valid = verifyGrabSignature(rawBody, signature, config.grab.webhookSecret);
      if (!valid) {
        logger.warn('[GrabWebhook] Invalid signature — rejecting request');
        return res.status(401).json({ error: 'Invalid signature' });
      }
    } else {
      logger.warn('[GrabWebhook] GRAB_WEBHOOK_SECRET not set — skipping signature check');
    }

    // ── 2. Parse payload ───────────────────────────
    let payload;
    try {
      payload = JSON.parse(rawBody.toString());
    } catch (err) {
      logger.error('[GrabWebhook] Invalid JSON body:', err.message);
      return res.status(400).json({ error: 'Invalid JSON' });
    }

    logger.debug('[GrabWebhook] Received event:', payload.eventType || 'unknown');

    // ── 3. Route by event type ─────────────────────
    try {
      _handleEvent(payload);
    } catch (err) {
      logger.error('[GrabWebhook] Error handling event:', err.message);
      // Still return 200 so GrabFood does not retry
    }

    // GrabFood expects a 200 response quickly
    res.status(200).json({ received: true });
  },
);

/**
 * Handle different GrabFood webhook event types.
 * @param {object} payload
 */
function _handleEvent(payload) {
  const eventType = payload.eventType || payload.type || '';

  switch (eventType.toUpperCase()) {
    case 'ORDER_PLACED':
    case 'ORDER_SUBMITTED':
    case 'NEW_ORDER': {
      const order = mapGrabOrderToDeliveryOrder(payload.order || payload);
      orderService.receiveOrder(order);
      break;
    }

    case 'ORDER_STATUS_UPDATED':
    case 'ORDER_UPDATED': {
      const orderId = payload.orderID || payload.orderId;
      const newStatus = payload.orderState || payload.status;
      if (orderId) {
        // Find by platformOrderId
        const existing = orderService
          .getAllOrders()
          .find((o) => o.platformOrderId === orderId);
        if (existing) {
          orderService.updateStatus(existing.id, _mapGrabStatus(newStatus));
        }
      }
      break;
    }

    case 'DRIVER_ALLOCATED':
    case 'DRIVER_ASSIGNED': {
      const orderId = payload.orderID || payload.orderId;
      const driver = payload.driver;
      if (orderId && driver) {
        const existing = orderService
          .getAllOrders()
          .find((o) => o.platformOrderId === orderId);
        if (existing) {
          orderService.updateDriverInfo(existing.id, {
            name: driver.name || '',
            phone: driver.phone || '',
            licensePlate: driver.licensePlate || driver.vehicleLicensePlate || '',
          });
        }
      }
      break;
    }

    case 'ORDER_CANCELLED': {
      const orderId = payload.orderID || payload.orderId;
      const reason = payload.cancellationReason || payload.reason || 'Cancelled by GrabFood';
      if (orderId) {
        const existing = orderService
          .getAllOrders()
          .find((o) => o.platformOrderId === orderId);
        if (existing) {
          // Just update status — no need to call GrabFood API since it came from them
          existing.status = 'CANCELLED';
          existing.updatedAt = new Date();
          const wsService = require('../../services/websocket-service');
          wsService.broadcastOrderCancelled(existing.id, reason);
        }
      }
      break;
    }

    default:
      logger.debug(`[GrabWebhook] Unhandled event type: ${eventType}`);
  }
}

function _mapGrabStatus(grabStatus) {
  const { _mapGrabStatus } = require('../../connectors/grab/grab-order-mapper');
  return _mapGrabStatus(grabStatus);
}

module.exports = router;

'use strict';

const crypto = require('crypto');
const express = require('express');
const router = express.Router();

const { mapShopeeFoodOrderToDeliveryOrder, _mapShopeeFoodStatus } = require('../../connectors/shopeefood/shopeefood-order-mapper');
const orderService = require('../../services/order-service');
const config = require('../../config');
const logger = require('../../utils/logger');

/**
 * POST /webhooks/shopeefood
 *
 * Receives webhook events from ShopeeFood.
 * Verifies HMAC-SHA256 signature via the x-shopee-signature header,
 * maps the payload to a DeliveryOrder, then broadcasts it to connected
 * POS tablets via WebSocket.
 *
 * Note: Express must be configured with express.raw() for this route
 * so we have access to the raw body for signature verification.
 */
router.post(
  '/',
  express.raw({ type: '*/*' }),
  (req, res) => {
    // ── 1. Signature verification ──────────────────
    const signature = req.headers['x-shopee-signature'];
    const rawBody = req.body; // Buffer because of express.raw()

    if (config.shopeefood.appSecret) {
      const valid = _verifyShopeeFoodSignature(rawBody, signature, config.shopeefood.appSecret);
      if (!valid) {
        logger.warn('[ShopeeFoodWebhook] Invalid signature — rejecting request');
        return res.status(401).json({ error: 'Invalid signature' });
      }
    } else {
      logger.warn('[ShopeeFoodWebhook] SHOPEEFOOD_APP_SECRET not set — skipping signature check');
    }

    // ── 2. Parse payload ───────────────────────────
    let payload;
    try {
      payload = JSON.parse(rawBody.toString());
    } catch (err) {
      logger.error('[ShopeeFoodWebhook] Invalid JSON body:', err.message);
      return res.status(400).json({ error: 'Invalid JSON' });
    }

    logger.debug('[ShopeeFoodWebhook] Received event:', payload.event_type || payload.eventType || 'unknown');

    // ── 3. Route by event type ─────────────────────
    try {
      _handleEvent(payload);
    } catch (err) {
      logger.error('[ShopeeFoodWebhook] Error handling event:', err.message);
      // Still return 200 so ShopeeFood does not retry
    }

    // ShopeeFood expects a 200 response quickly
    res.status(200).json({ received: true });
  },
);

/**
 * Handle different ShopeeFood webhook event types.
 * @param {object} payload
 */
function _handleEvent(payload) {
  const eventType = payload.event_type || payload.eventType || payload.type || '';

  switch (eventType.toUpperCase()) {
    case 'ORDER_PLACED':
    case 'NEW_ORDER': {
      const order = mapShopeeFoodOrderToDeliveryOrder(payload.order || payload);
      orderService.receiveOrder(order);
      break;
    }

    case 'ORDER_STATUS_UPDATED': {
      const orderId = payload.order_sn || payload.orderId;
      const newStatus = payload.order_status || payload.status;
      if (orderId) {
        const existing = orderService
          .getAllOrders()
          .find((o) => o.platformOrderId === orderId);
        if (existing) {
          orderService.updateStatus(existing.id, _mapShopeeFoodStatus(newStatus));
        }
      }
      break;
    }

    case 'DRIVER_ASSIGNED': {
      const orderId = payload.order_sn || payload.orderId;
      const driver = payload.driver_info || payload.driver;
      if (orderId && driver) {
        const existing = orderService
          .getAllOrders()
          .find((o) => o.platformOrderId === orderId);
        if (existing) {
          orderService.updateDriverInfo(existing.id, {
            name: driver.driver_name || driver.name || '',
            phone: driver.driver_phone || driver.phone || '',
            licensePlate: driver.license_plate_number || driver.licensePlate || '',
          });
        }
      }
      break;
    }

    case 'ORDER_CANCELLED': {
      const orderId = payload.order_sn || payload.orderId;
      const reason = payload.cancel_reason || payload.reason || 'Cancelled by ShopeeFood';
      if (orderId) {
        const existing = orderService
          .getAllOrders()
          .find((o) => o.platformOrderId === orderId);
        if (existing) {
          // Just update status — no need to call ShopeeFood API since it came from them
          existing.status = 'CANCELLED';
          existing.updatedAt = new Date();
          const wsService = require('../../services/websocket-service');
          wsService.broadcastOrderCancelled(existing.id, reason);
        }
      }
      break;
    }

    default:
      logger.debug(`[ShopeeFoodWebhook] Unhandled event type: ${eventType}`);
  }
}

/**
 * Verify ShopeeFood webhook HMAC-SHA256 signature.
 *
 * ShopeeFood sends the signature in the `x-shopee-signature` header as:
 *   sha256=<hex-digest>
 *
 * @param {string|Buffer} rawBody       – raw request body (before JSON.parse)
 * @param {string}        signatureHeader – value of x-shopee-signature header
 * @param {string}        secret          – SHOPEEFOOD_APP_SECRET from .env
 * @returns {boolean}
 */
function _verifyShopeeFoodSignature(rawBody, signatureHeader, secret) {
  if (!signatureHeader || !secret) return false;

  const [algo, digest] = signatureHeader.split('=');
  if (algo !== 'sha256' || !digest) return false;

  const expected = crypto
    .createHmac('sha256', secret)
    .update(rawBody)
    .digest('hex');

  // Constant-time comparison to prevent timing attacks
  try {
    return crypto.timingSafeEqual(
      Buffer.from(digest, 'hex'),
      Buffer.from(expected, 'hex'),
    );
  } catch {
    return false;
  }
}

module.exports = router;

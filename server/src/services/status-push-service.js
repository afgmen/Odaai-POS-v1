'use strict';

const logger = require('../utils/logger');

/**
 * Retry configuration for outbound platform API calls.
 */
const RETRY_CONFIG = {
  maxAttempts: 3,
  baseDelayMs: 1000,  // 1 s, 2 s, 4 s (exponential backoff)
};

/**
 * Push an order status update to the delivery platform with retry.
 *
 * This is fire-and-forget from the WebSocket layer's perspective —
 * errors are logged but do NOT bubble up to the POS tablet.
 *
 * @param {object} opts
 * @param {string} opts.platformOrderId
 * @param {string} opts.platform           – DeliveryPlatform value
 * @param {string} opts.newStatus          – DeliveryStatus value
 * @param {Function} opts.connectorFn      – async (platformOrderId, status) → void
 */
async function pushStatusWithRetry({ platformOrderId, platform, newStatus, connectorFn }) {
  let attempt = 0;

  while (attempt < RETRY_CONFIG.maxAttempts) {
    attempt++;
    try {
      await connectorFn(platformOrderId, newStatus);
      logger.info(
        `[StatusPush] ${platform} order ${platformOrderId} → ${newStatus} (attempt ${attempt})`,
      );
      return; // success
    } catch (err) {
      const isLastAttempt = attempt >= RETRY_CONFIG.maxAttempts;
      if (isLastAttempt) {
        logger.error(
          `[StatusPush] Failed to push ${newStatus} for ${platform} order ${platformOrderId} after ${attempt} attempts: ${err.message}`,
        );
        return; // exhaust retries — fire-and-forget
      }

      const delayMs = RETRY_CONFIG.baseDelayMs * Math.pow(2, attempt - 1);
      logger.warn(
        `[StatusPush] Attempt ${attempt} failed for ${platform} order ${platformOrderId}: ${err.message}. Retrying in ${delayMs}ms...`,
      );
      await _sleep(delayMs);
    }
  }
}

/**
 * KDS status → Delivery platform status mapping.
 *
 * Called when the Flutter app reports a KDS status change that is linked
 * to a delivery order.
 *
 * KDS status string → DeliveryStatus value:
 *   PREPARING → PREPARING
 *   READY     → READY_FOR_PICKUP
 *   SERVED    → COMPLETED
 *
 * @param {string} kdsStatus  – KDS OrderStatus value (PENDING/PREPARING/READY/SERVED/CANCELLED)
 * @returns {string | null}   – Corresponding DeliveryStatus value, or null if no mapping
 */
function mapKdsStatusToDeliveryStatus(kdsStatus) {
  switch (kdsStatus?.toUpperCase()) {
    case 'PREPARING':
      return 'PREPARING';
    case 'READY':
      return 'READY_FOR_PICKUP';
    case 'SERVED':
      return 'COMPLETED';
    default:
      return null; // PENDING / CANCELLED have no delivery status push
  }
}

function _sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

module.exports = { pushStatusWithRetry, mapKdsStatusToDeliveryStatus };

'use strict';

const axios = require('axios');
const BaseConnector = require('../base-connector');
const grabAuth = require('./grab-auth');
const { syncMenuToGrab } = require('./grab-menu-sync');
const config = require('../../config');
const logger = require('../../utils/logger');
const { DeliveryStatus } = require('../../models/delivery-order');

/**
 * GrabFood connector implementation.
 *
 * Handles outbound calls to the GrabFood Partner API:
 *   - Accept / reject orders
 *   - Status updates (preparing, ready for pickup)
 *   - Menu sync
 */
class GrabConnector extends BaseConnector {
  constructor() {
    super('GrabFood');
  }

  // ──────────────────────────────────────────────
  // Order lifecycle
  // ──────────────────────────────────────────────

  /**
   * Accept an order on GrabFood.
   * @param {string} platformOrderId
   */
  async acceptOrder(platformOrderId) {
    logger.info(`[GrabConnector] Accepting order ${platformOrderId}`);
    await this._post(`/partner/v1/order/prepare`, {
      orderID: platformOrderId,
    });
  }

  /**
   * Reject an order on GrabFood.
   * @param {string} platformOrderId
   * @param {string} reason
   */
  async rejectOrder(platformOrderId, reason) {
    logger.info(`[GrabConnector] Rejecting order ${platformOrderId}: ${reason}`);
    await this._post(`/partner/v1/order/cancel`, {
      orderID: platformOrderId,
      reason,
    });
  }

  /**
   * Push a status update to GrabFood.
   * Internal status → GrabFood API action mapping:
   *   PREPARING       → mark order as being prepared (already sent on accept)
   *   READY_FOR_PICKUP → mark food as ready for driver pickup
   *
   * @param {string} platformOrderId
   * @param {string} status – DeliveryStatus value
   */
  async updateOrderStatus(platformOrderId, status) {
    logger.info(`[GrabConnector] Updating order ${platformOrderId} status → ${status}`);

    switch (status) {
      case DeliveryStatus.PREPARING:
        // GrabFood does not have a separate "preparing" endpoint;
        // acceptOrder already starts preparation on their side.
        break;

      case DeliveryStatus.READY_FOR_PICKUP:
        await this._post(`/partner/v1/order/markReadyForPickup`, {
          orderID: platformOrderId,
        });
        break;

      default:
        logger.debug(
          `[GrabConnector] No outbound action for status ${status}`,
        );
    }
  }

  /**
   * Sync menu / prices to GrabFood.
   * @param {object} menuData
   */
  async syncMenu(menuData) {
    return syncMenuToGrab(menuData);
  }

  // ──────────────────────────────────────────────
  // HTTP helpers
  // ──────────────────────────────────────────────

  async _post(path, body) {
    const token = await grabAuth.getAccessToken();
    try {
      const response = await axios.post(
        `${config.grab.baseUrl}${path}`,
        body,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        },
      );
      return response.data;
    } catch (err) {
      // If 401, refresh token once and retry
      if (err.response?.status === 401) {
        logger.warn('[GrabConnector] 401 received, refreshing token and retrying...');
        const newToken = await grabAuth.refreshToken();
        const retryResponse = await axios.post(
          `${config.grab.baseUrl}${path}`,
          body,
          {
            headers: {
              Authorization: `Bearer ${newToken}`,
              'Content-Type': 'application/json',
            },
          },
        );
        return retryResponse.data;
      }
      logger.error(`[GrabConnector] API error on ${path}:`, err.response?.data || err.message);
      throw err;
    }
  }
}

module.exports = new GrabConnector();

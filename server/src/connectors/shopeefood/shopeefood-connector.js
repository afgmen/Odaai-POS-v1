'use strict';

const axios = require('axios');
const BaseConnector = require('../base-connector');
const shopeefoodAuth = require('./shopeefood-auth');
const { syncMenuToShopeeFood } = require('./shopeefood-menu-sync');
const config = require('../../config');
const logger = require('../../utils/logger');
const { DeliveryStatus } = require('../../models/delivery-order');

/**
 * ShopeeFood connector implementation.
 *
 * Handles outbound calls to the ShopeeFood Partner API:
 *   - Accept / reject orders
 *   - Status updates (preparing, ready for pickup)
 *   - Menu sync
 *
 * NOTE: ShopeeFood Partner API requires registration and approval.
 * Until credentials are available, all methods run in mock mode:
 *   - Log what would have been called
 *   - Return mock success responses
 *   - No real HTTP calls made
 *
 * Environment variables required for live mode:
 *   SHOPEEFOOD_APP_ID
 *   SHOPEEFOOD_APP_SECRET
 *   SHOPEEFOOD_API_BASE_URL  (default: https://partner.food.shopee.vn)
 */
class ShopeeFoodConnector extends BaseConnector {
  constructor() {
    super('ShopeeFood');
  }

  get _isMock() {
    return !config.shopeefood.appId || !config.shopeefood.appSecret;
  }

  // ──────────────────────────────────────────────
  // Order lifecycle
  // ──────────────────────────────────────────────

  /**
   * Accept an order on ShopeeFood.
   * @param {string} platformOrderId
   */
  async acceptOrder(platformOrderId) {
    logger.info(`[ShopeeFoodConnector] Accepting order ${platformOrderId}`);

    if (this._isMock) {
      logger.warn(`[ShopeeFoodConnector] MOCK: Would call POST /api/v1/order/${platformOrderId}/confirm`);
      return;
    }

    await this._post(`/api/v1/order/${platformOrderId}/confirm`, {
      order_sn: platformOrderId,
    });
  }

  /**
   * Reject an order on ShopeeFood.
   * @param {string} platformOrderId
   * @param {string} reason
   */
  async rejectOrder(platformOrderId, reason) {
    logger.info(`[ShopeeFoodConnector] Rejecting order ${platformOrderId}: ${reason}`);

    if (this._isMock) {
      logger.warn(`[ShopeeFoodConnector] MOCK: Would call POST /api/v1/order/${platformOrderId}/cancel`);
      return;
    }

    await this._post(`/api/v1/order/${platformOrderId}/cancel`, {
      order_sn: platformOrderId,
      cancel_reason: reason,
    });
  }

  /**
   * Push a status update to ShopeeFood.
   * Internal status → ShopeeFood API action mapping:
   *   PREPARING       → mark order as being prepared
   *   READY_FOR_PICKUP → mark food as ready for driver pickup
   *
   * @param {string} platformOrderId
   * @param {string} status – DeliveryStatus value
   */
  async updateOrderStatus(platformOrderId, status) {
    logger.info(`[ShopeeFoodConnector] Updating order ${platformOrderId} status → ${status}`);

    if (this._isMock) {
      logger.warn(`[ShopeeFoodConnector] MOCK: Would update order ${platformOrderId} to ${status}`);
      return;
    }

    switch (status) {
      case DeliveryStatus.PREPARING:
        await this._post(`/api/v1/order/${platformOrderId}/prepare`, {
          order_sn: platformOrderId,
        });
        break;

      case DeliveryStatus.READY_FOR_PICKUP:
        await this._post(`/api/v1/order/${platformOrderId}/ready`, {
          order_sn: platformOrderId,
        });
        break;

      default:
        logger.debug(
          `[ShopeeFoodConnector] No outbound action for status ${status}`,
        );
    }
  }

  /**
   * Sync menu / prices to ShopeeFood.
   * @param {object} menuData
   */
  async syncMenu(menuData) {
    return syncMenuToShopeeFood(menuData);
  }

  // ──────────────────────────────────────────────
  // HTTP helpers
  // ──────────────────────────────────────────────

  async _post(path, body) {
    const authHeader = shopeefoodAuth.getAuthHeader();
    try {
      const response = await axios.post(
        `${config.shopeefood.apiBaseUrl}${path}`,
        body,
        {
          headers: {
            Authorization: authHeader,
            'Content-Type': 'application/json',
          },
        },
      );
      return response.data;
    } catch (err) {
      logger.error(`[ShopeeFoodConnector] API error on ${path}:`, err.response?.data || err.message);
      throw err;
    }
  }
}

module.exports = new ShopeeFoodConnector();

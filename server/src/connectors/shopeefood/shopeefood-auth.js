'use strict';

const crypto = require('crypto');
const config = require('../../config');
const logger = require('../../utils/logger');

/**
 * ShopeeFood request authentication.
 *
 * ShopeeFood Partner API uses HMAC-SHA256 request signing:
 *   - Each request includes: app_id, timestamp, sign
 *   - sign = HMAC-SHA256(app_id + "|" + timestamp, app_secret)
 *
 * Unlike GrabFood (OAuth2 bearer tokens), ShopeeFood signs each request
 * individually — no token storage needed.
 *
 * Environment variables:
 *   SHOPEEFOOD_APP_ID     — Partner app ID from ShopeeFood portal
 *   SHOPEEFOOD_APP_SECRET — Partner app secret for signing
 */
class ShopeeFoodAuth {
  /**
   * Build signed auth headers for a ShopeeFood API request.
   * @returns {{ app_id: string, timestamp: number, sign: string }}
   */
  getAuthParams() {
    const appId = config.shopeefood.appId;
    const appSecret = config.shopeefood.appSecret;
    const timestamp = Math.floor(Date.now() / 1000);

    if (!appId || !appSecret) {
      logger.warn('[ShopeeFoodAuth] SHOPEEFOOD_APP_ID or SHOPEEFOOD_APP_SECRET not configured — using mock auth');
      return { app_id: 'mock_app_id', timestamp, sign: 'mock_sign' };
    }

    const payload = `${appId}|${timestamp}`;
    const sign = crypto
      .createHmac('sha256', appSecret)
      .update(payload)
      .digest('hex');

    logger.debug(`[ShopeeFoodAuth] Signed request: app_id=${appId}, timestamp=${timestamp}`);
    return { app_id: appId, timestamp, sign };
  }

  /**
   * Build Authorization header for ShopeeFood API.
   * @returns {string}
   */
  getAuthHeader() {
    const { app_id, timestamp, sign } = this.getAuthParams();
    return `ShopeefoodHmac app_id=${app_id},timestamp=${timestamp},sign=${sign}`;
  }
}

module.exports = new ShopeeFoodAuth();

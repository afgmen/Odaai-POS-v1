'use strict';

const axios = require('axios');
const config = require('../../config');
const shopeefoodAuth = require('./shopeefood-auth');
const logger = require('../../utils/logger');

/**
 * Push menu / price updates to ShopeeFood Partner API.
 *
 * NOTE: ShopeeFood Partner API access is restricted and requires approval
 * from Shopee. This implementation follows the known API patterns and will
 * work correctly once real credentials are configured.
 * Until then, the connector logs all calls and returns mock responses
 * so the rest of the system can be tested end-to-end.
 *
 * @param {object} menuData – POS menu data to sync
 * @returns {Promise<object>} – ShopeeFood API response (or mock)
 */
async function syncMenuToShopeeFood(menuData) {
  const isMock = !config.shopeefood.appId || !config.shopeefood.appSecret;

  const shopeefoodPayload = _mapMenuToShopeeFoodFormat(menuData);

  logger.info('[ShopeeFoodMenuSync] Pushing menu update to ShopeeFood...');
  logger.debug('[ShopeeFoodMenuSync] Payload:', JSON.stringify(shopeefoodPayload, null, 2));

  if (isMock) {
    logger.warn('[ShopeeFoodMenuSync] Running in MOCK mode — credentials not configured');
    logger.info('[ShopeeFoodMenuSync] Would have sent to: POST ' +
      `${config.shopeefood.apiBaseUrl}/api/v1/merchant/menu/update`);
    return {
      mock: true,
      message: 'Mock sync — configure SHOPEEFOOD_APP_ID and SHOPEEFOOD_APP_SECRET for real API calls',
      categories_synced: shopeefoodPayload.categories.length,
      items_synced: shopeefoodPayload.categories.reduce(
        (sum, c) => sum + c.items.length, 0
      ),
    };
  }

  try {
    const authHeader = shopeefoodAuth.getAuthHeader();
    const response = await axios.post(
      `${config.shopeefood.apiBaseUrl}/api/v1/merchant/menu/update`,
      shopeefoodPayload,
      {
        headers: {
          Authorization: authHeader,
          'Content-Type': 'application/json',
        },
      },
    );

    logger.info('[ShopeeFoodMenuSync] Menu sync successful', response.data);
    return response.data;
  } catch (err) {
    logger.error('[ShopeeFoodMenuSync] Menu sync failed:', err.response?.data || err.message);
    throw err;
  }
}

/**
 * Map internal POS menu format to ShopeeFood menu payload structure.
 *
 * ShopeeFood expects prices in minor units (xu = 1/100 VND).
 *
 * @param {object} menuData
 */
function _mapMenuToShopeeFoodFormat(menuData) {
  const categories = (menuData.categories || []).map((cat) => ({
    category_id: cat.id?.toString(),
    category_name: cat.name,
    items: (cat.items || []).map((item) => ({
      item_id: item.id?.toString(),
      item_name: item.name,
      description: item.description || '',
      // ShopeeFood prices are in minor units (1 VND = 100 xu in their system)
      item_price: Math.round((item.price || 0) * 100),
      is_available: item.available ?? (item.active !== false),
      image_url: item.imageUrl || null,
    })),
  }));

  return { categories };
}

module.exports = { syncMenuToShopeeFood };

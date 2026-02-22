'use strict';

const axios = require('axios');
const config = require('../../config');
const grabAuth = require('./grab-auth');
const logger = require('../../utils/logger');

/**
 * Push menu / price updates to GrabFood Partner API.
 *
 * @param {object} menuData – POS menu data to sync
 * @returns {Promise<object>} – GrabFood API response
 */
async function syncMenuToGrab(menuData) {
  const token = await grabAuth.getAccessToken();

  const grabMenuPayload = _mapMenuToGrabFormat(menuData);

  logger.info('[GrabMenuSync] Pushing menu update to GrabFood...');

  try {
    const response = await axios.put(
      `${config.grab.baseUrl}/partner/v1/menu`,
      grabMenuPayload,
      {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      },
    );

    logger.info('[GrabMenuSync] Menu sync successful', response.data);
    return response.data;
  } catch (err) {
    logger.error('[GrabMenuSync] Menu sync failed:', err.response?.data || err.message);
    throw err;
  }
}

/**
 * Map internal POS menu format to GrabFood menu payload structure.
 *
 * @param {object} menuData
 */
function _mapMenuToGrabFormat(menuData) {
  const categories = (menuData.categories || []).map((cat) => ({
    name: cat.name,
    ID: cat.id?.toString(),
    items: (cat.items || []).map((item) => ({
      ID: item.id?.toString(),
      name: item.name,
      description: item.description || '',
      priceInMinors: Math.round((item.price || 0) * 100), // VND in minors
      available: item.available ?? (item.active !== false),
      photos: item.imageUrl ? [{ URL: item.imageUrl }] : [],
    })),
  }));

  return { categories };
}

module.exports = { syncMenuToGrab };

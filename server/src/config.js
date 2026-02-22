'use strict';

require('dotenv').config();

const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',

  grab: {
    clientId: process.env.GRAB_CLIENT_ID || '',
    clientSecret: process.env.GRAB_CLIENT_SECRET || '',
    environment: process.env.GRAB_ENVIRONMENT || 'sandbox',
    webhookSecret: process.env.GRAB_WEBHOOK_SECRET || '',

    get baseUrl() {
      return config.grab.environment === 'production'
        ? 'https://partner-api.grab.com/grabfood'
        : 'https://partner-api.grab.com/grabfood-sandbox';
    },

    authBaseUrl: 'https://api.grab.com',
    scope: 'food.partner_api',
  },

  shopeefood: {
    appId: process.env.SHOPEEFOOD_APP_ID || '',
    appSecret: process.env.SHOPEEFOOD_APP_SECRET || '',
    apiBaseUrl: process.env.SHOPEEFOOD_API_BASE_URL || 'https://partner.food.shopee.vn',
  },

  ws: {
    heartbeatInterval: parseInt(process.env.WS_HEARTBEAT_INTERVAL || '30000', 10),
  },
};

module.exports = config;

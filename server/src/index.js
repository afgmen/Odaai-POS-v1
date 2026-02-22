'use strict';

const http = require('http');
const express = require('express');
const config = require('./config');
const logger = require('./utils/logger');
const wsService = require('./services/websocket-service');
const orderService = require('./services/order-service');

const connectorRegistry = require('./connectors/connector-registry');
const grabConnector = require('./connectors/grab/grab-connector');
const shopeefoodConnector = require('./connectors/shopeefood/shopeefood-connector');

// ── Route imports ────────────────────────────────
const grabWebhookRouter = require('./routes/webhooks/grab');
const shopeefoodWebhookRouter = require('./routes/webhooks/shopeefood');
const ordersRouter = require('./routes/api/orders');
const menuRouter = require('./routes/api/menu');
const platformsRouter = require('./routes/api/platforms');

// ── App setup ────────────────────────────────────
const app = express();

// Parse JSON bodies for all routes except the GrabFood webhook
// (that one uses express.raw() inline for signature verification)
app.use((req, res, next) => {
  if (req.path.startsWith('/webhooks/')) return next();
  express.json()(req, res, next);
});

// ── Health check ─────────────────────────────────
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    uptime: process.uptime(),
    wsClients: wsService.connectedClients,
    timestamp: new Date().toISOString(),
  });
});

// ── Connector registration ────────────────────────────────
// Connectors auto-register based on environment config.
// Missing credentials → registered as inactive (mock mode).
connectorRegistry.register('grab', grabConnector, Boolean(config.grab.clientId && config.grab.clientSecret));
connectorRegistry.register('shopeefood', shopeefoodConnector, Boolean(config.shopeefood.appId && config.shopeefood.appSecret));

// ── Routes ───────────────────────────────────────
app.use('/webhooks/grab', grabWebhookRouter);
app.use('/webhooks/shopeefood', shopeefoodWebhookRouter);
app.use('/api/orders', ordersRouter);
app.use('/api/menu', menuRouter);
app.use('/api/platforms', platformsRouter);

// ── 404 handler ──────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// ── Error handler ────────────────────────────────
app.use((err, req, res, _next) => {
  logger.error('[Server] Unhandled error:', err.message);
  res.status(500).json({ error: 'Internal server error' });
});

// ── HTTP + WebSocket server ───────────────────────
const server = http.createServer(app);
wsService.attach(server);

// ── WebSocket command handler (from POS tablets) ──
wsService.onMessage(async (message) => {
  const { type, orderId, reason, status, kdsStatus } = message;
  logger.debug(`[WS Command] ${type} for order ${orderId}`);

  switch (type) {
    case 'ACCEPT_ORDER':
      await orderService.acceptOrder(orderId);
      break;
    case 'REJECT_ORDER':
      await orderService.rejectOrder(orderId, reason || 'Rejected by merchant');
      break;
    case 'UPDATE_STATUS':
      await orderService.updateStatus(orderId, status);
      break;
    // Sent by Flutter when a KDS order linked to a delivery order changes status.
    // kdsStatus is the KDS OrderStatus value (PREPARING / READY / SERVED).
    case 'KDS_STATUS_UPDATE':
      await orderService.handleKdsStatusUpdate(orderId, kdsStatus);
      break;
    default:
      logger.warn(`[WS Command] Unknown type: ${type}`);
  }
});

// ── Start ─────────────────────────────────────────
server.listen(config.port, () => {
  logger.info(`Odaai POS Delivery Server started on port ${config.port}`);
  logger.info(`Environment : ${config.nodeEnv}`);
  logger.info(`GrabFood env: ${config.grab.environment}`);
  logger.info(`Health check: http://localhost:${config.port}/health`);
});

module.exports = { app, server };

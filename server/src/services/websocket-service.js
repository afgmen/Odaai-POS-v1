'use strict';

const { WebSocketServer, WebSocket } = require('ws');
const config = require('../config');
const logger = require('../utils/logger');

/**
 * WebSocket service — manages connections from POS tablets and
 * broadcasts delivery order events.
 *
 * Message types broadcast TO tablets:
 *   { type: 'NEW_ORDER',       order: DeliveryOrder }
 *   { type: 'ORDER_UPDATED',   order: DeliveryOrder }
 *   { type: 'DRIVER_ASSIGNED', orderId, driverInfo }
 *   { type: 'ORDER_CANCELLED', orderId, reason }
 *
 * Messages received FROM tablets:
 *   { type: 'ACCEPT_ORDER',   orderId }
 *   { type: 'REJECT_ORDER',   orderId, reason }
 *   { type: 'UPDATE_STATUS',  orderId, status }
 */
class WebSocketService {
  constructor() {
    /** @type {WebSocketServer | null} */
    this._wss = null;
    /** @type {Set<WebSocket>} */
    this._clients = new Set();
    /** @type {((message: object) => Promise<void>) | null} */
    this._messageHandler = null;
  }

  /**
   * Attach to an existing HTTP server.
   * @param {import('http').Server} httpServer
   */
  attach(httpServer) {
    this._wss = new WebSocketServer({ server: httpServer });

    this._wss.on('connection', (ws, req) => {
      const clientIp = req.socket.remoteAddress;
      logger.info(`[WS] POS tablet connected from ${clientIp}`);
      this._clients.add(ws);

      // Heartbeat ping
      ws.isAlive = true;
      ws.on('pong', () => { ws.isAlive = true; });

      ws.on('message', (data) => this._handleMessage(ws, data));

      ws.on('close', () => {
        logger.info(`[WS] POS tablet disconnected from ${clientIp}`);
        this._clients.delete(ws);
      });

      ws.on('error', (err) => {
        logger.error('[WS] Client error:', err.message);
        this._clients.delete(ws);
      });

      // Send connection acknowledgement
      this._send(ws, { type: 'CONNECTED', message: 'Odaai POS Delivery Server' });
    });

    // Heartbeat interval — terminate dead connections
    const interval = setInterval(() => {
      this._clients.forEach((ws) => {
        if (!ws.isAlive) {
          logger.warn('[WS] Terminating unresponsive client');
          this._clients.delete(ws);
          return ws.terminate();
        }
        ws.isAlive = false;
        ws.ping();
      });
    }, config.ws.heartbeatInterval);

    this._wss.on('close', () => clearInterval(interval));

    logger.info('[WS] WebSocket server ready');
  }

  /**
   * Register a handler for commands received from POS tablets.
   * @param {(message: object) => Promise<void>} handler
   */
  onMessage(handler) {
    this._messageHandler = handler;
  }

  // ──────────────────────────────────────────────
  // Broadcast helpers
  // ──────────────────────────────────────────────

  /** @param {import('../models/delivery-order').DeliveryOrder} order */
  broadcastNewOrder(order) {
    this._broadcast({ type: 'NEW_ORDER', order });
  }

  /** @param {import('../models/delivery-order').DeliveryOrder} order */
  broadcastOrderUpdated(order) {
    this._broadcast({ type: 'ORDER_UPDATED', order });
  }

  /**
   * @param {string} orderId
   * @param {import('../models/delivery-order').DriverInfo} driverInfo
   */
  broadcastDriverAssigned(orderId, driverInfo) {
    this._broadcast({ type: 'DRIVER_ASSIGNED', orderId, driverInfo });
  }

  /**
   * @param {string} orderId
   * @param {string} reason
   */
  broadcastOrderCancelled(orderId, reason) {
    this._broadcast({ type: 'ORDER_CANCELLED', orderId, reason });
  }

  /** @returns {number} */
  get connectedClients() {
    return this._clients.size;
  }

  // ──────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────

  _broadcast(message) {
    const json = JSON.stringify(message);
    let sent = 0;
    this._clients.forEach((ws) => {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(json);
        sent++;
      }
    });
    logger.debug(`[WS] Broadcast "${message.type}" to ${sent} client(s)`);
  }

  _send(ws, message) {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify(message));
    }
  }

  async _handleMessage(ws, data) {
    let message;
    try {
      message = JSON.parse(data.toString());
    } catch {
      logger.warn('[WS] Received invalid JSON from client');
      return;
    }

    logger.debug(`[WS] Received from client: ${message.type}`);

    if (this._messageHandler) {
      try {
        await this._messageHandler(message);
      } catch (err) {
        logger.error('[WS] Error in message handler:', err.message);
        this._send(ws, { type: 'ERROR', message: err.message });
      }
    }
  }
}

// Export singleton
module.exports = new WebSocketService();

'use strict';

const express = require('express');
const router = express.Router();

const orderService = require('../../services/order-service');
const logger = require('../../utils/logger');

/**
 * GET /api/orders
 * Returns all orders (newest first).
 */
router.get('/', (req, res) => {
  const orders = orderService.getAllOrders();
  res.json({ orders, count: orders.length });
});

/**
 * GET /api/orders/:id
 * Returns a single order.
 */
router.get('/:id', (req, res) => {
  const order = orderService.getOrder(req.params.id);
  if (!order) return res.status(404).json({ error: 'Order not found' });
  res.json({ order });
});

/**
 * PATCH /api/orders/:id/status
 * Body: { status: string }
 *
 * Also handles accept / reject via status values:
 *   ACCEPTED  → calls acceptOrder()
 *   CANCELLED → calls rejectOrder() (expects optional reason in body)
 *   Others    → calls updateStatus()
 */
router.patch('/:id/status', async (req, res) => {
  const { id } = req.params;
  const { status, reason } = req.body || {};

  if (!status) {
    return res.status(400).json({ error: 'status is required' });
  }

  try {
    let order;
    if (status === 'ACCEPTED') {
      order = await orderService.acceptOrder(id);
    } else if (status === 'CANCELLED') {
      order = await orderService.rejectOrder(id, reason || 'Rejected by merchant');
    } else {
      order = await orderService.updateStatus(id, status);
    }
    res.json({ order });
  } catch (err) {
    logger.error(`[OrdersAPI] Status update failed for ${id}:`, err.message);
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;

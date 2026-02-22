'use strict';

/**
 * Unified DeliveryOrder model shared across all delivery platforms.
 *
 * status flow:
 *   NEW → ACCEPTED → PREPARING → READY_FOR_PICKUP → PICKED_UP → COMPLETED
 *                                                              ↘ CANCELLED (any state)
 */

const DeliveryStatus = Object.freeze({
  NEW: 'NEW',
  ACCEPTED: 'ACCEPTED',
  PREPARING: 'PREPARING',
  READY_FOR_PICKUP: 'READY_FOR_PICKUP',
  PICKED_UP: 'PICKED_UP',
  COMPLETED: 'COMPLETED',
  CANCELLED: 'CANCELLED',
});

const DeliveryPlatform = Object.freeze({
  GRAB: 'grab',
  SHOPEEFOOD: 'shopeefood',
  MANUAL: 'manual',
});

/**
 * Create a new DeliveryOrder object.
 *
 * @param {Partial<DeliveryOrder>} fields
 * @returns {DeliveryOrder}
 */
function createDeliveryOrder(fields) {
  const now = new Date();
  return {
    id: fields.id || _generateId(),
    platformOrderId: fields.platformOrderId || '',
    platform: fields.platform || DeliveryPlatform.MANUAL,
    status: fields.status || DeliveryStatus.NEW,
    customerName: fields.customerName || 'Unknown',
    customerPhone: fields.customerPhone || null,
    deliveryAddress: fields.deliveryAddress || null,
    items: Array.isArray(fields.items) ? fields.items : [],
    totalAmount: fields.totalAmount || 0,
    currency: 'VND',
    platformFee: fields.platformFee || 0,
    specialInstructions: fields.specialInstructions || null,
    estimatedPickupTime: fields.estimatedPickupTime || null,
    driverInfo: fields.driverInfo || null,
    createdAt: fields.createdAt || now,
    updatedAt: fields.updatedAt || now,
  };
}

/**
 * Create a DeliveryOrderItem object.
 *
 * @param {{ name: string, quantity: number, price: number, notes?: string }} item
 */
function createOrderItem({ name, quantity, price, notes = null }) {
  return { name, quantity, price, notes };
}

/**
 * Create a DriverInfo object.
 *
 * @param {{ name: string, phone: string, licensePlate: string }} info
 */
function createDriverInfo({ name, phone, licensePlate }) {
  return { name, phone, licensePlate };
}

function _generateId() {
  return `dlv_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
}

module.exports = {
  DeliveryStatus,
  DeliveryPlatform,
  createDeliveryOrder,
  createOrderItem,
  createDriverInfo,
};

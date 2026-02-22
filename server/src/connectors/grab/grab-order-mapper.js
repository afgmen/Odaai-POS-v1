'use strict';

const {
  createDeliveryOrder,
  createOrderItem,
  createDriverInfo,
  DeliveryPlatform,
  DeliveryStatus,
} = require('../../models/delivery-order');

/**
 * Maps a raw GrabFood webhook order payload to the unified DeliveryOrder model.
 *
 * GrabFood order payload reference:
 * https://developer.grab.com/docs/food-partner-api/webhook
 *
 * @param {object} grabOrder – raw payload from GrabFood webhook
 * @returns {import('../../models/delivery-order').DeliveryOrder}
 */
function mapGrabOrderToDeliveryOrder(grabOrder) {
  const items = (grabOrder.items || []).map((item) =>
    createOrderItem({
      name: item.name || item.itemName || 'Unknown Item',
      quantity: item.quantity || 1,
      price: item.price || 0,
      notes: item.specialInstructions || null,
    }),
  );

  const totalAmount =
    grabOrder.totalFee ||
    grabOrder.orderValue ||
    items.reduce((sum, i) => sum + i.price * i.quantity, 0);

  const driverInfo = grabOrder.driver
    ? createDriverInfo({
        name: grabOrder.driver.name || '',
        phone: grabOrder.driver.phone || '',
        licensePlate: grabOrder.driver.licensePlate || grabOrder.driver.vehicleLicensePlate || '',
      })
    : null;

  const estimatedPickupTime = grabOrder.estimatedPickupTime
    ? new Date(grabOrder.estimatedPickupTime)
    : null;

  return createDeliveryOrder({
    platformOrderId: grabOrder.orderID || grabOrder.orderId || '',
    platform: DeliveryPlatform.GRAB,
    status: _mapGrabStatus(grabOrder.orderState || grabOrder.status),
    customerName:
      grabOrder.diner?.name ||
      grabOrder.customer?.name ||
      'GrabFood Customer',
    customerPhone:
      grabOrder.diner?.phone ||
      grabOrder.customer?.phone ||
      null,
    deliveryAddress:
      grabOrder.deliveryAddress?.address ||
      grabOrder.destination?.address ||
      null,
    items,
    totalAmount,
    platformFee: grabOrder.merchantFee || grabOrder.platformFee || 0,
    specialInstructions: grabOrder.specialInstructions || null,
    estimatedPickupTime,
    driverInfo,
    createdAt: grabOrder.submittedDateTime
      ? new Date(grabOrder.submittedDateTime)
      : new Date(),
  });
}

/**
 * Map GrabFood order state strings to internal DeliveryStatus.
 *
 * @param {string} grabStatus
 * @returns {string}
 */
function _mapGrabStatus(grabStatus) {
  if (!grabStatus) return DeliveryStatus.NEW;

  const statusMap = {
    // GrabFood states → internal
    PLACED: DeliveryStatus.NEW,
    SUBMITTED: DeliveryStatus.NEW,
    ACCEPTED: DeliveryStatus.ACCEPTED,
    DRIVER_ALLOCATED: DeliveryStatus.ACCEPTED,
    DRIVER_HEADING_TO_RESTAURANT: DeliveryStatus.PREPARING,
    DRIVER_AT_RESTAURANT: DeliveryStatus.READY_FOR_PICKUP,
    DRIVER_HEADING_TO_CUSTOMER: DeliveryStatus.PICKED_UP,
    COMPLETED: DeliveryStatus.COMPLETED,
    DELIVERED: DeliveryStatus.COMPLETED,
    CANCELLED: DeliveryStatus.CANCELLED,
    FAILED: DeliveryStatus.CANCELLED,
  };

  return statusMap[grabStatus.toUpperCase()] || DeliveryStatus.NEW;
}

module.exports = { mapGrabOrderToDeliveryOrder, _mapGrabStatus };

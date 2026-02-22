'use strict';

const {
  createDeliveryOrder,
  createOrderItem,
  createDriverInfo,
  DeliveryPlatform,
  DeliveryStatus,
} = require('../../models/delivery-order');

/**
 * Maps a raw ShopeeFood webhook order payload to the unified DeliveryOrder model.
 *
 * ShopeeFood Merchant API reference:
 * https://open.shopee.com/documents/v2/shopee-food-partner-api (placeholder)
 *
 * @param {object} shopeefoodOrder – raw payload from ShopeeFood webhook
 * @returns {import('../../models/delivery-order').DeliveryOrder}
 */
function mapShopeeFoodOrderToDeliveryOrder(shopeefoodOrder) {
  const items = (shopeefoodOrder.item_list || shopeefoodOrder.items || []).map((item) =>
    createOrderItem({
      name: item.item_name || item.name || 'Unknown Item',
      quantity: item.quantity || 1,
      // ShopeeFood prices are in minor units (cents / xu)
      price: (item.item_price || item.price || 0) / 100,
      notes: item.note || item.notes || null,
    }),
  );

  const totalAmount =
    (shopeefoodOrder.total_price || shopeefoodOrder.totalAmount || 0) / 100 ||
    items.reduce((sum, i) => sum + i.price * i.quantity, 0);

  const driverInfo = (shopeefoodOrder.driver_info || shopeefoodOrder.driver)
    ? createDriverInfo({
        name:
          shopeefoodOrder.driver_info?.driver_name ||
          shopeefoodOrder.driver?.name ||
          '',
        phone:
          shopeefoodOrder.driver_info?.driver_phone ||
          shopeefoodOrder.driver?.phone ||
          '',
        licensePlate:
          shopeefoodOrder.driver_info?.license_plate_number ||
          shopeefoodOrder.driver?.licensePlate ||
          '',
      })
    : null;

  const estimatedPickupTime = shopeefoodOrder.estimated_pickup_time
    ? new Date(shopeefoodOrder.estimated_pickup_time * 1000) // Unix → Date
    : null;

  const buyerInfo = shopeefoodOrder.buyer_info || shopeefoodOrder.customer || {};
  const shippingAddress =
    shopeefoodOrder.shipping_address ||
    shopeefoodOrder.delivery_address ||
    {};

  return createDeliveryOrder({
    platformOrderId: shopeefoodOrder.order_sn || shopeefoodOrder.orderId || shopeefoodOrder.id || '',
    platform: DeliveryPlatform.SHOPEEFOOD,
    status: _mapShopeeFoodStatus(
      shopeefoodOrder.order_status || shopeefoodOrder.status,
    ),
    customerName:
      buyerInfo.buyer_name ||
      buyerInfo.name ||
      'ShopeeFood Customer',
    customerPhone:
      buyerInfo.buyer_phone ||
      buyerInfo.phone ||
      null,
    deliveryAddress:
      shippingAddress.full_address ||
      shippingAddress.address ||
      null,
    items,
    totalAmount,
    platformFee:
      (shopeefoodOrder.service_fee || shopeefoodOrder.platformFee || 0) / 100,
    specialInstructions:
      shopeefoodOrder.note ||
      shopeefoodOrder.specialInstructions ||
      null,
    estimatedPickupTime,
    driverInfo,
    createdAt: shopeefoodOrder.create_time
      ? new Date(shopeefoodOrder.create_time * 1000)
      : new Date(),
  });
}

/**
 * Map ShopeeFood order status strings to internal DeliveryStatus.
 *
 * @param {string} shopeefoodStatus
 * @returns {string}
 */
function _mapShopeeFoodStatus(shopeefoodStatus) {
  if (!shopeefoodStatus) return DeliveryStatus.NEW;

  const statusMap = {
    RECEIVED: DeliveryStatus.NEW,
    WAITING_FOR_MERCHANT_CONFIRMATION: DeliveryStatus.NEW,
    MERCHANT_CONFIRMED: DeliveryStatus.ACCEPTED,
    PREPARING: DeliveryStatus.PREPARING,
    READY_FOR_PICKUP: DeliveryStatus.READY_FOR_PICKUP,
    DRIVER_ASSIGNED: DeliveryStatus.ACCEPTED,
    PICKED_UP: DeliveryStatus.PICKED_UP,
    DELIVERING: DeliveryStatus.PICKED_UP,
    COMPLETED: DeliveryStatus.COMPLETED,
    DELIVERED: DeliveryStatus.COMPLETED,
    CANCELLED: DeliveryStatus.CANCELLED,
    REJECTED: DeliveryStatus.CANCELLED,
  };

  return statusMap[shopeefoodStatus.toUpperCase()] || DeliveryStatus.NEW;
}

module.exports = { mapShopeeFoodOrderToDeliveryOrder, _mapShopeeFoodStatus };

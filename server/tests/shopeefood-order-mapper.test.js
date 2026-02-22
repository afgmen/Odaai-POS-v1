'use strict';

const {
  mapShopeeFoodOrderToDeliveryOrder,
  _mapShopeeFoodStatus,
} = require('../src/connectors/shopeefood/shopeefood-order-mapper');
const { DeliveryPlatform, DeliveryStatus } = require('../src/models/delivery-order');

describe('mapShopeeFoodOrderToDeliveryOrder', () => {
  const sampleOrder = {
    order_sn: 'SF-ORDER-001',
    order_status: 'RECEIVED',
    buyer_info: {
      buyer_name: 'Nguyen Thi B',
      buyer_phone: '+84912345678',
    },
    shipping_address: {
      full_address: '456 Nguyen Hue Blvd, District 1, HCMC',
    },
    item_list: [
      {
        item_name: 'Banh Mi Thit',
        quantity: 2,
        item_price: 3500000, // 35000 VND in minor units (/100)
        note: 'Extra chili',
      },
      {
        item_name: 'Ca Phe Sua Da',
        quantity: 1,
        item_price: 2500000, // 25000 VND in minor units
      },
    ],
    total_price: 9500000, // 95000 VND in minor units
    service_fee: 950000, // 9500 VND in minor units
    estimated_pickup_time: 1700000000, // Unix timestamp
    driver_info: {
      driver_name: 'Le Van C',
      driver_phone: '+84987654321',
      license_plate_number: '59B-67890',
    },
    note: 'Please deliver quickly',
    create_time: 1699999000,
  };

  test('maps order_sn to platformOrderId', () => {
    const order = mapShopeeFoodOrderToDeliveryOrder(sampleOrder);
    expect(order.platformOrderId).toBe('SF-ORDER-001');
  });

  test('maps buyer_info.buyer_name to customerName', () => {
    const order = mapShopeeFoodOrderToDeliveryOrder(sampleOrder);
    expect(order.customerName).toBe('Nguyen Thi B');
  });

  test('maps buyer_info.buyer_phone to customerPhone', () => {
    const order = mapShopeeFoodOrderToDeliveryOrder(sampleOrder);
    expect(order.customerPhone).toBe('+84912345678');
  });

  test('maps shipping_address.full_address to deliveryAddress', () => {
    const order = mapShopeeFoodOrderToDeliveryOrder(sampleOrder);
    expect(order.deliveryAddress).toBe('456 Nguyen Hue Blvd, District 1, HCMC');
  });

  test('maps item_list to items with price /100 conversion', () => {
    const order = mapShopeeFoodOrderToDeliveryOrder(sampleOrder);

    expect(order.items).toHaveLength(2);
    expect(order.items[0].name).toBe('Banh Mi Thit');
    expect(order.items[0].quantity).toBe(2);
    expect(order.items[0].price).toBe(35000); // 3500000 / 100
    expect(order.items[0].notes).toBe('Extra chili');

    expect(order.items[1].name).toBe('Ca Phe Sua Da');
    expect(order.items[1].quantity).toBe(1);
    expect(order.items[1].price).toBe(25000); // 2500000 / 100
    expect(order.items[1].notes).toBeNull();
  });

  test('maps total_price to totalAmount with /100 conversion', () => {
    const order = mapShopeeFoodOrderToDeliveryOrder(sampleOrder);
    expect(order.totalAmount).toBe(95000); // 9500000 / 100
  });

  test('maps estimated_pickup_time (unix timestamp) to Date', () => {
    const order = mapShopeeFoodOrderToDeliveryOrder(sampleOrder);
    expect(order.estimatedPickupTime).toBeInstanceOf(Date);
    expect(order.estimatedPickupTime.getTime()).toBe(1700000000 * 1000);
  });

  test('maps driver_info to driverInfo', () => {
    const order = mapShopeeFoodOrderToDeliveryOrder(sampleOrder);
    expect(order.driverInfo).not.toBeNull();
    expect(order.driverInfo.name).toBe('Le Van C');
    expect(order.driverInfo.phone).toBe('+84987654321');
    expect(order.driverInfo.licensePlate).toBe('59B-67890');
  });

  test('sets platform to DeliveryPlatform.SHOPEEFOOD', () => {
    const order = mapShopeeFoodOrderToDeliveryOrder(sampleOrder);
    expect(order.platform).toBe(DeliveryPlatform.SHOPEEFOOD);
  });

  test('maps service_fee to platformFee with /100 conversion', () => {
    const order = mapShopeeFoodOrderToDeliveryOrder(sampleOrder);
    expect(order.platformFee).toBe(9500); // 950000 / 100
  });

  test('maps note to specialInstructions', () => {
    const order = mapShopeeFoodOrderToDeliveryOrder(sampleOrder);
    expect(order.specialInstructions).toBe('Please deliver quickly');
  });

  test('generates a unique internal id for each call', () => {
    const o1 = mapShopeeFoodOrderToDeliveryOrder(sampleOrder);
    const o2 = mapShopeeFoodOrderToDeliveryOrder(sampleOrder);
    expect(o1.id).not.toBe(o2.id);
  });

  test('handles missing fields gracefully with defaults', () => {
    const order = mapShopeeFoodOrderToDeliveryOrder({});

    expect(order.platformOrderId).toBe('');
    expect(order.platform).toBe(DeliveryPlatform.SHOPEEFOOD);
    expect(order.status).toBe(DeliveryStatus.NEW);
    expect(order.customerName).toBe('ShopeeFood Customer');
    expect(order.customerPhone).toBeNull();
    expect(order.deliveryAddress).toBeNull();
    expect(order.items).toEqual([]);
    expect(order.totalAmount).toBe(0);
    expect(order.platformFee).toBe(0);
    expect(order.specialInstructions).toBeNull();
    expect(order.estimatedPickupTime).toBeNull();
    expect(order.driverInfo).toBeNull();
  });

  test('returns null driverInfo when no driver_info present', () => {
    const orderWithoutDriver = { ...sampleOrder };
    delete orderWithoutDriver.driver_info;

    const order = mapShopeeFoodOrderToDeliveryOrder(orderWithoutDriver);
    expect(order.driverInfo).toBeNull();
  });

  test('falls back to items field when item_list is absent', () => {
    const orderWithItemsField = {
      ...sampleOrder,
      items: [{ name: 'Pho', quantity: 1, price: 8000000 }],
    };
    delete orderWithItemsField.item_list;

    const order = mapShopeeFoodOrderToDeliveryOrder(orderWithItemsField);
    expect(order.items).toHaveLength(1);
    expect(order.items[0].name).toBe('Pho');
    expect(order.items[0].price).toBe(80000); // 8000000 / 100
  });

  test('falls back to customer field when buyer_info is absent', () => {
    const orderWithCustomer = {
      ...sampleOrder,
      customer: { name: 'Tran D', phone: '+84900000001' },
    };
    delete orderWithCustomer.buyer_info;

    const order = mapShopeeFoodOrderToDeliveryOrder(orderWithCustomer);
    expect(order.customerName).toBe('Tran D');
    expect(order.customerPhone).toBe('+84900000001');
  });

  test('falls back to delivery_address when shipping_address is absent', () => {
    const orderWithDeliveryAddress = {
      ...sampleOrder,
      delivery_address: { address: '789 Backup Street' },
    };
    delete orderWithDeliveryAddress.shipping_address;

    const order = mapShopeeFoodOrderToDeliveryOrder(orderWithDeliveryAddress);
    expect(order.deliveryAddress).toBe('789 Backup Street');
  });
});

describe('_mapShopeeFoodStatus', () => {
  test.each([
    ['RECEIVED', DeliveryStatus.NEW],
    ['WAITING_FOR_MERCHANT_CONFIRMATION', DeliveryStatus.NEW],
    ['MERCHANT_CONFIRMED', DeliveryStatus.ACCEPTED],
    ['PREPARING', DeliveryStatus.PREPARING],
    ['READY_FOR_PICKUP', DeliveryStatus.READY_FOR_PICKUP],
    ['DRIVER_ASSIGNED', DeliveryStatus.ACCEPTED],
    ['PICKED_UP', DeliveryStatus.PICKED_UP],
    ['DELIVERING', DeliveryStatus.PICKED_UP],
    ['COMPLETED', DeliveryStatus.COMPLETED],
    ['DELIVERED', DeliveryStatus.COMPLETED],
    ['CANCELLED', DeliveryStatus.CANCELLED],
    ['REJECTED', DeliveryStatus.CANCELLED],
    ['UNKNOWN_STATUS', DeliveryStatus.NEW],  // fallback
    [null, DeliveryStatus.NEW],              // null fallback
    [undefined, DeliveryStatus.NEW],         // undefined fallback
  ])('maps "%s" → %s', (shopeefoodStatus, expected) => {
    expect(_mapShopeeFoodStatus(shopeefoodStatus)).toBe(expected);
  });

  test('is case-insensitive', () => {
    expect(_mapShopeeFoodStatus('received')).toBe(DeliveryStatus.NEW);
    expect(_mapShopeeFoodStatus('Preparing')).toBe(DeliveryStatus.PREPARING);
    expect(_mapShopeeFoodStatus('cancelled')).toBe(DeliveryStatus.CANCELLED);
  });
});

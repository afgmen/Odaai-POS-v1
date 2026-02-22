'use strict';

const {
  mapGrabOrderToDeliveryOrder,
  _mapGrabStatus,
} = require('../src/connectors/grab/grab-order-mapper');
const { DeliveryPlatform, DeliveryStatus } = require('../src/models/delivery-order');

describe('GrabOrderMapper', () => {
  const sampleGrabOrder = {
    orderID: 'GRAB-123456',
    orderState: 'PLACED',
    submittedDateTime: '2024-01-15T10:30:00Z',
    diner: {
      name: 'Nguyen Van A',
      phone: '+84901234567',
    },
    deliveryAddress: {
      address: '123 Le Loi Street, District 1, Ho Chi Minh City',
    },
    items: [
      { name: 'Pho Bo', quantity: 2, price: 85000, specialInstructions: 'No cilantro' },
      { name: 'Tra Da', quantity: 2, price: 10000 },
    ],
    totalFee: 190000,
    merchantFee: 19000,
    specialInstructions: 'Ring the bell',
    estimatedPickupTime: '2024-01-15T10:50:00Z',
  };

  test('maps basic order fields correctly', () => {
    const order = mapGrabOrderToDeliveryOrder(sampleGrabOrder);

    expect(order.platformOrderId).toBe('GRAB-123456');
    expect(order.platform).toBe(DeliveryPlatform.GRAB);
    expect(order.status).toBe(DeliveryStatus.NEW);
    expect(order.customerName).toBe('Nguyen Van A');
    expect(order.customerPhone).toBe('+84901234567');
    expect(order.deliveryAddress).toBe('123 Le Loi Street, District 1, Ho Chi Minh City');
    expect(order.currency).toBe('VND');
  });

  test('maps items correctly', () => {
    const order = mapGrabOrderToDeliveryOrder(sampleGrabOrder);

    expect(order.items).toHaveLength(2);
    expect(order.items[0].name).toBe('Pho Bo');
    expect(order.items[0].quantity).toBe(2);
    expect(order.items[0].price).toBe(85000);
    expect(order.items[0].notes).toBe('No cilantro');
    expect(order.items[1].notes).toBeNull();
  });

  test('maps total amount and platform fee', () => {
    const order = mapGrabOrderToDeliveryOrder(sampleGrabOrder);

    expect(order.totalAmount).toBe(190000);
    expect(order.platformFee).toBe(19000);
  });

  test('maps special instructions', () => {
    const order = mapGrabOrderToDeliveryOrder(sampleGrabOrder);
    expect(order.specialInstructions).toBe('Ring the bell');
  });

  test('maps estimated pickup time', () => {
    const order = mapGrabOrderToDeliveryOrder(sampleGrabOrder);
    expect(order.estimatedPickupTime).toBeInstanceOf(Date);
  });

  test('returns null driverInfo when no driver', () => {
    const order = mapGrabOrderToDeliveryOrder(sampleGrabOrder);
    expect(order.driverInfo).toBeNull();
  });

  test('maps driver info when present', () => {
    const orderWithDriver = {
      ...sampleGrabOrder,
      driver: { name: 'Tran Van B', phone: '+84909876543', licensePlate: '51A-12345' },
    };
    const order = mapGrabOrderToDeliveryOrder(orderWithDriver);

    expect(order.driverInfo).not.toBeNull();
    expect(order.driverInfo.name).toBe('Tran Van B');
    expect(order.driverInfo.licensePlate).toBe('51A-12345');
  });

  test('generates a unique internal id', () => {
    const o1 = mapGrabOrderToDeliveryOrder(sampleGrabOrder);
    const o2 = mapGrabOrderToDeliveryOrder(sampleGrabOrder);
    expect(o1.id).not.toBe(o2.id);
  });
});

describe('_mapGrabStatus', () => {
  test.each([
    ['PLACED', DeliveryStatus.NEW],
    ['SUBMITTED', DeliveryStatus.NEW],
    ['ACCEPTED', DeliveryStatus.ACCEPTED],
    ['DRIVER_HEADING_TO_RESTAURANT', DeliveryStatus.PREPARING],
    ['DRIVER_AT_RESTAURANT', DeliveryStatus.READY_FOR_PICKUP],
    ['DRIVER_HEADING_TO_CUSTOMER', DeliveryStatus.PICKED_UP],
    ['COMPLETED', DeliveryStatus.COMPLETED],
    ['DELIVERED', DeliveryStatus.COMPLETED],
    ['CANCELLED', DeliveryStatus.CANCELLED],
    ['UNKNOWN_STATUS', DeliveryStatus.NEW], // fallback
    [null, DeliveryStatus.NEW],             // null fallback
  ])('maps "%s" → %s', (grabStatus, expected) => {
    expect(_mapGrabStatus(grabStatus)).toBe(expected);
  });
});

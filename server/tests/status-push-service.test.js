'use strict';

const {
  pushStatusWithRetry,
  mapKdsStatusToDeliveryStatus,
} = require('../src/services/status-push-service');

// Speed up tests by replacing setTimeout with fake timers
jest.useFakeTimers();

// ── mapKdsStatusToDeliveryStatus ─────────────────────────────────────────

describe('mapKdsStatusToDeliveryStatus', () => {
  test('PREPARING → PREPARING', () => {
    expect(mapKdsStatusToDeliveryStatus('PREPARING')).toBe('PREPARING');
  });

  test('READY → READY_FOR_PICKUP', () => {
    expect(mapKdsStatusToDeliveryStatus('READY')).toBe('READY_FOR_PICKUP');
  });

  test('SERVED → COMPLETED', () => {
    expect(mapKdsStatusToDeliveryStatus('SERVED')).toBe('COMPLETED');
  });

  test('PENDING → null (no delivery mapping)', () => {
    expect(mapKdsStatusToDeliveryStatus('PENDING')).toBeNull();
  });

  test('CANCELLED → null', () => {
    expect(mapKdsStatusToDeliveryStatus('CANCELLED')).toBeNull();
  });

  test('undefined → null', () => {
    expect(mapKdsStatusToDeliveryStatus(undefined)).toBeNull();
  });

  test('case-insensitive: preparing → PREPARING', () => {
    expect(mapKdsStatusToDeliveryStatus('preparing')).toBe('PREPARING');
  });

  test('case-insensitive: ready → READY_FOR_PICKUP', () => {
    expect(mapKdsStatusToDeliveryStatus('ready')).toBe('READY_FOR_PICKUP');
  });
});

// ── pushStatusWithRetry ───────────────────────────────────────────────────

describe('pushStatusWithRetry', () => {
  beforeEach(() => {
    jest.clearAllTimers();
    jest.clearAllMocks();
  });

  test('calls connectorFn once on success', async () => {
    const connectorFn = jest.fn().mockResolvedValue(undefined);

    await pushStatusWithRetry({
      platformOrderId: 'GRAB-001',
      platform: 'grab',
      newStatus: 'PREPARING',
      connectorFn,
    });

    expect(connectorFn).toHaveBeenCalledTimes(1);
    expect(connectorFn).toHaveBeenCalledWith('GRAB-001', 'PREPARING');
  });

  test('retries on failure and succeeds on second attempt', async () => {
    const connectorFn = jest
      .fn()
      .mockRejectedValueOnce(new Error('Transient error'))
      .mockResolvedValueOnce(undefined);

    const pushPromise = pushStatusWithRetry({
      platformOrderId: 'GRAB-002',
      platform: 'grab',
      newStatus: 'READY_FOR_PICKUP',
      connectorFn,
    });

    // Drain all pending timers (including the retry sleep) and flush microtasks
    await jest.runAllTimersAsync();

    await pushPromise;

    expect(connectorFn).toHaveBeenCalledTimes(2);
  });

  test('exhausts maxAttempts and does not throw (fire-and-forget)', async () => {
    const connectorFn = jest
      .fn()
      .mockRejectedValue(new Error('Persistent failure'));

    const pushPromise = pushStatusWithRetry({
      platformOrderId: 'GRAB-003',
      platform: 'grab',
      newStatus: 'COMPLETED',
      connectorFn,
    });

    // Drain all pending timers (covers the 1s and 2s retry delays) and flush microtasks
    await jest.runAllTimersAsync();

    // Should resolve (not reject) even after all failures
    await expect(pushPromise).resolves.toBeUndefined();
    expect(connectorFn).toHaveBeenCalledTimes(3); // maxAttempts = 3
  });

  test('passes platformOrderId and newStatus to connectorFn', async () => {
    const connectorFn = jest.fn().mockResolvedValue(undefined);

    await pushStatusWithRetry({
      platformOrderId: 'GRAB-XYZ',
      platform: 'grab',
      newStatus: 'CANCELLED',
      connectorFn,
    });

    expect(connectorFn).toHaveBeenCalledWith('GRAB-XYZ', 'CANCELLED');
  });
});

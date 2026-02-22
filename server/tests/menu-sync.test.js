'use strict';

/**
 * Tests for the enhanced /api/menu/sync route and grab-menu-sync mapper.
 *
 * We mock the GrabConnector so no real HTTP calls are made.
 */

// ── Module mocking ────────────────────────────────────────────────────────
jest.mock('../src/connectors/grab/grab-connector', () => ({
  syncMenu: jest.fn(),
}));

jest.mock('../src/connectors/connector-registry', () => {
  const grabConnector = require('../src/connectors/grab/grab-connector');
  return {
    getActiveConnectors: () => [
      { name: 'grab', connector: grabConnector, active: true },
    ],
    getStatusSummary: () => [],
  };
});

const grabConnector = require('../src/connectors/grab/grab-connector');
const express = require('express');
const request = require('supertest');

// Build a minimal Express app wired with the menu router
function buildApp() {
  const app = express();
  app.use(express.json());
  const menuRouter = require('../src/routes/api/menu');
  app.use('/api/menu', menuRouter);
  return app;
}

// ── Sample menu payload ───────────────────────────────────────────────────
const sampleMenu = {
  categories: [
    {
      id: 'cat-1',
      name: 'Main Dishes',
      items: [
        {
          id: 'item-1',
          name: 'Pho Bo',
          description: 'Beef noodle soup',
          price: 85000,
          available: true,
          imageUrl: null,
        },
        {
          id: 'item-2',
          name: 'Bun Bo Hue',
          description: 'Spicy beef noodle',
          price: 75000,
          available: false,
          imageUrl: 'https://example.com/bun.jpg',
        },
      ],
    },
    {
      id: 'cat-2',
      name: 'Drinks',
      items: [
        {
          id: 'item-3',
          name: 'Tra Da',
          description: 'Iced tea',
          price: 10000,
          available: true,
          imageUrl: null,
        },
      ],
    },
  ],
};

// ── Test suites ───────────────────────────────────────────────────────────

describe('POST /api/menu/sync', () => {
  let app;

  beforeEach(() => {
    jest.clearAllMocks();
    // Force module re-require so the router is fresh each test
    jest.isolateModules(() => {
      app = buildApp();
    });
    app = buildApp();
  });

  test('returns 400 when menuData is missing', async () => {
    const res = await request(app)
      .post('/api/menu/sync')
      .send({ platform: 'grab' })
      .expect(400);

    expect(res.body.error).toBe('menuData is required');
  });

  test('returns 400 when menuData.categories is not an array', async () => {
    const res = await request(app)
      .post('/api/menu/sync')
      .send({ menuData: { categories: 'not-an-array' } })
      .expect(400);

    expect(res.body.error).toMatch(/categories must be an array/);
  });

  test('returns 400 when platform is unknown', async () => {
    const res = await request(app)
      .post('/api/menu/sync')
      .send({ platform: 'unknownplatform', menuData: sampleMenu })
      .expect(400);

    expect(res.body.error).toMatch(/Unknown platform/);
  });

  test('returns 200 and success=true when grab sync succeeds', async () => {
    grabConnector.syncMenu.mockResolvedValueOnce({ success: true });

    const res = await request(app)
      .post('/api/menu/sync')
      .send({ platform: 'grab', menuData: sampleMenu })
      .expect(200);

    expect(res.body.success).toBe(true);
    expect(res.body.allSucceeded).toBe(true);
    expect(res.body.platforms.grab.success).toBe(true);
    expect(grabConnector.syncMenu).toHaveBeenCalledWith(sampleMenu);
  });

  test('returns 502 and success=false when grab sync fails', async () => {
    grabConnector.syncMenu.mockRejectedValueOnce(new Error('GrabFood API down'));

    const res = await request(app)
      .post('/api/menu/sync')
      .send({ platform: 'grab', menuData: sampleMenu })
      .expect(502);

    expect(res.body.success).toBe(false);
    expect(res.body.allSucceeded).toBe(false);
    expect(res.body.platforms.grab.success).toBe(false);
    expect(res.body.platforms.grab.error).toMatch(/GrabFood API down/);
  });

  test('platform=all syncs all available platforms', async () => {
    grabConnector.syncMenu.mockResolvedValueOnce({ synced: true });

    const res = await request(app)
      .post('/api/menu/sync')
      .send({ platform: 'all', menuData: sampleMenu })
      .expect(200);

    expect(res.body.platforms.grab).toBeDefined();
    expect(grabConnector.syncMenu).toHaveBeenCalledTimes(1);
  });

  test('defaults to platform=all when platform is omitted', async () => {
    grabConnector.syncMenu.mockResolvedValueOnce({ synced: true });

    const res = await request(app)
      .post('/api/menu/sync')
      .send({ menuData: sampleMenu })
      .expect(200);

    expect(res.body.platforms.grab).toBeDefined();
  });

  test('includes durationMs in platform result', async () => {
    grabConnector.syncMenu.mockResolvedValueOnce({});

    const res = await request(app)
      .post('/api/menu/sync')
      .send({ menuData: sampleMenu })
      .expect(200);

    expect(typeof res.body.platforms.grab.durationMs).toBe('number');
    expect(res.body.platforms.grab.durationMs).toBeGreaterThanOrEqual(0);
  });
});

// ── grab-menu-sync mapper ─────────────────────────────────────────────────

// Re-require the mapper directly (not via the connector) so we can test
// the mapping function without involving Grab auth/HTTP.
const { syncMenuToGrab } = require('../src/connectors/grab/grab-menu-sync');

jest.mock('../src/connectors/grab/grab-auth', () => ({
  getAccessToken: jest.fn().mockResolvedValue('mock-token'),
}));
jest.mock('axios');
const axios = require('axios');

describe('grab-menu-sync mapping', () => {
  test('maps categories and items to GrabFood format', async () => {
    axios.put = jest.fn().mockResolvedValue({ data: { success: true } });

    await syncMenuToGrab(sampleMenu);

    const calledPayload = axios.put.mock.calls[0][1];

    expect(calledPayload.categories).toHaveLength(2);

    const mainDishes = calledPayload.categories[0];
    expect(mainDishes.name).toBe('Main Dishes');
    expect(mainDishes.ID).toBe('cat-1');
    expect(mainDishes.items).toHaveLength(2);

    const phoBoItem = mainDishes.items[0];
    expect(phoBoItem.name).toBe('Pho Bo');
    expect(phoBoItem.priceInMinors).toBe(8500000); // 85000 * 100
    expect(phoBoItem.available).toBe(true);
    expect(phoBoItem.photos).toEqual([]);
  });

  test('marks unavailable items correctly', async () => {
    axios.put = jest.fn().mockResolvedValue({ data: {} });

    await syncMenuToGrab(sampleMenu);

    const bunBoItem = axios.put.mock.calls[0][1].categories[0].items[1];
    expect(bunBoItem.available).toBe(false);
  });

  test('includes photo URL when imageUrl is provided', async () => {
    axios.put = jest.fn().mockResolvedValue({ data: {} });

    await syncMenuToGrab(sampleMenu);

    const bunBoItem = axios.put.mock.calls[0][1].categories[0].items[1];
    expect(bunBoItem.photos).toEqual([{ URL: 'https://example.com/bun.jpg' }]);
  });

  test('throws on API error', async () => {
    axios.put = jest.fn().mockRejectedValue(new Error('Network error'));

    await expect(syncMenuToGrab(sampleMenu)).rejects.toThrow('Network error');
  });
});

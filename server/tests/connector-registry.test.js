'use strict';

// Mock logger to suppress output during tests
jest.mock('../src/utils/logger', () => ({
  info: jest.fn(),
  warn: jest.fn(),
  debug: jest.fn(),
  error: jest.fn(),
}));

const registry = require('../src/connectors/connector-registry');

// Helper to build a mock connector with a controllable syncMenu
function makeMockConnector(syncMenuImpl) {
  return {
    syncMenu: syncMenuImpl || jest.fn().mockResolvedValue({ ok: true }),
  };
}

// Reset the singleton's internal map between every test so tests are isolated
beforeEach(() => {
  registry._connectors.clear();
});

// ── Registration ──────────────────────────────────────────────────────────

describe('ConnectorRegistry.register()', () => {
  test('makes the connector retrievable via getConnector()', () => {
    const connector = makeMockConnector();
    registry.register('grab', connector, true);

    expect(registry.getConnector('grab')).toBe(connector);
  });

  test('register with active=true marks it active', () => {
    const connector = makeMockConnector();
    registry.register('grab', connector, true);

    expect(registry.isActive('grab')).toBe(true);
  });

  test('register with active=false marks it inactive', () => {
    const connector = makeMockConnector();
    registry.register('shopeefood', connector, false);

    expect(registry.isActive('shopeefood')).toBe(false);
  });

  test('overwrites a previously registered connector for the same platform', () => {
    const first = makeMockConnector();
    const second = makeMockConnector();

    registry.register('grab', first, true);
    registry.register('grab', second, false);

    expect(registry.getConnector('grab')).toBe(second);
    expect(registry.isActive('grab')).toBe(false);
  });
});

// ── Lookup ────────────────────────────────────────────────────────────────

describe('ConnectorRegistry.getConnector()', () => {
  test('returns null for an unknown platform', () => {
    expect(registry.getConnector('nonexistent')).toBeNull();
  });

  test('returns the registered connector instance', () => {
    const connector = makeMockConnector();
    registry.register('grab', connector, true);

    expect(registry.getConnector('grab')).toBe(connector);
  });
});

describe('ConnectorRegistry.getAllConnectors()', () => {
  test('returns an empty array when no connectors are registered', () => {
    expect(registry.getAllConnectors()).toEqual([]);
  });

  test('returns all registered connectors (active and inactive)', () => {
    const c1 = makeMockConnector();
    const c2 = makeMockConnector();

    registry.register('grab', c1, true);
    registry.register('shopeefood', c2, false);

    const all = registry.getAllConnectors();
    expect(all).toHaveLength(2);

    const names = all.map((e) => e.name);
    expect(names).toContain('grab');
    expect(names).toContain('shopeefood');
  });

  test('each entry has name, connector, active, and registeredAt fields', () => {
    registry.register('grab', makeMockConnector(), true);

    const [entry] = registry.getAllConnectors();
    expect(entry).toHaveProperty('name', 'grab');
    expect(entry).toHaveProperty('connector');
    expect(entry).toHaveProperty('active', true);
    expect(entry).toHaveProperty('registeredAt');
    expect(entry.registeredAt).toBeInstanceOf(Date);
  });
});

describe('ConnectorRegistry.getActiveConnectors()', () => {
  test('returns only active connectors', () => {
    registry.register('grab', makeMockConnector(), true);
    registry.register('shopeefood', makeMockConnector(), false);

    const active = registry.getActiveConnectors();
    expect(active).toHaveLength(1);
    expect(active[0].name).toBe('grab');
  });

  test('returns empty array when no connectors are active', () => {
    registry.register('grab', makeMockConnector(), false);
    registry.register('shopeefood', makeMockConnector(), false);

    expect(registry.getActiveConnectors()).toEqual([]);
  });

  test('returns all connectors when all are active', () => {
    registry.register('grab', makeMockConnector(), true);
    registry.register('shopeefood', makeMockConnector(), true);

    expect(registry.getActiveConnectors()).toHaveLength(2);
  });
});

describe('ConnectorRegistry.isActive()', () => {
  test('returns true for an active connector', () => {
    registry.register('grab', makeMockConnector(), true);
    expect(registry.isActive('grab')).toBe(true);
  });

  test('returns false for an inactive connector', () => {
    registry.register('grab', makeMockConnector(), false);
    expect(registry.isActive('grab')).toBe(false);
  });

  test('returns false for an unregistered platform', () => {
    expect(registry.isActive('unknown')).toBe(false);
  });
});

// ── Status summary ─────────────────────────────────────────────────────────

describe('ConnectorRegistry.getStatusSummary()', () => {
  test('returns an empty array when nothing is registered', () => {
    expect(registry.getStatusSummary()).toEqual([]);
  });

  test('returns serializable array with name, active, and registeredAt (ISO string)', () => {
    registry.register('grab', makeMockConnector(), true);
    registry.register('shopeefood', makeMockConnector(), false);

    const summary = registry.getStatusSummary();
    expect(summary).toHaveLength(2);

    const grab = summary.find((s) => s.name === 'grab');
    expect(grab).toBeDefined();
    expect(grab.active).toBe(true);
    expect(typeof grab.registeredAt).toBe('string');
    // Verify it is a valid ISO date string
    expect(() => new Date(grab.registeredAt)).not.toThrow();
    expect(new Date(grab.registeredAt).toISOString()).toBe(grab.registeredAt);

    const shopee = summary.find((s) => s.name === 'shopeefood');
    expect(shopee).toBeDefined();
    expect(shopee.active).toBe(false);
  });

  test('summary does not include the connector object itself (serializable)', () => {
    registry.register('grab', makeMockConnector(), true);
    const [entry] = registry.getStatusSummary();
    expect(entry).not.toHaveProperty('connector');
  });
});

// ── broadcastMenuUpdate ────────────────────────────────────────────────────

describe('ConnectorRegistry.broadcastMenuUpdate()', () => {
  const sampleMenu = { categories: [] };

  test('returns an empty array when no active connectors are registered', async () => {
    const results = await registry.broadcastMenuUpdate(sampleMenu);
    expect(results).toEqual([]);
  });

  test('returns an empty array when connectors are registered but all inactive', async () => {
    registry.register('grab', makeMockConnector(), false);
    registry.register('shopeefood', makeMockConnector(), false);

    const results = await registry.broadcastMenuUpdate(sampleMenu);
    expect(results).toEqual([]);
  });

  test('calls syncMenu on active connectors with the menu data', async () => {
    const mockConnector = { syncMenu: jest.fn().mockResolvedValue({ ok: true }) };
    registry.register('grab', mockConnector, true);

    await registry.broadcastMenuUpdate(sampleMenu);

    expect(mockConnector.syncMenu).toHaveBeenCalledTimes(1);
    expect(mockConnector.syncMenu).toHaveBeenCalledWith(sampleMenu);
  });

  test('skips inactive connectors (does not call syncMenu on them)', async () => {
    const activeConnector = { syncMenu: jest.fn().mockResolvedValue({ ok: true }) };
    const inactiveConnector = { syncMenu: jest.fn() };

    registry.register('grab', activeConnector, true);
    registry.register('shopeefood', inactiveConnector, false);

    await registry.broadcastMenuUpdate(sampleMenu);

    expect(activeConnector.syncMenu).toHaveBeenCalledTimes(1);
    expect(inactiveConnector.syncMenu).not.toHaveBeenCalled();
  });

  test('returns a result entry per active connector on success', async () => {
    const c1 = { syncMenu: jest.fn().mockResolvedValue({ synced: true }) };
    const c2 = { syncMenu: jest.fn().mockResolvedValue({ synced: true }) };

    registry.register('grab', c1, true);
    registry.register('shopeefood', c2, true);

    const results = await registry.broadcastMenuUpdate(sampleMenu);

    expect(results).toHaveLength(2);

    const grabResult = results.find((r) => r.platform === 'grab');
    expect(grabResult.success).toBe(true);
    expect(typeof grabResult.durationMs).toBe('number');

    const shopeeResult = results.find((r) => r.platform === 'shopeefood');
    expect(shopeeResult.success).toBe(true);
  });

  test('handles individual connector failures without throwing', async () => {
    const failingConnector = {
      syncMenu: jest.fn().mockRejectedValue(new Error('API unavailable')),
    };
    const successConnector = {
      syncMenu: jest.fn().mockResolvedValue({ ok: true }),
    };

    registry.register('shopeefood', failingConnector, true);
    registry.register('grab', successConnector, true);

    // Should NOT throw even though one connector fails
    let results;
    await expect(
      (async () => {
        results = await registry.broadcastMenuUpdate(sampleMenu);
      })(),
    ).resolves.not.toThrow();

    expect(results).toHaveLength(2);

    const shopeeResult = results.find((r) => r.platform === 'shopeefood');
    expect(shopeeResult.success).toBe(false);
    expect(shopeeResult.error).toBe('API unavailable');

    const grabResult = results.find((r) => r.platform === 'grab');
    expect(grabResult.success).toBe(true);
  });

  test('success result includes data from syncMenu response', async () => {
    const mockData = { categories_synced: 3, items_synced: 10 };
    const connector = { syncMenu: jest.fn().mockResolvedValue(mockData) };
    registry.register('grab', connector, true);

    const results = await registry.broadcastMenuUpdate(sampleMenu);
    expect(results[0].data).toEqual(mockData);
  });

  test('failure result includes error message and no data field', async () => {
    const connector = {
      syncMenu: jest.fn().mockRejectedValue(new Error('Timeout')),
    };
    registry.register('grab', connector, true);

    const results = await registry.broadcastMenuUpdate(sampleMenu);
    expect(results[0].success).toBe(false);
    expect(results[0].error).toBe('Timeout');
    expect(results[0]).not.toHaveProperty('data');
  });

  test('each result includes durationMs as a non-negative number', async () => {
    const connector = { syncMenu: jest.fn().mockResolvedValue({}) };
    registry.register('grab', connector, true);

    const results = await registry.broadcastMenuUpdate(sampleMenu);
    expect(typeof results[0].durationMs).toBe('number');
    expect(results[0].durationMs).toBeGreaterThanOrEqual(0);
  });
});

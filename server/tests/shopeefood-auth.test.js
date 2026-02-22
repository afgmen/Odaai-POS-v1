'use strict';

// Mock the config module so auth uses test credentials
jest.mock('../src/config', () => ({
  shopeefood: {
    appId: 'test_app_id',
    appSecret: 'test_app_secret',
    apiBaseUrl: 'https://test.shopee.vn',
  },
}));

// Also mock logger to suppress output during tests
jest.mock('../src/utils/logger', () => ({
  warn: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  error: jest.fn(),
}));

// Require after mocks are in place
const shopeefoodAuth = require('../src/connectors/shopeefood/shopeefood-auth');

describe('ShopeeFoodAuth.getAuthParams() — with credentials configured', () => {
  test('returns an object with app_id, timestamp, and sign', () => {
    const params = shopeefoodAuth.getAuthParams();

    expect(params).toHaveProperty('app_id');
    expect(params).toHaveProperty('timestamp');
    expect(params).toHaveProperty('sign');
  });

  test('app_id matches the configured appId', () => {
    const params = shopeefoodAuth.getAuthParams();
    expect(params.app_id).toBe('test_app_id');
  });

  test('timestamp is a reasonable Unix timestamp (within 5 seconds of now)', () => {
    const before = Math.floor(Date.now() / 1000);
    const params = shopeefoodAuth.getAuthParams();
    const after = Math.floor(Date.now() / 1000);

    expect(params.timestamp).toBeGreaterThanOrEqual(before);
    expect(params.timestamp).toBeLessThanOrEqual(after + 1);
  });

  test('sign is a 64-character hex string (SHA-256 output)', () => {
    const params = shopeefoodAuth.getAuthParams();
    expect(typeof params.sign).toBe('string');
    expect(params.sign).toMatch(/^[0-9a-f]{64}$/);
  });

  test('sign is reproducible given the same inputs', () => {
    // Two calls within the same second should produce the same sign when
    // the timestamp is the same. We verify the sign algorithm is deterministic
    // by computing it directly.
    const crypto = require('crypto');
    const params = shopeefoodAuth.getAuthParams();

    const expectedSign = crypto
      .createHmac('sha256', 'test_app_secret')
      .update(`${params.app_id}|${params.timestamp}`)
      .digest('hex');

    expect(params.sign).toBe(expectedSign);
  });
});

describe('ShopeeFoodAuth.getAuthHeader() — with credentials configured', () => {
  test('returns a string starting with "ShopeefoodHmac"', () => {
    const header = shopeefoodAuth.getAuthHeader();
    expect(header).toMatch(/^ShopeefoodHmac /);
  });

  test('contains app_id field', () => {
    const header = shopeefoodAuth.getAuthHeader();
    expect(header).toMatch(/app_id=test_app_id/);
  });

  test('contains timestamp field', () => {
    const header = shopeefoodAuth.getAuthHeader();
    expect(header).toMatch(/timestamp=\d+/);
  });

  test('contains sign field with a 64-char hex value', () => {
    const header = shopeefoodAuth.getAuthHeader();
    expect(header).toMatch(/sign=[0-9a-f]{64}/);
  });

  test('header format is "ShopeefoodHmac app_id=...,timestamp=...,sign=..."', () => {
    const header = shopeefoodAuth.getAuthHeader();
    expect(header).toMatch(
      /^ShopeefoodHmac app_id=.+,timestamp=\d+,sign=[0-9a-f]{64}$/,
    );
  });
});

describe('ShopeeFoodAuth.getAuthParams() — without credentials (mock mode)', () => {
  let authWithoutCreds;

  beforeAll(() => {
    // Create a fresh ShopeeFoodAuth instance that reads from a config
    // with empty credentials (simulates unconfigured environment).
    // We do this by temporarily overriding the module internals.
    jest.resetModules();

    jest.mock('../src/config', () => ({
      shopeefood: {
        appId: '',
        appSecret: '',
        apiBaseUrl: 'https://partner.food.shopee.vn',
      },
    }));

    jest.mock('../src/utils/logger', () => ({
      warn: jest.fn(),
      debug: jest.fn(),
      info: jest.fn(),
      error: jest.fn(),
    }));

    authWithoutCreds = require('../src/connectors/shopeefood/shopeefood-auth');
  });

  afterAll(() => {
    jest.resetModules();
  });

  test('returns mock app_id when credentials are not configured', () => {
    const params = authWithoutCreds.getAuthParams();
    expect(params.app_id).toBe('mock_app_id');
  });

  test('returns mock_sign when credentials are not configured', () => {
    const params = authWithoutCreds.getAuthParams();
    expect(params.sign).toBe('mock_sign');
  });

  test('still returns a timestamp even in mock mode', () => {
    const params = authWithoutCreds.getAuthParams();
    expect(typeof params.timestamp).toBe('number');
    expect(params.timestamp).toBeGreaterThan(0);
  });

  test('getAuthHeader() starts with "ShopeefoodHmac" in mock mode', () => {
    const header = authWithoutCreds.getAuthHeader();
    expect(header).toMatch(/^ShopeefoodHmac /);
  });

  test('getAuthHeader() contains mock_app_id in mock mode', () => {
    const header = authWithoutCreds.getAuthHeader();
    expect(header).toContain('app_id=mock_app_id');
  });

  test('getAuthHeader() contains mock_sign in mock mode', () => {
    const header = authWithoutCreds.getAuthHeader();
    expect(header).toContain('sign=mock_sign');
  });
});

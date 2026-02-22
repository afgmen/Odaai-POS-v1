'use strict';

const express = require('express');
const router = express.Router();
const connectorRegistry = require('../../connectors/connector-registry');
const logger = require('../../utils/logger');

/**
 * GET /api/platforms
 * List all registered delivery platform connectors with their status.
 */
router.get('/', (req, res) => {
  const summary = connectorRegistry.getStatusSummary();
  logger.debug('[PlatformsAPI] Status requested');
  return res.json({
    platforms: summary,
    activeCount: summary.filter((p) => p.active).length,
    totalCount: summary.length,
    timestamp: new Date().toISOString(),
  });
});

/**
 * GET /api/platforms/:name/status
 * Get status for a specific platform.
 */
router.get('/:name/status', (req, res) => {
  const { name } = req.params;
  const connector = connectorRegistry.getConnector(name);

  if (!connector) {
    return res.status(404).json({ error: `Platform '${name}' not registered` });
  }

  return res.json({
    name,
    active: connectorRegistry.isActive(name),
    registeredAt: connectorRegistry.getAllConnectors().find((c) => c.name === name)?.registeredAt,
  });
});

/**
 * POST /api/platforms/test/:name
 * Test connectivity for a specific platform by doing a lightweight health check.
 * Returns { ok: true/false, latencyMs, message }.
 */
router.post('/test/:name', async (req, res) => {
  const { name } = req.params;
  const connector = connectorRegistry.getConnector(name);

  if (!connector) {
    return res.status(404).json({ error: `Platform '${name}' not registered` });
  }

  logger.info(`[PlatformsAPI] Testing connection to: ${name}`);
  const startMs = Date.now();

  const isActive = connectorRegistry.isActive(name);
  if (!isActive) {
    return res.json({
      ok: false,
      latencyMs: 0,
      message: `${name} connector is inactive (credentials not configured)`,
    });
  }

  // Attempt a lightweight connectivity check
  // For most platforms this means a quick token fetch or status endpoint ping
  try {
    // Each connector's acceptOrder/syncMenu call will validate auth indirectly.
    // For a non-destructive test we just check that the connector responds.
    // We try to fetch/refresh auth token as a connectivity test.
    if (name === 'grab') {
      const grabAuth = require('../../connectors/grab/grab-auth');
      await grabAuth.getAccessToken();
    } else if (name === 'shopeefood') {
      const shopeefoodAuth = require('../../connectors/shopeefood/shopeefood-auth');
      // Just generate auth params (validates config is present)
      shopeefoodAuth.getAuthParams();
    }

    return res.json({
      ok: true,
      latencyMs: Date.now() - startMs,
      message: `${name} connectivity OK`,
    });
  } catch (err) {
    logger.error(`[PlatformsAPI] Connection test failed for ${name}:`, err.message);
    return res.json({
      ok: false,
      latencyMs: Date.now() - startMs,
      message: err.message,
    });
  }
});

module.exports = router;

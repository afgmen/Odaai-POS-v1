'use strict';

const express = require('express');
const router = express.Router();

const grabConnector = require('../../connectors/grab/grab-connector');
const shopeeFoodConnector = require('../../connectors/shopeefood/shopeefood-connector');
const connectorRegistry = require('../../connectors/connector-registry');
const logger = require('../../utils/logger');

/**
 * POST /api/menu/sync
 *
 * Body: { platform?: 'grab' | 'all', menuData: object }
 *
 * Expected menuData shape:
 * {
 *   categories: [{
 *     id: string,
 *     name: string,
 *     items: [{
 *       id: string,
 *       name: string,
 *       description: string,
 *       price: number,        // VND
 *       available: boolean,
 *       imageUrl: string | null,
 *     }]
 *   }]
 * }
 *
 * Pushes the POS menu to all requested delivery platforms.
 * Resilient: if one platform fails the others still sync.
 * Returns per-platform results so the POS can display partial failures.
 */
router.post('/sync', async (req, res) => {
  const { platform = 'all', menuData } = req.body || {};

  if (!menuData) {
    return res.status(400).json({ error: 'menuData is required' });
  }

  if (!menuData.categories || !Array.isArray(menuData.categories)) {
    return res.status(400).json({ error: 'menuData.categories must be an array' });
  }

  const itemCount = menuData.categories.reduce(
    (sum, cat) => sum + (cat.items?.length ?? 0),
    0,
  );
  logger.info(
    `[MenuAPI] Sync requested — platform=${platform}, categories=${menuData.categories.length}, items=${itemCount}`,
  );

  // ── Collect platforms to sync ──
  /** @type {Array<{ key: string, syncFn: (menuData: object) => Promise<unknown> }>} */
  const platforms = [];
  if (platform === 'all') {
    // Dynamically build from registry — adding a new connector is plug-and-play
    connectorRegistry.getActiveConnectors().forEach(({ name, connector }) => {
      platforms.push({ key: name, syncFn: (d) => connector.syncMenu(d) });
    });
  } else if (platform === 'grab') {
    platforms.push({ key: 'grab', syncFn: (d) => grabConnector.syncMenu(d) });
  } else if (platform === 'shopeefood') {
    platforms.push({ key: 'shopeefood', syncFn: (d) => shopeeFoodConnector.syncMenu(d) });
  }

  if (platforms.length === 0) {
    if (platform === 'all') {
      // No active connectors — return early with informative response
      logger.warn('[MenuAPI] menu sync requested but no active connectors are configured');
      return res.status(200).json({
        success: false,
        allSucceeded: false,
        platforms: {},
        message: 'No active connectors configured. Set credentials in .env to enable sync.',
      });
    }
    return res.status(400).json({ error: `Unknown platform: ${platform}` });
  }

  // ── Fire all syncs, capture individual successes/failures ──
  const results = {};
  let anySuccess = false;

  await Promise.all(
    platforms.map(async ({ key, syncFn }) => {
      const startMs = Date.now();
      try {
        const data = await syncFn(menuData);
        results[key] = {
          success: true,
          durationMs: Date.now() - startMs,
          data,
        };
        anySuccess = true;
        logger.info(`[MenuAPI] ${key} sync succeeded (${Date.now() - startMs}ms)`);
      } catch (err) {
        results[key] = {
          success: false,
          durationMs: Date.now() - startMs,
          error: err.response?.data?.message ?? err.message,
        };
        logger.error(`[MenuAPI] ${key} sync failed: ${err.message}`);
      }
    }),
  );

  // HTTP 207 Multi-Status when some succeeded, some failed
  const allSucceeded = Object.values(results).every((r) => r.success);
  const allFailed = Object.values(results).every((r) => !r.success);

  const httpStatus = allSucceeded ? 200 : allFailed ? 502 : 207;

  return res.status(httpStatus).json({
    success: anySuccess,
    allSucceeded,
    platforms: results,
  });
});

router.get('/platforms/status', (req, res) => {
  const connectorRegistry = require('../../connectors/connector-registry');
  return res.json({
    platforms: connectorRegistry.getStatusSummary(),
    timestamp: new Date().toISOString(),
  });
});

module.exports = router;

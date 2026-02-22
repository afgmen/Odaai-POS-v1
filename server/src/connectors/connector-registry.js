'use strict';

const logger = require('../utils/logger');

/**
 * Central registry for delivery platform connectors.
 *
 * Provides a plug-and-play mechanism for adding future platforms:
 *   1. Create a new connector (extends BaseConnector)
 *   2. Register it here on startup (auto-registered from index.js)
 *   3. The connector is automatically included in menu broadcasts,
 *      status pushes, and the platform management API
 *
 * A connector can be 'active' or 'inactive':
 *   - active:   credentials are configured and the connector is ready
 *   - inactive: connector is registered but credentials are missing;
 *               it logs a warning and returns mock responses
 */
class ConnectorRegistry {
  constructor() {
    /** @type {Map<string, { connector: import('./base-connector'), active: boolean, registeredAt: Date }>} */
    this._connectors = new Map();
  }

  // ──────────────────────────────────────────────
  // Registration
  // ──────────────────────────────────────────────

  /**
   * Register a connector. If `active` is false (credentials missing),
   * the connector is still registered for status reporting but will not
   * be included in broadcastMenuUpdate or status pushes.
   *
   * @param {string} platformName  – e.g. 'grab', 'shopeefood'
   * @param {import('./base-connector')} connector  – connector instance
   * @param {boolean} active  – true if credentials are configured
   */
  register(platformName, connector, active = true) {
    this._connectors.set(platformName, {
      connector,
      active,
      registeredAt: new Date(),
    });

    if (active) {
      logger.info(`[ConnectorRegistry] ✓ Registered connector: ${platformName} (active)`);
    } else {
      logger.warn(
        `[ConnectorRegistry] ⚠ Registered connector: ${platformName} (inactive — credentials not configured)`,
      );
    }
  }

  // ──────────────────────────────────────────────
  // Lookup
  // ──────────────────────────────────────────────

  /**
   * Get a connector by platform name.
   * Returns null if not registered.
   *
   * @param {string} platformName
   * @returns {import('./base-connector') | null}
   */
  getConnector(platformName) {
    const entry = this._connectors.get(platformName);
    return entry ? entry.connector : null;
  }

  /**
   * Get all registered connectors (active and inactive).
   * @returns {Array<{ name: string, connector: import('./base-connector'), active: boolean, registeredAt: Date }>}
   */
  getAllConnectors() {
    return [...this._connectors.entries()].map(([name, entry]) => ({
      name,
      ...entry,
    }));
  }

  /**
   * Get only active connectors.
   * @returns {Array<{ name: string, connector: import('./base-connector'), active: boolean, registeredAt: Date }>}
   */
  getActiveConnectors() {
    return this.getAllConnectors().filter((entry) => entry.active);
  }

  /**
   * Check if a platform is registered and active.
   * @param {string} platformName
   * @returns {boolean}
   */
  isActive(platformName) {
    const entry = this._connectors.get(platformName);
    return entry ? entry.active : false;
  }

  // ──────────────────────────────────────────────
  // Broadcast operations
  // ──────────────────────────────────────────────

  /**
   * Broadcast a menu update to ALL active connectors.
   * Each platform sync is independent — failures don't affect others.
   *
   * @param {object} menuData
   * @returns {Promise<Array<{ platform: string, success: boolean, durationMs: number, data?: unknown, error?: string }>>}
   */
  async broadcastMenuUpdate(menuData) {
    const active = this.getActiveConnectors();

    if (active.length === 0) {
      logger.warn('[ConnectorRegistry] broadcastMenuUpdate: no active connectors');
      return [];
    }

    logger.info(
      `[ConnectorRegistry] Broadcasting menu update to ${active.length} platform(s): ` +
      active.map((e) => e.name).join(', '),
    );

    const results = await Promise.all(
      active.map(async ({ name, connector }) => {
        const startMs = Date.now();
        try {
          const data = await connector.syncMenu(menuData);
          logger.info(`[ConnectorRegistry] Menu sync OK: ${name} (${Date.now() - startMs}ms)`);
          return { platform: name, success: true, durationMs: Date.now() - startMs, data };
        } catch (err) {
          logger.error(`[ConnectorRegistry] Menu sync FAILED: ${name} — ${err.message}`);
          return {
            platform: name,
            success: false,
            durationMs: Date.now() - startMs,
            error: err.response?.data?.message ?? err.message,
          };
        }
      }),
    );

    return results;
  }

  // ──────────────────────────────────────────────
  // Status summary (for platform management API)
  // ──────────────────────────────────────────────

  /**
   * Return a status summary of all registered connectors.
   * Used by the Flutter platform management settings screen.
   *
   * @returns {Array<{ name: string, active: boolean, registeredAt: string }>}
   */
  getStatusSummary() {
    return this.getAllConnectors().map(({ name, active, registeredAt }) => ({
      name,
      active,
      registeredAt: registeredAt.toISOString(),
    }));
  }
}

// Export a singleton registry
module.exports = new ConnectorRegistry();

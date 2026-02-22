'use strict';

const axios = require('axios');
const config = require('../../config');
const logger = require('../../utils/logger');

/**
 * GrabFood OAuth2 token manager.
 *
 * Uses client_credentials grant with scope `food.partner_api`.
 * Stores the token in memory and auto-refreshes 60 s before expiry.
 */
class GrabAuth {
  constructor() {
    this._accessToken = null;
    this._expiresAt = null; // Date
    this._refreshTimer = null;
  }

  /**
   * Return a valid access token, fetching a new one if needed.
   * @returns {Promise<string>}
   */
  async getAccessToken() {
    if (this._isTokenValid()) {
      return this._accessToken;
    }
    await this._fetchToken();
    return this._accessToken;
  }

  /**
   * Force-refresh the token (e.g. on 401 response).
   * @returns {Promise<string>}
   */
  async refreshToken() {
    this._clearRefreshTimer();
    await this._fetchToken();
    return this._accessToken;
  }

  // ──────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────

  _isTokenValid() {
    if (!this._accessToken || !this._expiresAt) return false;
    // Consider expired 60 s before actual expiry
    return new Date() < new Date(this._expiresAt.getTime() - 60_000);
  }

  async _fetchToken() {
    logger.info('[GrabAuth] Fetching new OAuth2 access token...');

    const params = new URLSearchParams({
      grant_type: 'client_credentials',
      client_id: config.grab.clientId,
      client_secret: config.grab.clientSecret,
      scope: config.grab.scope,
    });

    const response = await axios.post(
      `${config.grab.authBaseUrl}/grabid/v1/oauth2/token`,
      params.toString(),
      { headers: { 'Content-Type': 'application/x-www-form-urlencoded' } },
    );

    const { access_token, expires_in } = response.data;

    this._accessToken = access_token;
    this._expiresAt = new Date(Date.now() + expires_in * 1000);

    logger.info(`[GrabAuth] Token obtained, expires at ${this._expiresAt.toISOString()}`);

    // Schedule auto-refresh 60 s before expiry
    const refreshDelay = Math.max(0, expires_in * 1000 - 60_000);
    this._scheduleRefresh(refreshDelay);
  }

  _scheduleRefresh(delayMs) {
    this._clearRefreshTimer();
    this._refreshTimer = setTimeout(async () => {
      try {
        await this._fetchToken();
      } catch (err) {
        logger.error('[GrabAuth] Auto-refresh failed:', err.message);
      }
    }, delayMs);
  }

  _clearRefreshTimer() {
    if (this._refreshTimer) {
      clearTimeout(this._refreshTimer);
      this._refreshTimer = null;
    }
  }
}

// Export a singleton instance
module.exports = new GrabAuth();

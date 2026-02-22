'use strict';

/**
 * Abstract base class for all delivery platform connectors.
 *
 * Each connector must implement:
 *   - acceptOrder(platformOrderId)
 *   - rejectOrder(platformOrderId, reason)
 *   - updateOrderStatus(platformOrderId, status)
 *   - syncMenu(menuData)
 */
class BaseConnector {
  constructor(name) {
    if (new.target === BaseConnector) {
      throw new Error('BaseConnector is abstract and cannot be instantiated directly.');
    }
    this.name = name;
  }

  /**
   * Accept an incoming order on the platform.
   * @param {string} platformOrderId
   * @returns {Promise<void>}
   */
  async acceptOrder(platformOrderId) {
    throw new Error(`${this.name}.acceptOrder() not implemented`);
  }

  /**
   * Reject an incoming order on the platform.
   * @param {string} platformOrderId
   * @param {string} reason
   * @returns {Promise<void>}
   */
  async rejectOrder(platformOrderId, reason) {
    throw new Error(`${this.name}.rejectOrder() not implemented`);
  }

  /**
   * Push a status update to the platform.
   * @param {string} platformOrderId
   * @param {string} status  – one of DeliveryStatus values
   * @returns {Promise<void>}
   */
  async updateOrderStatus(platformOrderId, status) {
    throw new Error(`${this.name}.updateOrderStatus() not implemented`);
  }

  /**
   * Sync menu / pricing to the platform.
   * @param {object} menuData
   * @returns {Promise<void>}
   */
  async syncMenu(menuData) {
    throw new Error(`${this.name}.syncMenu() not implemented`);
  }
}

module.exports = BaseConnector;

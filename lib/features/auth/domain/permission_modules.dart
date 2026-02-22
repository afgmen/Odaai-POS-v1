// ignore_for_file: constant_identifier_names

/// Permission naming convention: module.action
/// All available permissions in the RBAC system
class PermissionModules {
  // ========================================
  // POS Module
  // ========================================
  static const String POS_OPEN = 'pos.open';
  static const String POS_REFUND = 'pos.refund';
  static const String POS_DISCOUNT = 'pos.discount';
  static const String POS_PRICE_OVERRIDE = 'pos.price.override';
  static const String POS_CASH_DRAWER_OPEN = 'pos.cash.drawer.open';

  // ========================================
  // Orders Module
  // ========================================
  static const String ORDER_CREATE = 'order.create';
  static const String ORDER_CANCEL = 'order.cancel';
  static const String ORDER_VIEW = 'order.view';

  // ========================================
  // Inventory Module
  // ========================================
  static const String INVENTORY_VIEW = 'inventory.view';
  static const String INVENTORY_EDIT = 'inventory.edit';
  static const String INVENTORY_ADJUST = 'inventory.adjust';
  static const String INVENTORY_WRITEOFF = 'inventory.writeoff';

  // ========================================
  // Revenue Module (Sensitive)
  // ========================================
  static const String REVENUE_DASHBOARD_VIEW = 'revenue.dashboard.view';
  static const String REVENUE_DAILY_VIEW = 'revenue.daily.view';
  static const String REVENUE_WEEKLY_VIEW = 'revenue.weekly.view';
  static const String REVENUE_MONTHLY_VIEW = 'revenue.monthly.view';
  static const String REVENUE_MULTISTORE_VIEW = 'revenue.multistore.view';
  static const String REVENUE_EXPORT = 'revenue.export';
  static const String REVENUE_PNL_VIEW = 'revenue.pnl.view';

  // ========================================
  // Staff Module
  // ========================================
  static const String STAFF_VIEW = 'staff.view';
  static const String STAFF_MANAGE = 'staff.manage';
  static const String STAFF_ROLE_ASSIGN = 'staff.role.assign';

  // ========================================
  // Settings Module
  // ========================================
  static const String SETTINGS_STORE_EDIT = 'settings.store.edit';
  static const String SETTINGS_TAX_EDIT = 'settings.tax.edit';
  static const String SETTINGS_PAYMENT_EDIT = 'settings.payment.edit';
  static const String SETTINGS_INTEGRATION_EDIT = 'settings.integration.edit';

  // ========================================
  // Module Names
  // ========================================
  static const String MODULE_POS = 'pos';
  static const String MODULE_ORDER = 'order';
  static const String MODULE_INVENTORY = 'inventory';
  static const String MODULE_REVENUE = 'revenue';
  static const String MODULE_STAFF = 'staff';
  static const String MODULE_SETTINGS = 'settings';

  /// Get module name from permission
  static String getModule(String permission) {
    final parts = permission.split('.');
    return parts.isNotEmpty ? parts[0] : 'unknown';
  }

  /// Get all permissions for a module
  static List<String> getPermissionsByModule(String module) {
    const allPermissions = [
      POS_OPEN, POS_REFUND, POS_DISCOUNT, POS_PRICE_OVERRIDE, POS_CASH_DRAWER_OPEN,
      ORDER_CREATE, ORDER_CANCEL, ORDER_VIEW,
      INVENTORY_VIEW, INVENTORY_EDIT, INVENTORY_ADJUST, INVENTORY_WRITEOFF,
      REVENUE_DASHBOARD_VIEW, REVENUE_DAILY_VIEW, REVENUE_WEEKLY_VIEW,
      REVENUE_MONTHLY_VIEW, REVENUE_MULTISTORE_VIEW, REVENUE_EXPORT, REVENUE_PNL_VIEW,
      STAFF_VIEW, STAFF_MANAGE, STAFF_ROLE_ASSIGN,
      SETTINGS_STORE_EDIT, SETTINGS_TAX_EDIT, SETTINGS_PAYMENT_EDIT, SETTINGS_INTEGRATION_EDIT,
    ];

    return allPermissions.where((p) => p.startsWith('$module.')).toList();
  }

  /// Get all module names
  static List<String> getAllModules() {
    return [
      MODULE_POS,
      MODULE_ORDER,
      MODULE_INVENTORY,
      MODULE_REVENUE,
      MODULE_STAFF,
      MODULE_SETTINGS,
    ];
  }

  /// Get module display name
  static String getModuleDisplayName(String module) {
    switch (module) {
      case MODULE_POS:
        return 'POS';
      case MODULE_ORDER:
        return 'Orders';
      case MODULE_INVENTORY:
        return 'Inventory';
      case MODULE_REVENUE:
        return 'Revenue';
      case MODULE_STAFF:
        return 'Staff';
      case MODULE_SETTINGS:
        return 'Settings';
      default:
        return module.toUpperCase();
    }
  }

  /// Get module display name (Korean) — kept for backward compatibility
  static String getModuleDisplayNameKo(String module) {
    return getModuleDisplayName(module);
  }

  /// Get permission display name
  static String getPermissionDisplayName(String permission) {
    final displayNames = {
      // POS
      POS_OPEN: 'Open POS',
      POS_REFUND: 'Process Refunds',
      POS_DISCOUNT: 'Apply Discounts',
      POS_PRICE_OVERRIDE: 'Override Prices',
      POS_CASH_DRAWER_OPEN: 'Open Cash Drawer',

      // Orders
      ORDER_CREATE: 'Create Orders',
      ORDER_CANCEL: 'Cancel Orders',
      ORDER_VIEW: 'View Order History',

      // Inventory
      INVENTORY_VIEW: 'View Inventory',
      INVENTORY_EDIT: 'Edit Products',
      INVENTORY_ADJUST: 'Adjust Stock',
      INVENTORY_WRITEOFF: 'Write Off Items',

      // Revenue (Sensitive)
      REVENUE_DASHBOARD_VIEW: 'Dashboard View',
      REVENUE_DAILY_VIEW: 'Daily Revenue',
      REVENUE_WEEKLY_VIEW: 'Weekly Revenue',
      REVENUE_MONTHLY_VIEW: 'Monthly Revenue',
      REVENUE_MULTISTORE_VIEW: 'Multi-store Revenue',
      REVENUE_EXPORT: 'Export Reports',
      REVENUE_PNL_VIEW: 'P&L Statement',

      // Staff
      STAFF_VIEW: 'View Staff List',
      STAFF_MANAGE: 'Manage Staff',
      STAFF_ROLE_ASSIGN: 'Assign Roles',

      // Settings
      SETTINGS_STORE_EDIT: 'Store Settings',
      SETTINGS_TAX_EDIT: 'Tax Settings',
      SETTINGS_PAYMENT_EDIT: 'Payment Settings',
      SETTINGS_INTEGRATION_EDIT: 'Integration Settings',
    };

    return displayNames[permission] ?? permission;
  }

  /// Get permission display name (Korean) — now returns English for consistency
  static String getPermissionDisplayNameKo(String permission) {
    return getPermissionDisplayName(permission);
  }

  /// Check if permission is sensitive (involves financial data)
  static bool isSensitive(String permission) {
    return permission.startsWith('revenue.') ||
           permission.startsWith('settings.');
  }

  /// Get all permissions as a list
  static List<String> getAllPermissions() {
    return [
      // POS
      POS_OPEN, POS_REFUND, POS_DISCOUNT, POS_PRICE_OVERRIDE, POS_CASH_DRAWER_OPEN,
      // Orders
      ORDER_CREATE, ORDER_CANCEL, ORDER_VIEW,
      // Inventory
      INVENTORY_VIEW, INVENTORY_EDIT, INVENTORY_ADJUST, INVENTORY_WRITEOFF,
      // Revenue
      REVENUE_DASHBOARD_VIEW, REVENUE_DAILY_VIEW, REVENUE_WEEKLY_VIEW,
      REVENUE_MONTHLY_VIEW, REVENUE_MULTISTORE_VIEW, REVENUE_EXPORT, REVENUE_PNL_VIEW,
      // Staff
      STAFF_VIEW, STAFF_MANAGE, STAFF_ROLE_ASSIGN,
      // Settings
      SETTINGS_STORE_EDIT, SETTINGS_TAX_EDIT, SETTINGS_PAYMENT_EDIT, SETTINGS_INTEGRATION_EDIT,
    ];
  }
}

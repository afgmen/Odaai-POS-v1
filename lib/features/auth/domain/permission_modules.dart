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

  /// Get module display name (Korean)
  static String getModuleDisplayNameKo(String module) {
    switch (module) {
      case MODULE_POS:
        return 'POS';
      case MODULE_ORDER:
        return '주문';
      case MODULE_INVENTORY:
        return '재고';
      case MODULE_REVENUE:
        return '매출';
      case MODULE_STAFF:
        return '직원';
      case MODULE_SETTINGS:
        return '설정';
      default:
        return module.toUpperCase();
    }
  }

  /// Get permission display name
  static String getPermissionDisplayName(String permission) {
    // Convert "revenue.daily.view" → "View Daily Revenue"
    final parts = permission.split('.');
    if (parts.length < 2) return permission;

    final action = parts.sublist(1).map((p) => _capitalize(p)).join(' ');
    return action;
  }

  /// Get permission display name (Korean)
  static String getPermissionDisplayNameKo(String permission) {
    final displayNames = {
      // POS
      POS_OPEN: 'POS 열기',
      POS_REFUND: '환불 처리',
      POS_DISCOUNT: '할인 적용',
      POS_PRICE_OVERRIDE: '가격 변경',
      POS_CASH_DRAWER_OPEN: '현금함 열기',

      // Orders
      ORDER_CREATE: '주문 생성',
      ORDER_CANCEL: '주문 취소',
      ORDER_VIEW: '주문 내역 조회',

      // Inventory
      INVENTORY_VIEW: '재고 조회',
      INVENTORY_EDIT: '상품 정보 편집',
      INVENTORY_ADJUST: '재고 조정',
      INVENTORY_WRITEOFF: '상품 폐기',

      // Revenue (Sensitive)
      REVENUE_DASHBOARD_VIEW: '매출 대시보드 조회',
      REVENUE_DAILY_VIEW: '일일 매출 조회',
      REVENUE_WEEKLY_VIEW: '주간 매출 조회',
      REVENUE_MONTHLY_VIEW: '월간 매출 조회',
      REVENUE_MULTISTORE_VIEW: '다중 매장 매출 조회',
      REVENUE_EXPORT: '매출 리포트 내보내기',
      REVENUE_PNL_VIEW: '손익계산서 조회',

      // Staff
      STAFF_VIEW: '직원 목록 조회',
      STAFF_MANAGE: '직원 관리',
      STAFF_ROLE_ASSIGN: '직원 역할 할당',

      // Settings
      SETTINGS_STORE_EDIT: '매장 설정 편집',
      SETTINGS_TAX_EDIT: '세금 설정 편집',
      SETTINGS_PAYMENT_EDIT: '결제 설정 편집',
      SETTINGS_INTEGRATION_EDIT: '연동 설정 편집',
    };

    return displayNames[permission] ?? permission;
  }

  /// Check if permission is sensitive (involves financial data)
  static bool isSensitive(String permission) {
    return permission.startsWith('revenue.') ||
           permission.startsWith('settings.');
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
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

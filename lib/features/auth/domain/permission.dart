// ignore_for_file: constant_identifier_names

/// Legacy permission enum (used for manager override checks)
enum Permission {
  // Sales
  SALES_CREATE,
  SALES_VIEW_OWN,
  SALES_VIEW_ALL,

  // Refunds
  REFUND_SMALL,      // Refunds up to 50,000
  REFUND_UNLIMITED,

  // Discounts
  DISCOUNT_APPLY,

  // Inventory
  INVENTORY_VIEW,
  INVENTORY_MODIFY,

  // Staff management
  EMPLOYEE_VIEW,
  EMPLOYEE_MANAGE,

  // Reports
  REPORT_VIEW,

  // Table management
  TABLE_MANAGE,

  // Kitchen display
  KDS_ACCESS,
}

/// Permission extension - descriptions and utilities
extension PermissionExtension on Permission {
  /// Permission description
  String get description {
    switch (this) {
      case Permission.SALES_CREATE:
        return 'Create sales';
      case Permission.SALES_VIEW_OWN:
        return 'View own sales';
      case Permission.SALES_VIEW_ALL:
        return 'View all sales';
      case Permission.REFUND_SMALL:
        return 'Small refunds (≤50,000)';
      case Permission.REFUND_UNLIMITED:
        return 'Unlimited refunds';
      case Permission.DISCOUNT_APPLY:
        return 'Apply discounts';
      case Permission.INVENTORY_VIEW:
        return 'View inventory';
      case Permission.INVENTORY_MODIFY:
        return 'Modify inventory';
      case Permission.EMPLOYEE_VIEW:
        return 'View employees';
      case Permission.EMPLOYEE_MANAGE:
        return 'Manage employees';
      case Permission.REPORT_VIEW:
        return 'View reports';
      case Permission.TABLE_MANAGE:
        return 'Manage tables';
      case Permission.KDS_ACCESS:
        return 'Access kitchen display';
    }
  }

  /// Permission category
  String get category {
    if ([Permission.SALES_CREATE, Permission.SALES_VIEW_OWN, Permission.SALES_VIEW_ALL]
        .contains(this)) {
      return 'Sales';
    } else if ([Permission.REFUND_SMALL, Permission.REFUND_UNLIMITED].contains(this)) {
      return 'Refunds';
    } else if ([Permission.DISCOUNT_APPLY].contains(this)) {
      return 'Discounts';
    } else if ([Permission.INVENTORY_VIEW, Permission.INVENTORY_MODIFY].contains(this)) {
      return 'Inventory';
    } else if ([Permission.EMPLOYEE_VIEW, Permission.EMPLOYEE_MANAGE].contains(this)) {
      return 'Staff';
    } else if ([Permission.REPORT_VIEW].contains(this)) {
      return 'Reports';
    } else if ([Permission.TABLE_MANAGE].contains(this)) {
      return 'Tables';
    } else if ([Permission.KDS_ACCESS].contains(this)) {
      return 'Kitchen';
    }
    return 'Other';
  }
}

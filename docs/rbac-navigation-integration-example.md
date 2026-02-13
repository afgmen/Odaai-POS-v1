# RBAC Navigation Integration Example

> **File**: `lib/features/app_root_screen.dart`
> **Status**: Example Implementation (Not Applied Yet)
> **Date**: 2026-02-12

---

## Current Implementation

The app uses `AdaptiveScaffold` with 14 navigation items. Currently, all items are visible to all users regardless of role.

---

## Integration Approach

Since the navigation uses a static list of screens and dynamic navigation items, we need to:

1. **Filter navigation items** based on user permissions
2. **Map filtered indices** to the correct screen in the static list
3. **Use PermissionGuard** to conditionally show/hide navigation items

---

## Implementation Strategy

### Option 1: Filter Navigation Items (Recommended)

This approach filters the navigation items list based on permissions and maintains a mapping to the original screen indices.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive/adaptive_scaffold.dart';
import '../core/widgets/permission_gate_widget.dart';
import '../l10n/app_localizations.dart';
import 'auth/domain/permission_modules.dart';
import 'auth/providers/rbac_providers.dart';
// ... other imports

class _AppRootScreenState extends ConsumerState<AppRootScreen> {
  int _currentIndex = 0;

  static const _screens = <Widget>[
    PosMainScreen(),           // 0
    ProductManagementScreen(), // 1
    SalesHistoryScreen(),      // 2 - REVENUE_DAILY_VIEW
    DashboardScreen(),         // 3 - REVENUE_DASHBOARD_VIEW
    CustomerManagementScreen(),// 4
    TableManagementScreen(),   // 5
    RefundScreen(),            // 6
    CashDrawerScreen(),        // 7
    DailyClosingScreen(),      // 8 - REVENUE_DAILY_VIEW
    LowStockScreen(),          // 9
    EmployeeManagementScreen(),// 10 - STAFF_MANAGE
    PromotionManagementScreen(),// 11
    ReportsScreen(),           // 12 - REVENUE_DAILY_VIEW
    SettingsScreen(),          // 13 - OWNER ONLY
  ];

  /// Build filtered navigation items based on permissions
  List<_NavItemWithIndex> _buildFilteredDestinations(
    AppLocalizations? l10n,
    WidgetRef ref,
  ) {
    final allItems = [
      _NavItemWithIndex(
        screenIndex: 0,
        item: NavigationItem(
          icon: Icons.point_of_sale_outlined,
          selectedIcon: Icons.point_of_sale,
          label: l10n?.navPos ?? 'POS',
        ),
        permission: null, // Always visible
      ),
      _NavItemWithIndex(
        screenIndex: 1,
        item: NavigationItem(
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
          label: l10n?.navProducts ?? 'Products',
        ),
        permission: null, // Always visible
      ),
      _NavItemWithIndex(
        screenIndex: 2,
        item: NavigationItem(
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long,
          label: l10n?.navSales ?? 'Sales',
        ),
        permission: PermissionModules.REVENUE_DAILY_VIEW,
      ),
      _NavItemWithIndex(
        screenIndex: 3,
        item: NavigationItem(
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
          label: l10n?.navDashboard ?? 'Dashboard',
        ),
        permission: PermissionModules.REVENUE_DASHBOARD_VIEW,
      ),
      _NavItemWithIndex(
        screenIndex: 4,
        item: NavigationItem(
          icon: Icons.people_alt_outlined,
          selectedIcon: Icons.people_alt,
          label: l10n?.navCustomers ?? 'Customers',
        ),
        permission: null, // Always visible
      ),
      _NavItemWithIndex(
        screenIndex: 5,
        item: NavigationItem(
          icon: Icons.table_restaurant_outlined,
          selectedIcon: Icons.table_restaurant,
          label: l10n?.navTables ?? 'Tables',
        ),
        permission: null, // Always visible
      ),
      _NavItemWithIndex(
        screenIndex: 6,
        item: NavigationItem(
          icon: Icons.undo_outlined,
          selectedIcon: Icons.undo,
          label: l10n?.navRefunds ?? 'Refunds',
        ),
        permission: null, // Always visible
      ),
      _NavItemWithIndex(
        screenIndex: 7,
        item: NavigationItem(
          icon: Icons.account_balance_wallet_outlined,
          selectedIcon: Icons.account_balance_wallet,
          label: l10n?.navCashDrawer ?? 'Cash',
        ),
        permission: null, // Always visible
      ),
      _NavItemWithIndex(
        screenIndex: 8,
        item: NavigationItem(
          icon: Icons.event_note_outlined,
          selectedIcon: Icons.event_note,
          label: l10n?.navDailyClosing ?? 'Daily Closing',
        ),
        permission: PermissionModules.REVENUE_DAILY_VIEW,
      ),
      _NavItemWithIndex(
        screenIndex: 9,
        item: NavigationItem(
          icon: Icons.warning_amber_outlined,
          selectedIcon: Icons.warning_amber_rounded,
          label: l10n?.navInventory ?? 'Low Stock',
        ),
        permission: null, // Always visible
      ),
      _NavItemWithIndex(
        screenIndex: 10,
        item: NavigationItem(
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          label: l10n?.navEmployees ?? 'Employees',
        ),
        permission: PermissionModules.STAFF_MANAGE,
      ),
      _NavItemWithIndex(
        screenIndex: 11,
        item: NavigationItem(
          icon: Icons.local_offer_outlined,
          selectedIcon: Icons.local_offer,
          label: l10n?.navPromotions ?? 'Promotions',
        ),
        permission: null, // Always visible
      ),
      _NavItemWithIndex(
        screenIndex: 12,
        item: NavigationItem(
          icon: Icons.analytics_outlined,
          selectedIcon: Icons.analytics,
          label: l10n?.navReports ?? 'Reports',
        ),
        permission: PermissionModules.REVENUE_DAILY_VIEW,
      ),
      _NavItemWithIndex(
        screenIndex: 13,
        item: NavigationItem(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: l10n?.settings ?? 'Settings',
        ),
        permission: null, // OWNER check done below
        ownerOnly: true,
      ),
    ];

    // Check permissions for each item
    final isOwner = ref.watch(isOwnerProvider).value ?? false;
    final filtered = <_NavItemWithIndex>[];

    for (final navItem in allItems) {
      // Owner-only check
      if (navItem.ownerOnly && !isOwner) {
        continue;
      }

      // Permission check
      if (navItem.permission != null) {
        final hasPermission = ref.watch(
          hasPermissionProvider((
            permission: navItem.permission!,
            storeId: null,
          )),
        ).value ?? false;

        if (!hasPermission) {
          continue;
        }
      }

      filtered.add(navItem);
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filteredItems = _buildFilteredDestinations(l10n, ref);

    return AdaptiveScaffold(
      currentIndex: _currentIndex,
      onDestinationSelected: (index) {
        // Map filtered index to original screen index
        if (index >= 0 && index < filteredItems.length) {
          setState(() => _currentIndex = index);
        }
      },
      destinations: filteredItems.map((e) => e.item).toList(),
      trailing: const SyncStatusIndicator(),
      bodyBuilder: (context, index) {
        // Get the actual screen index from the filtered item
        final screenIndex = (index >= 0 && index < filteredItems.length)
            ? filteredItems[index].screenIndex
            : 0;

        return _screens[screenIndex];
      },
    );
  }
}

/// Helper class to associate navigation items with their screen indices
class _NavItemWithIndex {
  final int screenIndex;
  final NavigationItem item;
  final String? permission;
  final bool ownerOnly;

  _NavItemWithIndex({
    required this.screenIndex,
    required this.item,
    this.permission,
    this.ownerOnly = false,
  });
}
```

---

## Permission Mapping

| Navigation Item | Screen Index | Permission Required | Owner Only |
|-----------------|--------------|---------------------|------------|
| POS | 0 | None | No |
| Products | 1 | None | No |
| **Sales** | 2 | `REVENUE_DAILY_VIEW` | No |
| **Dashboard** | 3 | `REVENUE_DASHBOARD_VIEW` | No |
| Customers | 4 | None | No |
| Tables | 5 | None | No |
| Refunds | 6 | None | No |
| Cash Drawer | 7 | None | No |
| **Daily Closing** | 8 | `REVENUE_DAILY_VIEW` | No |
| Low Stock | 9 | None | No |
| **Employees** | 10 | `STAFF_MANAGE` | No |
| Promotions | 11 | None | No |
| **Reports** | 12 | `REVENUE_DAILY_VIEW` | No |
| **Settings** | 13 | None | **Yes** |

---

## Expected Behavior by Role

### STAFF Role
**Visible Navigation Items**:
- POS
- Products
- Customers
- Tables
- Refunds
- Cash Drawer
- Low Stock
- Promotions

**Hidden Items**:
- Sales (no permission)
- Dashboard (no permission)
- Daily Closing (no permission)
- Employees (no permission)
- Reports (no permission)
- Settings (owner only)

---

### STORE_MANAGER Role
**Visible Navigation Items**:
- POS
- Products
- Sales ✅
- Dashboard ✅
- Customers
- Tables
- Refunds
- Cash Drawer
- Daily Closing ✅
- Low Stock
- Promotions
- Reports ✅

**Hidden Items**:
- Employees (no permission)
- Settings (owner only)

---

### AREA_MANAGER Role
**Visible Navigation Items**:
- All items except Settings

**Hidden Items**:
- Settings (owner only)

---

### OWNER Role
**Visible Navigation Items**:
- All items (full access)

---

## Testing Checklist

- [ ] STAFF role: Sees 8 navigation items (no revenue/management screens)
- [ ] STORE_MANAGER role: Sees 12 navigation items (no employee management)
- [ ] AREA_MANAGER role: Sees 13 navigation items (no settings)
- [ ] OWNER role: Sees all 14 navigation items
- [ ] Clicking each visible item navigates to the correct screen
- [ ] RBAC toggle OFF: All users see all 14 items
- [ ] RBAC toggle ON: Filtering works correctly

---

## Alternative Approach: Simple Hide (Not Recommended)

If you prefer a simpler approach that doesn't filter the list:

```dart
List<NavigationItem> _buildDestinations(AppLocalizations? l10n, WidgetRef ref) {
  final isOwner = ref.watch(isOwnerProvider).value ?? false;

  return [
    NavigationItem(...), // POS - always visible
    NavigationItem(...), // Products - always visible

    // Conditionally show Sales
    if (_hasPermission(ref, PermissionModules.REVENUE_DAILY_VIEW))
      NavigationItem(...), // Sales

    // Conditionally show Dashboard
    if (_hasPermission(ref, PermissionModules.REVENUE_DASHBOARD_VIEW))
      NavigationItem(...), // Dashboard

    // ... other items

    // Owner-only Settings
    if (isOwner)
      NavigationItem(...), // Settings
  ];
}

bool _hasPermission(WidgetRef ref, String permission) {
  return ref.watch(
    hasPermissionProvider((permission: permission, storeId: null)),
  ).value ?? false;
}
```

**Drawback**: This approach changes the list length dynamically, which requires careful index management in the `bodyBuilder`.

---

## Recommendation

Use **Option 1 (Filtered Navigation Items)** as it:
- ✅ Clearly separates permission logic
- ✅ Maintains stable screen indices
- ✅ Easy to test and debug
- ✅ Scales well if more permissions are added

---

**Status**: This is an example implementation. Actual integration requires:
1. Testing with different roles
2. Verifying navigation index mapping
3. Ensuring RBAC toggle behavior works correctly

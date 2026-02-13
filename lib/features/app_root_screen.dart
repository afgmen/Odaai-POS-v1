import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive/adaptive_scaffold.dart';
import '../l10n/app_localizations.dart';
import 'cash_drawer/presentation/screens/cash_drawer_screen.dart';
import 'customers/presentation/screens/customer_management_screen.dart';
import 'daily_closing/presentation/screens/daily_closing_screen.dart';
import 'pos/presentation/screens/pos_main_screen.dart';
import 'products/presentation/screens/product_management_screen.dart';
import 'sales/presentation/screens/sales_history_screen.dart';
import 'dashboard/presentation/screens/dashboard_screen.dart';
import 'dashboard/presentation/screens/low_stock_screen.dart';
import 'employees/presentation/screens/employee_management_screen.dart';
import 'promotions/presentation/screens/promotion_management_screen.dart';
import 'refunds/presentation/screens/refund_screen.dart';
import 'reports/presentation/screens/reports_screen.dart';
import 'settings/presentation/screens/settings_screen.dart';
import 'sync/presentation/widgets/sync_status_indicator.dart';
import 'tables/presentation/screens/table_management_screen.dart';

/// 앱 전체 탭 네비게이션 루트
/// AdaptiveScaffold 사용 → 모바일: BottomNav, 태블릿+: NavigationRail
class AppRootScreen extends ConsumerStatefulWidget {
  const AppRootScreen({super.key});

  @override
  ConsumerState<AppRootScreen> createState() => _AppRootScreenState();
}

class _AppRootScreenState extends ConsumerState<AppRootScreen> {
  int _currentIndex = 0;

  static const _screens = <Widget>[
    PosMainScreen(),           // 0
    ProductManagementScreen(), // 1
    SalesHistoryScreen(),      // 2
    DashboardScreen(),         // 3
    CustomerManagementScreen(),// 4
    TableManagementScreen(),   // 5
    RefundScreen(),            // 6
    CashDrawerScreen(),        // 7
    DailyClosingScreen(),      // 8  ← NEW
    LowStockScreen(),          // 9
    EmployeeManagementScreen(),// 10
    PromotionManagementScreen(),// 11
    ReportsScreen(),           // 12
    SettingsScreen(),          // 13
  ];

  /// 네비게이션 아이템 목록을 l10n 기반으로 빌드
  List<NavigationItem> _buildDestinations(AppLocalizations? l10n) {
    return [
      NavigationItem(icon: Icons.point_of_sale_outlined, selectedIcon: Icons.point_of_sale,
          label: l10n?.navPos ?? 'POS'),
      NavigationItem(icon: Icons.inventory_2_outlined, selectedIcon: Icons.inventory_2,
          label: l10n?.navProducts ?? 'Products'),
      NavigationItem(icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long,
          label: l10n?.navSales ?? 'Sales'),
      NavigationItem(icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart,
          label: l10n?.navDashboard ?? 'Dashboard'),
      // ─── 새 기능 4개 ────────────────────
      NavigationItem(icon: Icons.people_alt_outlined, selectedIcon: Icons.people_alt,
          label: l10n?.navCustomers ?? 'Customers'),
      NavigationItem(icon: Icons.table_restaurant_outlined, selectedIcon: Icons.table_restaurant,
          label: l10n?.navTables ?? 'Tables'),
      NavigationItem(icon: Icons.undo_outlined, selectedIcon: Icons.undo,
          label: l10n?.navRefunds ?? 'Refunds'),
      NavigationItem(icon: Icons.account_balance_wallet_outlined, selectedIcon: Icons.account_balance_wallet,
          label: l10n?.navCashDrawer ?? 'Cash'),
      NavigationItem(icon: Icons.event_note_outlined, selectedIcon: Icons.event_note,
          label: l10n?.navDailyClosing ?? 'Daily Closing'),
      // ─── 기존 기능 ─────────────────────
      NavigationItem(icon: Icons.warning_amber_outlined, selectedIcon: Icons.warning_amber_rounded,
          label: l10n?.navInventory ?? 'Low Stock'),
      NavigationItem(icon: Icons.people_outline, selectedIcon: Icons.people,
          label: l10n?.navEmployees ?? 'Employees'),
      NavigationItem(icon: Icons.local_offer_outlined, selectedIcon: Icons.local_offer,
          label: l10n?.navPromotions ?? 'Promotions'),
      NavigationItem(icon: Icons.analytics_outlined, selectedIcon: Icons.analytics,
          label: l10n?.navReports ?? 'Reports'),
      NavigationItem(icon: Icons.settings_outlined, selectedIcon: Icons.settings,
          label: l10n?.settings ?? 'Settings'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AdaptiveScaffold(
      currentIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      destinations: _buildDestinations(l10n),
      trailing: const SyncStatusIndicator(),
      bodyBuilder: (context, index) {
        return IndexedStack(
          index: _currentIndex,
          children: _screens,
        );
      },
    );
  }
}

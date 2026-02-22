import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive/adaptive_scaffold.dart';
import '../l10n/app_localizations.dart';
import 'auth/providers/rbac_providers.dart';
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
import 'delivery/presentation/screens/delivery_queue_screen.dart';
import 'delivery/domain/services/kds_delivery_bridge_provider.dart';

/// 개별 탭 항목 데이터 모델
class _TabEntry {
  final Widget screen;
  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations? l10n) label;
  /// null이면 RBAC와 무관하게 항상 표시
  final String? requiredPermission;

  const _TabEntry({
    required this.screen,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.requiredPermission,
  });
}

/// 앱 전체 탭 네비게이션 루트
/// AdaptiveScaffold 사용 → 모바일: BottomNav, 태블릿+: NavigationRail
/// RBAC 활성화 시 권한 없는 탭은 자동으로 숨겨집니다.
class AppRootScreen extends ConsumerStatefulWidget {
  const AppRootScreen({super.key});

  @override
  ConsumerState<AppRootScreen> createState() => _AppRootScreenState();
}

class _AppRootScreenState extends ConsumerState<AppRootScreen> {
  int _currentIndex = 0;

  /// 전체 탭 목록 (permission이 null이면 항상 표시)
  static const _allTabs = <_TabEntry>[
    _TabEntry(
      screen: PosMainScreen(),
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale,
      label: _labelPos,
      requiredPermission: 'pos.open',
    ),
    _TabEntry(
      screen: ProductManagementScreen(),
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: _labelProducts,
      requiredPermission: 'inventory.view',
    ),
    _TabEntry(
      screen: SalesHistoryScreen(),
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: _labelSales,
      requiredPermission: 'order.view',
    ),
    _TabEntry(
      screen: DashboardScreen(),
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      label: _labelDashboard,
      requiredPermission: 'revenue.dashboard.view',
    ),
    _TabEntry(
      screen: CustomerManagementScreen(),
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt,
      label: _labelCustomers,
      requiredPermission: 'order.view',
    ),
    _TabEntry(
      screen: TableManagementScreen(),
      icon: Icons.table_restaurant_outlined,
      selectedIcon: Icons.table_restaurant,
      label: _labelTables,
      requiredPermission: 'pos.open',
    ),
    _TabEntry(
      screen: RefundScreen(),
      icon: Icons.undo_outlined,
      selectedIcon: Icons.undo,
      label: _labelRefunds,
      requiredPermission: 'pos.refund',
    ),
    _TabEntry(
      screen: CashDrawerScreen(),
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      label: _labelCashDrawer,
      requiredPermission: 'pos.cash.drawer.open',
    ),
    _TabEntry(
      screen: DailyClosingScreen(),
      icon: Icons.event_note_outlined,
      selectedIcon: Icons.event_note,
      label: _labelDailyClosing,
      requiredPermission: 'revenue.daily.view',
    ),
    _TabEntry(
      screen: LowStockScreen(),
      icon: Icons.warning_amber_outlined,
      selectedIcon: Icons.warning_amber_rounded,
      label: _labelInventory,
      requiredPermission: 'inventory.view',
    ),
    _TabEntry(
      screen: EmployeeManagementScreen(),
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      label: _labelEmployees,
      requiredPermission: 'staff.view',
    ),
    _TabEntry(
      screen: PromotionManagementScreen(),
      icon: Icons.local_offer_outlined,
      selectedIcon: Icons.local_offer,
      label: _labelPromotions,
      requiredPermission: 'inventory.edit',
    ),
    _TabEntry(
      screen: ReportsScreen(),
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      label: _labelReports,
      requiredPermission: 'revenue.dashboard.view',
    ),
    _TabEntry(
      screen: DeliveryQueueScreen(),
      icon: Icons.delivery_dining_outlined,
      selectedIcon: Icons.delivery_dining,
      label: _labelDelivery,
      // Delivery is accessible to anyone who can open the POS
      requiredPermission: 'pos.open',
    ),
    _TabEntry(
      screen: SettingsScreen(),
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: _labelSettings,
      // 설정은 항상 표시 (내부에서 권한별 항목 제어)
      requiredPermission: null,
    ),
  ];

  // Static label helpers (tear-offs)
  static String _labelPos(AppLocalizations? l10n) => l10n?.navPos ?? 'POS';
  static String _labelProducts(AppLocalizations? l10n) => l10n?.navProducts ?? 'Products';
  static String _labelSales(AppLocalizations? l10n) => l10n?.navSales ?? 'Sales';
  static String _labelDashboard(AppLocalizations? l10n) => l10n?.navDashboard ?? 'Dashboard';
  static String _labelCustomers(AppLocalizations? l10n) => l10n?.navCustomers ?? 'Customers';
  static String _labelTables(AppLocalizations? l10n) => l10n?.navTables ?? 'Tables';
  static String _labelRefunds(AppLocalizations? l10n) => l10n?.navRefunds ?? 'Refunds';
  static String _labelCashDrawer(AppLocalizations? l10n) => l10n?.navCashDrawer ?? 'Cash';
  static String _labelDailyClosing(AppLocalizations? l10n) => l10n?.navDailyClosing ?? 'Daily Closing';
  static String _labelInventory(AppLocalizations? l10n) => l10n?.navInventory ?? 'Low Stock';
  static String _labelEmployees(AppLocalizations? l10n) => l10n?.navEmployees ?? 'Employees';
  static String _labelPromotions(AppLocalizations? l10n) => l10n?.navPromotions ?? 'Promotions';
  static String _labelReports(AppLocalizations? l10n) => l10n?.navReports ?? 'Reports';
  static String _labelDelivery(AppLocalizations? l10n) => l10n?.deliveryTitle ?? 'Delivery';
  static String _labelSettings(AppLocalizations? l10n) => l10n?.settings ?? 'Settings';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // KDS→Delivery bridge: keep alive so status changes are forwarded
    ref.watch(kdsDeliveryBridgeProvider);

    // RBAC 활성화 여부 감시
    final rbacEnabled = ref.watch(rbacSettingProvider);

    // 사용자 권한 목록 감시
    final userPermissions = ref.watch(userPermissionsProvider);

    // RBAC 상태 로딩 중 → 로딩 표시
    if (rbacEnabled.isLoading || userPermissions.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isRbacOn = rbacEnabled.valueOrNull ?? false;
    final permissions = userPermissions.valueOrNull ?? {};

    // 표시할 탭 필터링
    final visibleTabs = _allTabs.where((tab) {
      // RBAC 꺼져있으면 모든 탭 표시
      if (!isRbacOn) return true;
      // permission이 null이면 항상 표시
      if (tab.requiredPermission == null) return true;
      // 권한 보유 여부로 필터링
      return permissions.contains(tab.requiredPermission);
    }).toList();

    // currentIndex가 범위 초과하면 0으로 재설정
    final safeIndex = _currentIndex < visibleTabs.length ? _currentIndex : 0;

    final destinations = visibleTabs
        .map((tab) => NavigationItem(
              icon: tab.icon,
              selectedIcon: tab.selectedIcon,
              label: tab.label(l10n),
            ))
        .toList();

    return AdaptiveScaffold(
      currentIndex: safeIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      destinations: destinations,
      trailing: const SyncStatusIndicator(),
      bodyBuilder: (context, index) {
        return IndexedStack(
          index: safeIndex,
          children: visibleTabs.map((tab) => tab.screen).toList(),
        );
      },
    );
  }
}

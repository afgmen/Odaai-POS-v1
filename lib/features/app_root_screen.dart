import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import 'pos/presentation/screens/pos_main_screen.dart';
import 'products/presentation/screens/product_management_screen.dart';
import 'sales/presentation/screens/sales_history_screen.dart';
import 'dashboard/presentation/screens/dashboard_screen.dart';
import 'dashboard/presentation/screens/low_stock_screen.dart';
import 'employees/presentation/screens/employee_management_screen.dart';
import 'promotions/presentation/screens/promotion_management_screen.dart';

/// 앱 전체 탭 네비게이션 루트
/// IndexedStack 사용 → 탭 전환 시 각 화면의 로컬 상태(스크롤 등) 유지
class AppRootScreen extends ConsumerStatefulWidget {
  const AppRootScreen({super.key});

  @override
  ConsumerState<AppRootScreen> createState() => _AppRootScreenState();
}

class _AppRootScreenState extends ConsumerState<AppRootScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          PosMainScreen(),
          ProductManagementScreen(),
          SalesHistoryScreen(),
          DashboardScreen(),
          LowStockScreen(),
          EmployeeManagementScreen(),
          PromotionManagementScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppTheme.cardWhite,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x14000000),
        height: 70,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppTheme.textSecondary);
        }),
        indicatorColor: const Color(0xFFE8F0FE),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'POS',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: '상품관리',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '주문내역',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '대시보드',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber_rounded),
            label: '재고부족',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: '직원관리',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer),
            label: '프로모션',
          ),
        ],
      ),
    );
  }
}

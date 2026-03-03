# RBAC Feature Integration Guide

> **Purpose**: Step-by-step guide for integrating RBAC permission checks into existing features
>
> **Date**: 2026-02-12
> **Status**: Implementation Guide

---

## 📋 Features Requiring Integration

Based on codebase analysis, these features need RBAC permission checks:

| Feature | Screen/Component | Permission Required | Priority |
|---------|------------------|---------------------|:--------:|
| **Dashboard** | `dashboard_screen.dart` | `revenue.dashboard.view` | HIGH |
| **Daily Closing** | `daily_closing_screen.dart` | `revenue.daily.view` | HIGH |
| **Sales Reports** | `reports_screen.dart` | `revenue.daily/weekly/monthly.view` | HIGH |
| **Sales History** | `sales_history_screen.dart` | `revenue.daily.view` | MEDIUM |
| **Employee Management** | `employee_management_screen.dart` | `staff.manage` | HIGH |
| **Settings** | Various settings screens | `settings.*` permissions | MEDIUM |
| **Inventory** | Inventory screens (if exists) | `inventory.edit`, `inventory.adjust` | MEDIUM |

---

## 🔧 Integration Steps by Feature

### 1. Dashboard Screen (Revenue Dashboard)

**File**: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

**Permission**: `revenue.dashboard.view`

**Integration Pattern**:
```dart
import '../../../../core/widgets/permission_gate_widget.dart';
import '../../../../features/auth/domain/permission_modules.dart';

class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionGateWidget(
      permission: PermissionModules.REVENUE_DASHBOARD_VIEW,
      fallback: const AccessDeniedCard(
        message: '매출 대시보드를 볼 권한이 없습니다',
      ),
      child: Scaffold(
        // ... existing dashboard code
      ),
    );
  }
}
```

---

### 2. Daily Closing Screen

**File**: `lib/features/daily_closing/presentation/screens/daily_closing_screen.dart`

**Permission**: `revenue.daily.view`

**Integration Pattern**:
```dart
import '../../../../core/widgets/permission_gate_widget.dart';
import '../../../../features/auth/domain/permission_modules.dart';

class DailyClosingScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<DailyClosingScreen> createState() => _DailyClosingScreenState();
}

class _DailyClosingScreenState extends ConsumerState<DailyClosingScreen> {
  @override
  Widget build(BuildContext context) {
    return PermissionGateWidget(
      permission: PermissionModules.REVENUE_DAILY_VIEW,
      fallback: Scaffold(
        appBar: AppBar(title: const Text('일일 마감')),
        body: const AccessDeniedCard(
          message: '일일 매출을 볼 권한이 없습니다',
        ),
      ),
      child: Scaffold(
        // ... existing daily closing code
      ),
    );
  }
}
```

---

### 3. Sales Reports Screen

**File**: `lib/features/reports/presentation/screens/reports_screen.dart`

**Permission**: Multiple permissions based on report type

**Integration Pattern**:
```dart
import '../../../../core/widgets/permission_gate_widget.dart';
import '../../../../features/auth/domain/permission_modules.dart';

// For daily report tab
PermissionGateWidget(
  permission: PermissionModules.REVENUE_DAILY_VIEW,
  child: DailyReportTab(),
  fallback: const AccessDeniedCard(
    message: '일일 매출 보고서를 볼 권한이 없습니다',
  ),
)

// For weekly report tab
PermissionGateWidget(
  permission: PermissionModules.REVENUE_WEEKLY_VIEW,
  child: WeeklyReportTab(),
  fallback: const AccessDeniedCard(
    message: '주간 매출 보고서를 볼 권한이 없습니다',
  ),
)

// For monthly report tab
PermissionGateWidget(
  permission: PermissionModules.REVENUE_MONTHLY_VIEW,
  child: MonthlyReportTab(),
  fallback: const AccessDeniedCard(
    message: '월간 매출 보고서를 볼 권한이 없습니다',
  ),
)
```

---

### 4. Employee Management Screen

**File**: `lib/features/employees/presentation/screens/employee_management_screen.dart`

**Permission**: `staff.manage`

**Integration Pattern**:
```dart
import '../../../../core/widgets/permission_gate_widget.dart';
import '../../../../features/auth/domain/permission_modules.dart';

class EmployeeManagementScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionGateWidget(
      permission: PermissionModules.STAFF_MANAGE,
      fallback: const AccessDeniedCard(
        message: '직원 관리 권한이 없습니다',
      ),
      child: Scaffold(
        // ... existing employee management code
        floatingActionButton: PermissionGuard(
          permission: PermissionModules.STAFF_MANAGE,
          child: FloatingActionButton(
            onPressed: () => _showAddEmployeeDialog(),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
```

---

### 5. Navigation Menu (Hide Items)

**File**: `lib/core/navigation/main_navigation.dart` (or similar)

**Integration Pattern**:
```dart
import '../../core/widgets/permission_gate_widget.dart';
import '../../features/auth/domain/permission_modules.dart';

// Hide navigation items based on permissions
PermissionGuard(
  permission: PermissionModules.REVENUE_DASHBOARD_VIEW,
  child: NavigationDestination(
    icon: Icon(Icons.dashboard),
    label: '대시보드',
  ),
)

PermissionGuard(
  permission: PermissionModules.REVENUE_DAILY_VIEW,
  child: NavigationDestination(
    icon: Icon(Icons.summarize),
    label: '일일 마감',
  ),
)

PermissionGuard(
  permission: PermissionModules.STAFF_MANAGE,
  child: NavigationDestination(
    icon: Icon(Icons.people),
    label: '직원 관리',
  ),
)

// Owner-only Settings
OwnerOnly(
  child: NavigationDestination(
    icon: Icon(Icons.settings),
    label: '설정',
  ),
)
```

---

## 🎨 UI Patterns Reference

### Pattern 1: Full Screen Permission Guard
Use when the entire screen requires permission:
```dart
PermissionGateWidget(
  permission: 'revenue.dashboard.view',
  fallback: AccessDeniedCard(),
  child: YourScreen(),
)
```

### Pattern 2: Partial Screen Guard
Use when only part of the screen requires permission:
```dart
Column(
  children: [
    PublicWidget(),
    PermissionGateWidget(
      permission: 'revenue.daily.view',
      child: SensitiveDataWidget(),
      fallback: Text('권한 없음'),
    ),
  ],
)
```

### Pattern 3: Button/Action Guard
Use to disable buttons based on permission:
```dart
PermissionButton(
  permission: 'order.cancel',
  onPressed: () => cancelOrder(),
  child: Text('주문 취소'),
)

// OR

PermissionGuard(
  permission: 'staff.manage',
  child: ElevatedButton(
    onPressed: () => addEmployee(),
    child: Text('직원 추가'),
  ),
)
```

### Pattern 4: Owner-Only Features
Use for owner-exclusive features:
```dart
OwnerOnly(
  child: AdvancedSettingsButton(),
  fallback: SizedBox.shrink(),
)
```

---

## 🔍 Testing Checklist

After integration, test with different roles:

### OWNER Role Testing:
- [ ] Can access all screens
- [ ] Can see all navigation items
- [ ] Can perform all actions
- [ ] RBAC toggle visible in settings

### AREA_MANAGER Role Testing:
- [ ] Can access dashboard
- [ ] Can see all revenue reports
- [ ] Can manage staff
- [ ] Cannot access settings
- [ ] Can access assigned stores only

### STORE_MANAGER Role Testing:
- [ ] Can access dashboard
- [ ] Can see daily revenue only
- [ ] Cannot see weekly/monthly revenue
- [ ] Cannot access settings
- [ ] Can access own store only

### STAFF Role Testing:
- [ ] Cannot access dashboard
- [ ] Cannot see any revenue reports
- [ ] Cannot access employee management
- [ ] Cannot access settings
- [ ] Can only perform POS operations
- [ ] Can access own store only

---

## 🚨 Common Pitfalls

### 1. Forgetting Store Scope Validation
```dart
// ❌ WRONG - No store scope validation
PermissionGateWidget(
  permission: 'revenue.daily.view',
  child: RevenueWidget(),
)

// ✅ CORRECT - With store scope
PermissionGateWidget(
  permission: 'revenue.daily.view',
  storeId: currentStoreId, // Always pass storeId for revenue data
  child: RevenueWidget(),
)
```

### 2. Hardcoding Permission Strings
```dart
// ❌ WRONG
PermissionGateWidget(
  permission: 'revenue.daily.view',
  child: Widget(),
)

// ✅ CORRECT
PermissionGateWidget(
  permission: PermissionModules.REVENUE_DAILY_VIEW,
  child: Widget(),
)
```

### 3. Not Providing Fallback
```dart
// ⚠️ OK but not user-friendly
PermissionGateWidget(
  permission: PermissionModules.REVENUE_DAILY_VIEW,
  child: Widget(),
  // No fallback - widget just disappears
)

// ✅ BETTER
PermissionGateWidget(
  permission: PermissionModules.REVENUE_DAILY_VIEW,
  child: Widget(),
  fallback: AccessDeniedCard(message: 'Clear message'),
)
```

---

## 📝 Implementation Order

1. **Phase 5a: Core Revenue Features** (Week 1)
   - [ ] Dashboard Screen
   - [ ] Daily Closing Screen
   - [ ] Sales Reports Screen

2. **Phase 5b: Management Features** (Week 1)
   - [ ] Employee Management Screen
   - [ ] Settings Screens

3. **Phase 5c: Navigation & UI** (Week 1)
   - [ ] Main Navigation Menu
   - [ ] Drawer/Sidebar (if exists)
   - [ ] Action Buttons

4. **Phase 5d: Testing** (Week 1)
   - [ ] Create test accounts for each role
   - [ ] Manual testing per role
   - [ ] Document test results

---

## 🎯 Success Criteria

- [ ] All revenue screens protected with RBAC
- [ ] Staff role cannot see any financial data
- [ ] Navigation hides items based on permissions
- [ ] Action buttons disabled based on permissions
- [ ] Clear "Access Denied" messages shown
- [ ] Store scope validated for multi-store data
- [ ] All permission checks use constants (no hardcoded strings)
- [ ] Manual testing passed for all 4 roles

---

## 📚 Reference

- **Permission Constants**: `lib/features/auth/domain/permission_modules.dart`
- **Permission Widgets**: `lib/core/widgets/permission_gate_widget.dart`
- **RBAC Providers**: `lib/features/auth/providers/rbac_providers.dart`
- **Design Document**: `docs/02-design/features/role-based-access-control.design.md`

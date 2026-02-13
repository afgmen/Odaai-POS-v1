# RBAC Integration Status

> **Date**: 2026-02-12
> **Phase**: Phase 5 - Feature Integration (In Progress)

---

## ✅ Completed Integrations

### 1. Dashboard Screen
**File**: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

**Changes**:
- ✅ Wrapped entire screen with `PermissionGateWidget`
- ✅ Permission: `PermissionModules.REVENUE_DASHBOARD_VIEW`
- ✅ Fallback: `AccessDeniedCard` with Korean message
- ✅ Added imports for `permission_gate_widget.dart` and `permission_modules.dart`

**Pattern Used**: Full Screen Permission Guard

```dart
return PermissionGateWidget(
  permission: PermissionModules.REVENUE_DASHBOARD_VIEW,
  fallback: Scaffold(
    appBar: AppBar(...),
    body: const Center(
      child: AccessDeniedCard(
        message: '매출 대시보드를 볼 권한이 없습니다',
      ),
    ),
  ),
  child: _DashboardScreenContent(),
);
```

**Effect**:
- STAFF role: Cannot access dashboard (sees "Access Denied")
- STORE_MANAGER role: Can view dashboard
- AREA_MANAGER role: Can view dashboard
- OWNER role: Can view dashboard

---

### 2. Daily Closing Screen
**File**: `lib/features/daily_closing/presentation/screens/daily_closing_screen.dart`

**Changes**:
- ✅ Wrapped entire screen with `PermissionGateWidget`
- ✅ Permission: `PermissionModules.REVENUE_DAILY_VIEW`
- ✅ Fallback: `AccessDeniedCard` with Korean message
- ✅ Added imports for `permission_gate_widget.dart` and `permission_modules.dart`

**Pattern Used**: Full Screen Permission Guard

```dart
return PermissionGateWidget(
  permission: PermissionModules.REVENUE_DAILY_VIEW,
  fallback: Scaffold(
    appBar: AppBar(title: Text(l10n.dailyClosing)),
    body: const Center(
      child: AccessDeniedCard(
        message: '일일 매출을 볼 권한이 없습니다',
      ),
    ),
  ),
  child: _buildClosingContent(context),
);
```

**Effect**:
- STAFF role: Cannot access daily closing (sees "Access Denied")
- STORE_MANAGER role: Can perform daily closing
- AREA_MANAGER role: Can perform daily closing
- OWNER role: Can perform daily closing

---

### 3. Employee Management Screen
**File**: `lib/features/employees/presentation/screens/employee_management_screen.dart`

**Changes**:
- ✅ Wrapped entire screen with `PermissionGateWidget`
- ✅ Permission: `PermissionModules.STAFF_MANAGE`
- ✅ Fallback: `AccessDeniedCard` with Korean message
- ✅ Added `PermissionGuard` around "Add Employee" button
- ✅ Added imports for `permission_gate_widget.dart` and `permission_modules.dart`

**Pattern Used**: Full Screen Permission Guard + Button Guard

```dart
return PermissionGateWidget(
  permission: PermissionModules.STAFF_MANAGE,
  fallback: Scaffold(...),
  child: _EmployeeManagementContent(),
);

// Inside content:
actions: [
  PermissionGuard(
    permission: PermissionModules.STAFF_MANAGE,
    child: ElevatedButton.icon(...),
  ),
],
```

**Effect**:
- STAFF role: Cannot access employee management
- STORE_MANAGER role: Cannot manage employees
- AREA_MANAGER role: Can manage employees
- OWNER role: Can manage employees

---

## 🔄 Pending Integrations

### 4. Sales Reports Screen
**File**: `lib/features/reports/presentation/screens/reports_screen.dart`

**Permissions Needed**:
- `PermissionModules.REVENUE_DAILY_VIEW` - Daily report tab
- `PermissionModules.REVENUE_WEEKLY_VIEW` - Weekly report tab
- `PermissionModules.REVENUE_MONTHLY_VIEW` - Monthly report tab

**Pattern**: Tab-level Permission Guards

**Implementation**:
```dart
// Daily Report Tab
PermissionGateWidget(
  permission: PermissionModules.REVENUE_DAILY_VIEW,
  child: DailyReportTab(),
  fallback: const AccessDeniedCard(
    message: '일일 매출 보고서를 볼 권한이 없습니다',
  ),
)

// Weekly Report Tab
PermissionGateWidget(
  permission: PermissionModules.REVENUE_WEEKLY_VIEW,
  child: WeeklyReportTab(),
  fallback: const AccessDeniedCard(
    message: '주간 매출 보고서를 볼 권한이 없습니다',
  ),
)

// Monthly Report Tab
PermissionGateWidget(
  permission: PermissionModules.REVENUE_MONTHLY_VIEW,
  child: MonthlyReportTab(),
  fallback: const AccessDeniedCard(
    message: '월간 매출 보고서를 볼 권한이 없습니다',
  ),
)
```

---

### 5. Sales History Screen
**File**: `lib/features/sales/presentation/screens/sales_history_screen.dart`

**Permissions Needed**:
- `PermissionModules.REVENUE_DAILY_VIEW` - View sales history

**Pattern**: Full Screen Permission Guard

---

### 6. Navigation Menu
**File**: TBD (need to locate main navigation file)

**Implementation**:
```dart
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

OwnerOnly(
  child: NavigationDestination(
    icon: Icon(Icons.settings),
    label: '설정',
  ),
)
```

---

### 7. Settings Screens
**Files**: Various settings screens

**Permissions Needed**:
- `PermissionModules.SETTINGS_STORE_EDIT` - Store settings
- `PermissionModules.SETTINGS_TAX_EDIT` - Tax settings
- `PermissionModules.SETTINGS_PAYMENT_EDIT` - Payment settings
- `PermissionModules.SETTINGS_INTEGRATION_EDIT` - Integration settings

**Pattern**: Owner-only wrapper

```dart
OwnerOnly(
  child: SettingsScreen(),
  fallback: AccessDeniedCard(message: 'Owner only'),
)
```

---

## 📋 Integration Checklist

### Phase 5a: Core Revenue Features ✅
- [x] Dashboard Screen
- [x] Daily Closing Screen
- [x] Employee Management Screen

### Phase 5b: Reports & History 🔄
- [ ] Sales Reports Screen (daily/weekly/monthly tabs)
- [ ] Sales History Screen

### Phase 5c: Navigation & Settings 🔄
- [ ] Main Navigation Menu
- [ ] Settings Screens

### Phase 5d: Testing ⏳
- [ ] Create test accounts for each role (OWNER, AREA_MANAGER, STORE_MANAGER, STAFF)
- [ ] Manual testing per role
- [ ] Document test results

---

## 🎯 Role Permission Summary

| Role | Dashboard | Daily Closing | Reports | Employee Mgmt | Settings |
|------|-----------|---------------|---------|---------------|----------|
| **OWNER** | ✅ All | ✅ All | ✅ All | ✅ Yes | ✅ Yes |
| **AREA_MANAGER** | ✅ All stores | ✅ All stores | ✅ All periods | ✅ Yes | ❌ No |
| **STORE_MANAGER** | ✅ Own store | ✅ Own store | ✅ Daily only | ❌ No | ❌ No |
| **STAFF** | ❌ No | ❌ No | ❌ No | ❌ No | ❌ No |

---

## 🚨 Important Notes

1. **Store Scope Validation**:
   - For AREA_MANAGER and STORE_MANAGER, always pass `storeId` parameter
   - Example: `PermissionGateWidget(permission: '...', storeId: currentStoreId, ...)`

2. **RBAC Toggle**:
   - When RBAC is disabled (`rbac_enabled = false`), all users have all permissions
   - This ensures backward compatibility for existing installations

3. **Permission Constants**:
   - Always use `PermissionModules.PERMISSION_NAME` constants
   - Never hardcode permission strings

4. **Fallback UI**:
   - Always provide clear, user-friendly `AccessDeniedCard` messages
   - Use Korean messages matching the app's localization

5. **Testing Priority**:
   - Test with STAFF role first (most restrictive)
   - Verify OWNER role has access to everything
   - Test RBAC toggle on/off behavior

---

## 📚 Reference Files

- **Permission Constants**: `lib/features/auth/domain/permission_modules.dart`
- **Permission Widgets**: `lib/core/widgets/permission_gate_widget.dart`
- **RBAC Providers**: `lib/features/auth/providers/rbac_providers.dart`
- **Integration Guide**: `docs/rbac-integration-guide.md`
- **Design Document**: `docs/02-design/features/role-based-access-control.design.md`

---

## 🔜 Next Steps

1. ✅ Complete Phase 5b: Integrate Reports and Sales History screens
2. ✅ Complete Phase 5c: Integrate Navigation and Settings
3. ✅ Phase 6: Create test accounts and perform manual testing
4. ✅ Phase 6: Document test results
5. ✅ Phase 6: Create production migration guide

---

## 💡 Integration Tips

### Quick Integration Template

```dart
// 1. Add imports
import '../../../../core/widgets/permission_gate_widget.dart';
import '../../../auth/domain/permission_modules.dart';

// 2. Wrap screen with PermissionGateWidget
return PermissionGateWidget(
  permission: PermissionModules.YOUR_PERMISSION,
  fallback: Scaffold(
    appBar: AppBar(title: Text('Screen Title')),
    body: const Center(
      child: AccessDeniedCard(
        message: '권한 없음 메시지',
      ),
    ),
  ),
  child: YourScreenContent(),
);

// 3. Use PermissionGuard for buttons/widgets
PermissionGuard(
  permission: PermissionModules.YOUR_PERMISSION,
  child: YourWidget(),
)

// 4. Use OwnerOnly for owner-exclusive features
OwnerOnly(
  child: OwnerOnlyWidget(),
  fallback: SizedBox.shrink(),
)
```

---

**Last Updated**: 2026-02-12
**Status**: Phase 5 In Progress (3/7 features integrated)

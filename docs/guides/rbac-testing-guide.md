# RBAC Testing Guide

> **Purpose**: Comprehensive manual testing guide for RBAC feature
> **Date**: 2026-02-12
> **Status**: Testing Ready

---

## 📋 Testing Overview

This guide provides step-by-step instructions for manually testing the RBAC (Role-Based Access Control) system across all 4 roles.

---

## 🔧 Test Environment Setup

### Prerequisites

1. ✅ Database migrated to v12 (with RBAC tables)
2. ✅ All Phase 1-5 implementations complete
3. ✅ App builds without errors

### Step 1: Create Test Accounts

Run these SQL commands in your database:

```sql
-- 1. Create OWNER test account (should already exist)
INSERT OR IGNORE INTO employees (id, name, pin, role, is_active, created_at)
VALUES (1, 'Test Owner', '1111', 'MANAGER', 1, datetime('now'));

-- Update to OWNER with full access
UPDATE employees
SET defaultRole = 'OWNER',
    storeScope = 'ALL_STORES',
    primaryStoreId = NULL
WHERE id = 1;

-- 2. Create AREA_MANAGER test account
INSERT INTO employees (name, pin, role, is_active, defaultRole, storeScope, created_at)
VALUES ('Test Area Manager', '2222', 'MANAGER', 1, 'AREA_MANAGER', 'ASSIGNED_STORES', datetime('now'));

-- Get the ID of area manager
-- Assume ID = 2 for this example

-- Assign area manager to multiple stores
INSERT INTO store_assignments (employeeId, storeId, assignedAt)
VALUES
  (2, 'store-001', datetime('now')),
  (2, 'store-002', datetime('now'));

-- 3. Create STORE_MANAGER test account
INSERT INTO employees (name, pin, role, is_active, defaultRole, storeScope, primaryStoreId, created_at)
VALUES ('Test Store Manager', '3333', 'MANAGER', 1, 'STORE_MANAGER', 'OWN_STORE', 'store-001', datetime('now'));

-- 4. Create STAFF test account
INSERT INTO employees (name, pin, role, is_active, defaultRole, storeScope, primaryStoreId, created_at)
VALUES ('Test Staff', '4444', 'CASHIER', 1, 'STAFF', 'OWN_STORE', 'store-001', datetime('now'));
```

### Step 2: Enable RBAC System

1. Login as OWNER (PIN: 1111)
2. Navigate to Settings → Security Settings
3. Toggle "RBAC (Role-Based Access Control)" to ON
4. Verify the toggle shows "RBAC가 활성화됨"

---

## 🧪 Test Cases by Role

### Test 1: OWNER Role (Full Access)

**Login**: PIN `1111`

| Feature | Expected Result | Status |
|---------|----------------|--------|
| **Navigation** | | |
| All 14 navigation items visible | ✅ Should see all items | ⬜ |
| Settings menu visible | ✅ Should be visible | ⬜ |
| **Dashboard** | | |
| Can access Dashboard screen | ✅ No "Access Denied" | ⬜ |
| Can see total sales | ✅ Revenue visible | ⬜ |
| Can see order count | ✅ Data visible | ⬜ |
| Can see payment breakdown | ✅ All data visible | ⬜ |
| **Daily Closing** | | |
| Can access Daily Closing screen | ✅ No "Access Denied" | ⬜ |
| Can view cash reconciliation | ✅ Amounts visible | ⬜ |
| Can perform closing | ✅ Button enabled | ⬜ |
| Can generate PDF | ✅ PDF created | ⬜ |
| **Sales Reports** | | |
| Can access Reports screen | ✅ No "Access Denied" | ⬜ |
| Can view KPI cards | ✅ All data visible | ⬜ |
| Can export to Excel | ✅ Excel downloaded | ⬜ |
| **Sales History** | | |
| Can access Sales History | ✅ No "Access Denied" | ⬜ |
| Can see transaction amounts | ✅ All amounts visible | ⬜ |
| Can view sale details | ✅ Detail screen opens | ⬜ |
| **Employee Management** | | |
| Can access Employee Management | ✅ No "Access Denied" | ⬜ |
| "Add Employee" button visible | ✅ Button shown | ⬜ |
| Can add new employee | ✅ Form opens | ⬜ |
| Can edit employees | ✅ Edit works | ⬜ |
| Can assign roles | ✅ Role selection works | ⬜ |
| **Settings** | | |
| Can access Settings | ✅ Full access | ⬜ |
| Can see Security Settings | ✅ RBAC toggle visible | ⬜ |
| Can toggle RBAC on/off | ✅ Toggle works | ⬜ |

**Expected Total**: All features accessible ✅

---

### Test 2: AREA_MANAGER Role (Multi-Store Manager)

**Login**: PIN `2222`

| Feature | Expected Result | Status |
|---------|----------------|--------|
| **Dashboard** | | |
| Can access Dashboard screen | ✅ No "Access Denied" | ⬜ |
| Can see all revenue data | ✅ All data visible | ⬜ |
| Can see assigned stores data | ✅ Store-001 & Store-002 | ⬜ |
| **Daily Closing** | | |
| Can access Daily Closing screen | ✅ No "Access Denied" | ⬜ |
| Can perform closing for assigned stores | ✅ Works | ⬜ |
| **Sales Reports** | | |
| Can access Reports screen | ✅ No "Access Denied" | ⬜ |
| Can view all report periods | ✅ Daily/Weekly/Monthly | ⬜ |
| Can export reports | ✅ Excel export works | ⬜ |
| **Sales History** | | |
| Can access Sales History | ✅ No "Access Denied" | ⬜ |
| Can see transaction amounts | ✅ Amounts visible | ⬜ |
| **Employee Management** | | |
| Can access Employee Management | ✅ No "Access Denied" | ⬜ |
| "Add Employee" button visible | ✅ Button shown | ⬜ |
| Can manage employees | ✅ Full access | ⬜ |
| **Settings** | | |
| Can access Settings | ❌ "Access Denied" OR hidden | ⬜ |
| Cannot see RBAC toggle | ❌ Not visible | ⬜ |

**Expected**: Access to all features except Settings ✅/❌

---

### Test 3: STORE_MANAGER Role (Single Store Manager)

**Login**: PIN `3333`

| Feature | Expected Result | Status |
|---------|----------------|--------|
| **Dashboard** | | |
| Can access Dashboard screen | ✅ No "Access Denied" | ⬜ |
| Can see own store revenue | ✅ Store-001 data visible | ⬜ |
| Cannot see other stores | ❌ Only own store | ⬜ |
| **Daily Closing** | | |
| Can access Daily Closing screen | ✅ No "Access Denied" | ⬜ |
| Can perform closing for own store | ✅ Works | ⬜ |
| **Sales Reports** | | |
| Can access Reports screen | ✅ No "Access Denied" | ⬜ |
| Can view daily reports | ✅ Daily data visible | ⬜ |
| Can view own store only | ❌ Only Store-001 | ⬜ |
| **Sales History** | | |
| Can access Sales History | ✅ No "Access Denied" | ⬜ |
| Can see transaction amounts | ✅ Amounts visible | ⬜ |
| **Employee Management** | | |
| Can access Employee Management | ❌ "Access Denied" shown | ⬜ |
| Cannot see employee list | ❌ Blocked | ⬜ |
| **Settings** | | |
| Can access Settings | ❌ "Access Denied" OR hidden | ⬜ |
| Cannot toggle RBAC | ❌ Not accessible | ⬜ |

**Expected**: Revenue access only, no management features ✅/❌

---

### Test 4: STAFF Role (POS Operations Only)

**Login**: PIN `4444`

| Feature | Expected Result | Status |
|---------|----------------|--------|
| **Dashboard** | | |
| Can access Dashboard screen | ❌ "Access Denied" shown | ⬜ |
| Dashboard completely blocked | ❌ Cannot see any data | ⬜ |
| **Daily Closing** | | |
| Can access Daily Closing screen | ❌ "Access Denied" shown | ⬜ |
| Closing completely blocked | ❌ Cannot access | ⬜ |
| **Sales Reports** | | |
| Can access Reports screen | ❌ "Access Denied" shown | ⬜ |
| Reports completely blocked | ❌ Cannot access | ⬜ |
| **Sales History** | | |
| Can access Sales History | ❌ "Access Denied" shown | ⬜ |
| History completely blocked | ❌ Cannot see amounts | ⬜ |
| **Employee Management** | | |
| Can access Employee Management | ❌ "Access Denied" shown | ⬜ |
| Management completely blocked | ❌ Cannot access | ⬜ |
| **POS Features (Should Work)** | | |
| Can access POS screen | ✅ Full access | ⬜ |
| Can create orders | ✅ Works normally | ⬜ |
| Can process payments | ✅ Works normally | ⬜ |
| Can access Products | ✅ Can view/manage | ⬜ |
| Can access Customers | ✅ Can view/manage | ⬜ |

**Expected**: All revenue features blocked, POS operations allowed ✅/❌

---

## 🔄 RBAC Toggle Testing

### Test 5: RBAC Toggle OFF (Backward Compatibility)

**Login as OWNER**

1. Navigate to Settings → Security Settings
2. Toggle RBAC to **OFF**
3. Logout and login as **STAFF** (PIN: 4444)

| Feature | Expected Result | Status |
|---------|----------------|--------|
| Dashboard | ✅ Full access (no blocking) | ⬜ |
| Daily Closing | ✅ Full access | ⬜ |
| Sales Reports | ✅ Full access | ⬜ |
| Sales History | ✅ Full access | ⬜ |
| Employee Management | ✅ Full access | ⬜ |

**Expected**: With RBAC OFF, all users have full access ✅

4. Login as OWNER, toggle RBAC back to **ON**
5. Verify STAFF is blocked again

---

## 🐛 Error Cases Testing

### Test 6: Permission Denied UI

For each blocked screen (STAFF role), verify:

| Check | Expected Result | Status |
|-------|----------------|--------|
| Screen shows proper AppBar | ✅ Title visible | ⬜ |
| "Access Denied" card centered | ✅ Centered in body | ⬜ |
| Lock icon displayed | ✅ Icon visible | ⬜ |
| Korean message shown | ✅ Correct message | ⬜ |
| "Contact admin" message shown | ✅ Help text visible | ⬜ |
| No error/crash | ✅ App stable | ⬜ |

---

## 📊 Test Results Summary

### Completion Checklist

- [ ] Test 1: OWNER role (all features work)
- [ ] Test 2: AREA_MANAGER role (no settings)
- [ ] Test 3: STORE_MANAGER role (no employee mgmt/settings)
- [ ] Test 4: STAFF role (no revenue features)
- [ ] Test 5: RBAC toggle OFF (backward compatibility)
- [ ] Test 6: Permission denied UI (correct messages)

### Test Results Template

```
=================================================
RBAC Testing Results
Date: _______________
Tester: _______________
=================================================

Test 1: OWNER Role
Status: [ ] PASS  [ ] FAIL
Notes: _________________________________________

Test 2: AREA_MANAGER Role
Status: [ ] PASS  [ ] FAIL
Notes: _________________________________________

Test 3: STORE_MANAGER Role
Status: [ ] PASS  [ ] FAIL
Notes: _________________________________________

Test 4: STAFF Role
Status: [ ] PASS  [ ] FAIL
Notes: _________________________________________

Test 5: RBAC Toggle OFF
Status: [ ] PASS  [ ] FAIL
Notes: _________________________________________

Test 6: Permission Denied UI
Status: [ ] PASS  [ ] FAIL
Notes: _________________________________________

=================================================
Overall Status: [ ] ALL PASS  [ ] NEEDS FIX
=================================================
```

---

## 🚨 Common Issues & Solutions

### Issue 1: "Access Denied" shown to OWNER
**Cause**: RBAC toggle is ON but permission seeding failed
**Solution**: Re-run `_seedRBACPermissions()` method

### Issue 2: All users see all features (RBAC not working)
**Cause**: RBAC toggle is OFF in database
**Solution**: Check `system_settings` table, set `rbac_enabled = 'true'`

### Issue 3: STAFF can see revenue data
**Cause**: Permission check not implemented or bypassed
**Solution**: Verify `PermissionGateWidget` is wrapping the screen

### Issue 4: Navigation menu doesn't hide items
**Cause**: Navigation filtering not implemented yet
**Solution**: Expected behavior - navigation integration is optional

---

## 📝 Bug Report Template

```markdown
### Bug Report: [Brief Description]

**Role**: OWNER / AREA_MANAGER / STORE_MANAGER / STAFF
**Screen**: Dashboard / Daily Closing / etc.
**RBAC Status**: ON / OFF

**Steps to Reproduce**:
1.
2.
3.

**Expected Behavior**:


**Actual Behavior**:


**Screenshots**: (if applicable)


**Priority**: High / Medium / Low
```

---

**Last Updated**: 2026-02-12
**Status**: Ready for Testing

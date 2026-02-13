# RBAC Production Migration Guide

> **Purpose**: Step-by-step guide for deploying RBAC to production
> **Date**: 2026-02-12
> **Target**: Production Database v11 → v12

---

## ⚠️ Critical Pre-Migration Checklist

Before starting migration, verify:

- [ ] ✅ All Phase 1-5 code merged to main branch
- [ ] ✅ Manual testing completed on all 4 roles
- [ ] ✅ Database backup created
- [ ] ✅ Migration tested on staging environment
- [ ] ✅ Rollback plan prepared
- [ ] ✅ Downtime window scheduled (if needed)
- [ ] ✅ Team notified of migration

---

## 🔄 Migration Overview

### What Changes

1. **Database Schema**: v11 → v12
   - 4 new tables: `permissions`, `role_permissions`, `user_roles`, `store_assignments`
   - 3 new columns in `employees`: `defaultRole`, `storeScope`, `primaryStoreId`
   - 1 new setting: `rbac_enabled` in `system_settings`

2. **Default State After Migration**:
   - ✅ RBAC is **DISABLED** by default (backward compatible)
   - ✅ All existing employees continue working as before
   - ✅ 23 permissions seeded in database
   - ✅ Default role permission templates created

---

## 📋 Migration Steps

### Step 1: Backup Current Database

**CRITICAL**: Always backup before migration!

```bash
# For SQLite (local development)
cp ~/path/to/your/database.db ~/path/to/your/database_backup_$(date +%Y%m%d_%H%M%S).db

# Verify backup
ls -lh ~/path/to/your/database_backup_*.db
```

### Step 2: Run Database Migration

The migration runs automatically when the app starts with the updated code.

**Automatic Migration** (Recommended):
1. Deploy updated app code
2. App detects schema version 11
3. Runs `onUpgrade` to version 12
4. Seeds RBAC permissions
5. Adds new columns to employees table

**Migration Code Reference**:
- File: `lib/database/app_database.dart`
- Method: `onUpgrade(Migrator m, int from, int to)`
- Seeding: `_seedRBACPermissions()`

### Step 3: Verify Migration Success

Run these queries to confirm migration:

```sql
-- 1. Check schema version
SELECT * FROM sqlite_master WHERE type='table';
-- Should see: permissions, role_permissions, user_roles, store_assignments

-- 2. Verify permissions seeded
SELECT COUNT(*) FROM permissions;
-- Expected: 23 permissions

-- 3. Check employee table columns
PRAGMA table_info(employees);
-- Should see: defaultRole, storeScope, primaryStoreId

-- 4. Check RBAC setting
SELECT * FROM system_settings WHERE key = 'rbac_enabled';
-- Expected: value = 'false' (disabled by default)
```

### Step 4: Assign Roles to Existing Employees

**IMPORTANT**: All existing employees default to `STAFF` role with `OWN_STORE` scope.

```sql
-- 1. Find current owner/manager
SELECT id, name, role FROM employees WHERE role = 'MANAGER';

-- 2. Promote to OWNER (typically id = 1)
UPDATE employees
SET defaultRole = 'OWNER',
    storeScope = 'ALL_STORES',
    primaryStoreId = NULL
WHERE id = 1;

-- 3. Assign other managers as STORE_MANAGER
UPDATE employees
SET defaultRole = 'STORE_MANAGER',
    storeScope = 'OWN_STORE',
    primaryStoreId = 'your-store-id'
WHERE id IN (2, 3, 4); -- Replace with actual manager IDs

-- 4. Leave STAFF as default
-- No action needed - already defaulted to STAFF
```

### Step 5: Create Store Assignments (If Using AREA_MANAGER)

If you have Area Managers who oversee multiple stores:

```sql
-- Get Area Manager ID
SELECT id, name FROM employees WHERE defaultRole = 'AREA_MANAGER';

-- Assign stores to Area Manager
INSERT INTO store_assignments (employeeId, storeId, assignedAt)
VALUES
  (2, 'store-001', datetime('now')),
  (2, 'store-002', datetime('now')),
  (2, 'store-003', datetime('now'));
```

### Step 6: Enable RBAC (When Ready)

**Option A: Via UI (Recommended)**
1. Login as OWNER
2. Navigate to Settings → Security Settings
3. Toggle "RBAC (Role-Based Access Control)" to **ON**
4. Confirm the change

**Option B: Via SQL (Direct)**
```sql
UPDATE system_settings
SET value = 'true', updated_at = CURRENT_TIMESTAMP
WHERE key = 'rbac_enabled';
```

### Step 7: Verify RBAC is Working

1. Logout from OWNER account
2. Login as STAFF account
3. Try to access Dashboard
4. **Expected**: "Access Denied" message shown
5. If access is still granted, check:
   - RBAC toggle is ON
   - Employee has `defaultRole = 'STAFF'`
   - Permission cache cleared (app restart)

---

## 🎯 Role Assignment Strategy

### Recommended Role Distribution

| Current Role | Recommended RBAC Role | Reason |
|--------------|----------------------|--------|
| Business Owner | OWNER | Full system access |
| Store Manager | STORE_MANAGER | Can view own store revenue |
| Senior Manager | AREA_MANAGER | Can manage multiple stores |
| Cashier/Staff | STAFF | POS operations only |

### Assignment Commands

```sql
-- Owner
UPDATE employees
SET defaultRole = 'OWNER', storeScope = 'ALL_STORES', primaryStoreId = NULL
WHERE name = 'Owner Name';

-- Store Manager
UPDATE employees
SET defaultRole = 'STORE_MANAGER', storeScope = 'OWN_STORE', primaryStoreId = 'store-001'
WHERE name = 'Manager Name';

-- Area Manager
UPDATE employees
SET defaultRole = 'AREA_MANAGER', storeScope = 'ASSIGNED_STORES', primaryStoreId = NULL
WHERE name = 'Area Manager Name';

-- Staff (default - no change needed)
-- defaultRole = 'STAFF', storeScope = 'OWN_STORE'
```

---

## 🔙 Rollback Plan

### If Migration Fails

**Option 1: Restore from Backup**
```bash
# Stop the app
# Restore backup
cp ~/path/to/your/database_backup_TIMESTAMP.db ~/path/to/your/database.db
# Restart app with old code (v11 schema)
```

**Option 2: Disable RBAC (Keep v12 Schema)**
```sql
-- Disable RBAC, everyone gets full access
UPDATE system_settings
SET value = 'false'
WHERE key = 'rbac_enabled';

-- Verify
SELECT * FROM system_settings WHERE key = 'rbac_enabled';
```

---

## 📊 Post-Migration Monitoring

### Day 1: Monitor These Metrics

1. **Login Success Rate**
   - All employees can still login
   - No authentication issues

2. **Permission Errors**
   - Check for unexpected "Access Denied" messages
   - Verify OWNER has full access

3. **Performance**
   - No noticeable slowdown
   - Permission checks are fast (<50ms)

4. **User Feedback**
   - STAFF understands they can't access revenue
   - Managers can access required features

### Week 1: Verify Stability

- [ ] No crashes related to permission checks
- [ ] RBAC toggle works correctly
- [ ] Role changes apply immediately
- [ ] Store scope filtering works (if multi-store)

---

## 🚨 Common Migration Issues

### Issue 1: All employees have STAFF role after migration

**Cause**: Migration sets default role to STAFF
**Solution**: Manually assign correct roles (see Step 4)

### Issue 2: OWNER can't access Settings

**Cause**: Permission seeding failed or cache issue
**Solution**:
```sql
-- Re-run permission seeding
-- Check permissions table
SELECT COUNT(*) FROM permissions;
-- Should be 23

-- Verify OWNER has all permissions
SELECT * FROM role_permissions WHERE role = 'OWNER';

-- Restart app to clear cache
```

### Issue 3: RBAC toggle not visible

**Cause**: User logged in is not OWNER
**Solution**: Only OWNER can see Security Settings screen

### Issue 4: "Table not found" errors

**Cause**: Migration didn't run completely
**Solution**:
```sql
-- Check schema version
PRAGMA user_version;
-- Should be 12

-- If still 11, migration didn't run
-- Check migration code in app_database.dart
```

---

## ✅ Migration Success Criteria

- [ ] Database schema version is 12
- [ ] 23 permissions exist in `permissions` table
- [ ] All employees have `defaultRole`, `storeScope`, `primaryStoreId` values
- [ ] `rbac_enabled` setting exists in `system_settings`
- [ ] OWNER account works (can login and access all features)
- [ ] STAFF account is blocked from revenue screens when RBAC is ON
- [ ] RBAC toggle works (can enable/disable)
- [ ] No crashes or errors in production logs

---

## 📞 Support & Troubleshooting

### Before Contacting Support

1. Check database backup exists
2. Verify schema version: `PRAGMA user_version;`
3. Check RBAC toggle state: `SELECT * FROM system_settings WHERE key = 'rbac_enabled';`
4. Review migration logs
5. Test with OWNER account first

### Emergency Contacts

- **Technical Lead**: [Contact Info]
- **Database Admin**: [Contact Info]
- **Emergency Rollback Authority**: [Contact Info]

---

## 📝 Migration Checklist

Copy this checklist for your migration:

```
=================================================
RBAC Production Migration Checklist
Date: _______________
Executed By: _______________
=================================================

PRE-MIGRATION
[ ] Code reviewed and approved
[ ] Manual testing completed on staging
[ ] Database backup created
[ ] Team notified
[ ] Downtime window scheduled (if applicable)

MIGRATION
[ ] App deployed with v12 schema code
[ ] Schema migration ran successfully
[ ] Verified 23 permissions seeded
[ ] Verified new columns added to employees
[ ] Assigned OWNER role to owner account(s)
[ ] Assigned STORE_MANAGER to managers
[ ] Created store assignments (if multi-store)
[ ] RBAC toggle verified as OFF initially

POST-MIGRATION
[ ] OWNER can login and access all features
[ ] STAFF can login and use POS
[ ] Database queries return correct results
[ ] No error logs or crashes
[ ] Performance is normal
[ ] Enabled RBAC (when ready)
[ ] STAFF blocked from revenue screens
[ ] Role permission tests passed

ROLLBACK (If Needed)
[ ] Backup restored successfully
[ ] OR RBAC disabled via SQL
[ ] App functionality verified
[ ] Issue documented for future fix

=================================================
Status: [ ] SUCCESS  [ ] FAILED  [ ] ROLLED BACK
Notes: __________________________________________
=================================================
```

---

**Last Updated**: 2026-02-12
**Status**: Ready for Production Migration
**Recommended Timeline**: Test migration on staging first, then production during low-traffic hours

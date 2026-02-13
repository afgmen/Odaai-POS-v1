-- ============================================================
-- Quick Start: Enable RBAC Feature
-- ============================================================
-- This script enables RBAC and assigns proper roles to users
-- Run this directly in your SQLite database

-- Step 1: Enable RBAC System
-- ============================================================
UPDATE system_settings
SET value = 'true', updated_at = CURRENT_TIMESTAMP
WHERE key = 'rbac_enabled';

-- Verify RBAC is enabled
SELECT key, value FROM system_settings WHERE key = 'rbac_enabled';

-- Step 2: Assign OWNER Role to Current User
-- ============================================================
-- Update the first employee (typically the owner) to have OWNER role
UPDATE employees
SET defaultRole = 'OWNER',
    storeScope = 'ALL_STORES',
    primaryStoreId = NULL
WHERE id = 1;

-- Verify role assignment
SELECT id, name, defaultRole, storeScope FROM employees WHERE id = 1;

-- Step 3: Check Permissions are Seeded
-- ============================================================
-- Should return 23 permissions
SELECT COUNT(*) as permission_count FROM permissions;

-- View all permissions
SELECT module, name, description FROM permissions ORDER BY module, name;

-- Step 4: Verify RBAC is Working
-- ============================================================
-- After running this script:
-- 1. Restart your app
-- 2. Login with the OWNER account
-- 3. Go to Settings → Security (new section at the top)
-- 4. You should see the RBAC toggle (should show "Enabled")

-- ============================================================
-- Optional: Create Test Accounts (For Testing)
-- ============================================================

-- Create STAFF test account (PIN: 4444)
-- This account will NOT be able to see revenue screens when RBAC is ON
/*
INSERT INTO employees (name, pin, role, is_active, defaultRole, storeScope, primaryStoreId, created_at)
VALUES ('Test Staff', '4444', 'CASHIER', 1, 'STAFF', 'OWN_STORE', 'store-001', datetime('now'));
*/

-- ============================================================
-- Rollback (if needed)
-- ============================================================
-- To disable RBAC and restore full access for everyone:
/*
UPDATE system_settings
SET value = 'false', updated_at = CURRENT_TIMESTAMP
WHERE key = 'rbac_enabled';
*/

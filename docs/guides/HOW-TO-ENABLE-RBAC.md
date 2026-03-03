# How to Enable RBAC (Quick Guide)

> **Time Required**: 2 minutes
> **Difficulty**: Easy

---

## 🎯 What You'll Get

After enabling RBAC:
- ✅ Security Settings screen appears in Settings menu (Owner only)
- ✅ RBAC toggle control to enable/disable permissions
- ✅ Role-based access control for revenue screens
- ✅ STAFF users cannot see financial data

---

## 📋 3-Step Activation

### Step 1: Run SQL Script (30 seconds)

1. **Locate your database file**:
   - Usually at: `~/Library/Application Support/com.example.odaPos/app.db`
   - Or check your app's data directory

2. **Open with SQLite**:
   ```bash
   sqlite3 ~/path/to/your/app.db
   ```

3. **Run this command**:
   ```sql
   UPDATE system_settings
   SET value = 'true', updated_at = CURRENT_TIMESTAMP
   WHERE key = 'rbac_enabled';

   -- Also set yourself as OWNER
   UPDATE employees
   SET defaultRole = 'OWNER',
       storeScope = 'ALL_STORES',
       primaryStoreId = NULL
   WHERE id = 1;

   .quit
   ```

   **OR** use the provided script:
   ```bash
   sqlite3 ~/path/to/your/app.db < docs/enable-rbac-quick-start.sql
   ```

### Step 2: Restart App (30 seconds)

1. **Close the app completely**
2. **Restart it**
3. **Login** with your OWNER account

### Step 3: Verify It Works (1 minute)

1. **Go to Settings**
2. **Look for "Security" section** at the top (before "App Info")
3. **Click "RBAC Settings"**
4. **You should see**:
   - ✅ "RBAC (Role-Based Access Control)" toggle
   - ✅ Status: "RBAC가 활성화됨" (RBAC is enabled)
   - ✅ Role descriptions

---

## 🧪 Quick Test

Want to see RBAC in action?

1. **Create a test STAFF account**:
   ```sql
   INSERT INTO employees (name, pin, role, is_active, defaultRole, storeScope, created_at)
   VALUES ('Test Staff', '4444', 'CASHIER', 1, 'STAFF', 'OWN_STORE', datetime('now'));
   ```

2. **Logout from OWNER account**

3. **Login as STAFF** (PIN: 4444)

4. **Try to access**:
   - ❌ Dashboard → Should show "Access Denied"
   - ❌ Daily Closing → Should show "Access Denied"
   - ❌ Reports → Should show "Access Denied"
   - ❌ Sales History → Should show "Access Denied"
   - ❌ Employee Management → Should show "Access Denied"
   - ✅ POS → Should work normally

5. **Login back as OWNER**

6. **Toggle RBAC OFF** in Security Settings

7. **Login as STAFF again**
   - ✅ Now ALL screens should be accessible

---

## 🔍 Troubleshooting

### "Security section doesn't appear in Settings"

**Cause**: You're not logged in as OWNER

**Solution**:
1. Check your employee role in database:
   ```sql
   SELECT id, name, defaultRole FROM employees WHERE id = 1;
   ```
2. Should show `defaultRole = 'OWNER'`
3. If not, run Step 1 SQL script again

### "RBAC toggle shows OFF but I enabled it"

**Cause**: App cache issue

**Solution**:
1. Completely close and restart the app
2. If still OFF, run this SQL again:
   ```sql
   UPDATE system_settings SET value = 'true' WHERE key = 'rbac_enabled';
   ```

### "Payment still fails with 'No employee logged in'"

**Cause**: This was fixed in the auth_provider.dart

**Solution**:
1. Restart the app
2. The fix should automatically work
3. If still failing, check you're logged in (session exists)

---

## 📚 Next Steps

Once RBAC is enabled:

1. **Assign Roles**: Update employees' `defaultRole` field
   - OWNER: Full access
   - AREA_MANAGER: Multi-store manager
   - STORE_MANAGER: Single store manager
   - STAFF: POS operations only

2. **Customize Permissions**: Use Security Settings screen to modify role permissions

3. **Test Each Role**: Create test accounts and verify permissions work correctly

4. **Read Full Docs**: See `docs/rbac-testing-guide.md` for comprehensive testing

---

## 🎉 Success Checklist

- [ ] RBAC enabled in database
- [ ] App restarted
- [ ] Security section visible in Settings (as OWNER)
- [ ] RBAC toggle shows "Enabled"
- [ ] STAFF account cannot access revenue screens
- [ ] OWNER account has full access

---

**Last Updated**: 2026-02-12
**Quick Enable**: Just run the SQL script and restart! 🚀

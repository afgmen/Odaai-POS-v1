# Quick RBAC Status Check

## 🔍 How to Check if RBAC is Enabled

### Method 1: In the App (Easiest)

1. **Open the app**
2. **Go to Settings screen**
3. **Look at the top**:

   **If you see a blue box with "Enable RBAC Security"**:
   - ✅ RBAC is currently **DISABLED**
   - 👉 Click the button to enable it!

   **If you DON'T see the blue box**:
   - ✅ RBAC is already **ENABLED**
   - 👉 Look for "Security" section to manage it

---

## 🚀 To Enable RBAC (One Click!)

### From Settings Screen:

1. Go to **Settings**
2. See the blue **"Enable RBAC Security"** card at the top
3. Click **"Enable RBAC Now"** button
4. Confirm the dialog
5. App will restart automatically
6. Done! You're now OWNER with full access 🎉

After restart:
- ✅ You'll see "Security" section in Settings
- ✅ You can manage RBAC toggle
- ✅ You can test with different roles

---

## 📱 What You'll See

### Before Enabling:
```
Settings Screen
┌─────────────────────────────────────┐
│  🛡️  Enable RBAC Security           │
│  Role-Based Access Control          │
│                                     │
│  ✅ Control who can see revenue     │
│  ✅ Manage employee permissions     │
│  ✅ Set yourself as OWNER           │
│                                     │
│  [Enable RBAC Now]                  │
└─────────────────────────────────────┘

Language & Currency
...
```

### After Enabling & Restart:
```
Settings Screen

Language & Currency
...

Store Information
...

Receipt Settings
...

🛡️ Security                    ← NEW!
┌─────────────────────────────────────┐
│  RBAC Settings                      │
│  Manage Permissions              →  │
└─────────────────────────────────────┘

App Information
...
```

---

## 🧪 Testing After Enable

1. **Check you're OWNER**:
   - Go to Settings → Security → RBAC Settings
   - Toggle should show "RBAC가 활성화됨"

2. **Create test STAFF**:
   - Use Employee Management screen
   - Create employee with PIN 4444
   - Set role to STAFF

3. **Test STAFF permissions**:
   - Logout
   - Login as STAFF (PIN 4444)
   - Try Dashboard → Should show "Access Denied" ❌
   - Try POS → Should work fine ✅

4. **Toggle RBAC OFF/ON**:
   - Login as OWNER
   - Go to Security Settings
   - Toggle RBAC OFF
   - Login as STAFF → Everything accessible
   - Toggle RBAC ON
   - Login as STAFF → Revenue blocked again

---

## ⚠️ Troubleshooting

### "I clicked Enable but nothing happened"

**Solution**:
- Check for error message
- Restart the app manually
- The button should disappear after enable

### "The blue button is gone but no Security section"

**Solution**:
- Restart the app completely (close and reopen)
- Make sure you're logged in
- Check you're set as OWNER (button sets this automatically)

### "I want to disable RBAC again"

**Solution**:
1. Go to Security Settings
2. Toggle RBAC OFF
3. Everyone gets full access again

---

**Super Simple**: Just click the blue "Enable RBAC Now" button in Settings! 🚀

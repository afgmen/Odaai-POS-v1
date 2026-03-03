# Where to Find "Set as OWNER" Button

## ⚠️ Important: Security Section is Hidden Until You're OWNER

The "Security" section in Settings is **intentionally hidden** by the `OwnerOnly` widget until you have the OWNER role.

## ✅ Correct Path: Employee Management

### Step 1: Navigate to Employee Management
```
Sidebar → Employees (👥 icon)
```

### Step 2: Look for the Blue Tip Banner
At the top of the Employee Management screen, you'll see:
```
┌────────────────────────────────────────────────────────┐
│ ℹ️  💡 Tip: Click "Set as OWNER" button on any        │
│    employee card below to enable RBAC security         │
└────────────────────────────────────────────────────────┘
```

### Step 3: Find Your Employee Card
Each employee card will show:
```
┌─────────────────────────────┐
│  Administrator              │
│  📧 admin@company.com       │
│  PIN: ****                  │
│  🛡️ Role: ADMIN            │
│  ✅ Active                  │
│                             │
│  ┌───────────────────────┐ │
│  │ 🛡️ Set as OWNER       │ │  ← CLICK THIS BUTTON
│  │ (Enable RBAC)          │ │
│  └───────────────────────┘ │
└─────────────────────────────┘
```

### Step 4: Click "Set as OWNER" Button
- Blue button with shield icon (🛡️)
- Located at the bottom of each employee card
- Will show a confirmation dialog

### Step 5: Confirm and Restart
1. Click "Set as OWNER" in the confirmation dialog
2. Click "Restart Now" when prompted
3. App will restart automatically

### Step 6: Verify in Settings
After restart, go to:
```
Settings → Security → RBAC Settings
```

Now the Security section will be visible because you're OWNER!

## ❌ Why Settings Doesn't Show Security Yet

```dart
// In settings_screen.dart
OwnerOnly(  // ← This widget checks if you're OWNER
  child: Column(
    children: [
      _SectionHeader(title: 'Security', icon: Icons.security),
      // ... Security section content
    ],
  ),
)
```

The `OwnerOnly` widget returns `SizedBox.shrink()` (invisible) if:
- RBAC is disabled, OR
- Your current role is not OWNER

That's why you need to use the "Set as OWNER" button in Employee Management first!

## 🔍 Visual Flow

```
Current State:
├─ RBAC: Disabled
├─ Your Role: ADMIN (not OWNER)
└─ Security Section: Hidden by OwnerOnly widget

Action Required:
├─ Go to Employee Management
├─ Click "Set as OWNER" button on your card
└─ Restart app

After Restart:
├─ RBAC: Enabled
├─ Your Role: OWNER
└─ Security Section: ✅ Visible in Settings!
```

## 📸 Expected Screenshots

### Before (Current State):
Settings screen shows:
- ⚙️ General
- 📊 Data & Backup
- ❌ Security (HIDDEN - you're here looking for this!)

### After (OWNER State):
Settings screen shows:
- ⚙️ General
- 📊 Data & Backup
- 🔒 Security ← NOW VISIBLE!
  - RBAC Settings

## 🚨 Troubleshooting

**Q: I still don't see the "Set as OWNER" button in Employee Management**
A: Make sure the app has restarted after the code changes. Stop the app completely and run `flutter run -d macos` again.

**Q: I clicked the button but Security section still doesn't appear**
A: Did you restart the app after clicking? The app MUST be restarted for the role change to take effect.

**Q: Can I use SQL to enable it instead?**
A: Yes, but the button is easier. If you prefer SQL, see `docs/enable-rbac-quick-start.sql`

## 📝 Summary

1. ❌ DON'T look in Settings for Security section (it's hidden)
2. ✅ DO go to Employee Management
3. ✅ DO click "Set as OWNER" button on your employee card
4. ✅ DO restart the app when prompted
5. ✅ THEN go to Settings → Security

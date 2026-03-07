# Language Consistency Migration Plan (B-083)

## Problem
Mixed language usage in UI (English + Vietnamese hardcoded strings)

## Current State
- ✅ i18n system exists (Flutter intl)
- ✅ English (app_en.arb) and Vietnamese (app_vi.arb) support
- ❌ Many hardcoded English strings found
- ❌ Inconsistent usage of l10n

## Hardcoded Strings Found

### High Priority (User-Facing)
```
lib/features/attendance/presentation/screens/leave_request_screen.dart:
- "Leave Management"
- "Request Submitted"
- "Your leave request has been submitted.\nIt will be confirmed after manager approval."
- "OK"
- "Notice"
- "Please log in."
- "Unable to load leave information."
- "An error occurred: ..."

lib/features/attendance/presentation/screens/attendance_admin_dashboard_screen.dart:
- "Attendance Management"
- "View All"

lib/features/attendance/presentation/screens/leave_approval_screen.dart:
- "Leave Approval"
- "Reject Leave"
- "Reject this leave request?"
- "Cancel"
```

## Migration Steps

### Phase 1: Add Missing Keys
Add to `app_en.arb` and `app_vi.arb`:
```json
{
  "leaveManagement": "Leave Management",
  "requestSubmitted": "Request Submitted",
  "requestSubmittedMessage": "Your leave request has been submitted.\nIt will be confirmed after manager approval.",
  "notice": "Notice",
  "pleaseLogIn": "Please log in.",
  "unableToLoadLeaveInfo": "Unable to load leave information.",
  "errorOccurred": "An error occurred",
  "attendanceManagement": "Attendance Management",
  "viewAll": "View All",
  "leaveApproval": "Leave Approval",
  "rejectLeave": "Reject Leave",
  "rejectLeaveConfirmation": "Reject this leave request?"
}
```

### Phase 2: Replace Hardcoded Strings
Example:
```dart
// BEFORE:
Text('Leave Management')

// AFTER:
Text(l10n.leaveManagement)
```

### Phase 3: Verify
Run automated test to detect remaining hardcoded strings:
```bash
grep -r "Text('" lib/ --include="*.dart" | grep -v "l10n\."
```

## Migration Script (Automated)

```bash
# Find all hardcoded Text() widgets
find lib -name "*.dart" -exec grep -H "Text('.*')" {} \;

# Count hardcoded strings
grep -r "Text('" lib --include="*.dart" | wc -l
```

## Testing Strategy
- 13 unit tests created (✅ all passing)
- Manual UI testing required
- Screenshot comparison before/after

## Estimated Effort
- ARB file updates: 1h
- Code refactoring: 4h
- Testing & verification: 1h
- **Total: 6h**

## Success Criteria
✅ No hardcoded strings in user-facing UI
✅ All text uses l10n system
✅ Consistent language across all screens
✅ Both EN and VI translations complete

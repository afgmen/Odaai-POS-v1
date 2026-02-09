# Oda POS - Manual Testing Guide

## 🚀 Getting Started

### 1. Run the Application

```bash
cd /Users/JINLee/Documents/AI-coding/Odaai-POS/oda_pos
flutter run
```

### 2. Default Language
- ✅ The app now starts in **English** by default
- You can change language in Settings if needed

---

## 📋 Feature Testing Checklist

### Phase 1: Authentication & Basic Setup

#### Test 1.1: PIN Login
- [ ] Launch app
- [ ] See PIN login screen
- [ ] Enter correct PIN (check database or create new user)
- [ ] Login successful → Navigate to main screen

---

### Phase 2: Customer Loyalty Program

#### Test 2.1: Point System
- [ ] Go to POS screen
- [ ] Select a customer
- [ ] Add products to cart
- [ ] Complete sale
- [ ] **Verify**: Customer earns points (1% of total)
- [ ] Check customer profile → Points balance updated

#### Test 2.2: Point Redemption
- [ ] Select customer with points
- [ ] Click "Use Points" button
- [ ] Enter points to redeem
- [ ] Complete sale
- [ ] **Verify**: Points deducted correctly
- [ ] **Verify**: Final total = Original - Points used

#### Test 2.3: Membership Tiers
- [ ] Go to Loyalty Dashboard
- [ ] View tier distribution (Bronze/Silver/Gold/Platinum)
- [ ] Check customer with different spending levels
- [ ] **Verify**: Tier upgrades based on total_spent
  - Bronze: $0+
  - Silver: $100,000+
  - Gold: $500,000+
  - Platinum: $1,000,000+

#### Test 2.4: Birthday Customers
- [ ] Go to Loyalty Dashboard
- [ ] Check "Birthday Customers This Month"
- [ ] **Verify**: Shows customers with birthdays
- [ ] **Verify**: Can send birthday messages

---

### Phase 3: Employee Attendance Management

#### Test 3.1: Check-In (Employee Screen)
- [ ] Login as employee
- [ ] Go to Attendance Check screen
- [ ] **Verify**: Shows current time (updates every second)
- [ ] **Verify**: Shows today's schedule (09:00 ~ 18:00)
- [ ] Click "Check In" button
- [ ] **Verify**: Status changes to "Working"
- [ ] **Verify**: Check-in time recorded
- [ ] **Late Test**: Check in after 09:15 → Should show "Late" badge

#### Test 3.2: Check-Out (Employee Screen)
- [ ] After checking in, click "Check Out" button
- [ ] **Verify**: Shows total work hours
- [ ] **Verify**: Calculates overtime if worked > scheduled hours
- [ ] **Verify**: Status changes to "Completed"
- [ ] **Early Leave Test**: Check out before 17:30 → Should show "Early Leave"

#### Test 3.3: Attendance History
- [ ] Go to Attendance History screen
- [ ] **Verify**: Shows monthly records
- [ ] Click month selector → Change to different month
- [ ] **Verify**: Records updated for selected month
- [ ] Click on a record → See detailed info
- [ ] **Verify**: Shows check-in/out times, work hours, late/early flags

#### Test 3.4: Leave Request (Employee Screen)
- [ ] Go to Leave Request screen
- [ ] See "Request Leave" and "Request History" tabs
- [ ] **Verify**: Shows leave balance (Annual: 15, Sick: 5, Personal: 3)
- [ ] Select leave type: Annual Leave
- [ ] Select start date and end date
- [ ] **Verify**: Auto-calculates days (excludes weekends)
- [ ] Enter reason
- [ ] Click "Submit"
- [ ] **Verify**: Request appears in "Request History" with "Pending" status

#### Test 3.5: Admin Dashboard
- [ ] Login as admin/manager
- [ ] Go to Attendance Admin Dashboard
- [ ] **Today's Status Card**:
  - [ ] Shows total employees
  - [ ] Shows working count
  - [ ] Shows checked-out count
  - [ ] Shows late count
  - [ ] Shows absent count
- [ ] **Pending Approvals**:
  - [ ] Shows leave requests awaiting approval
  - [ ] Click to go to approval screen
- [ ] **Attention Required**:
  - [ ] Shows employees late today
  - [ ] Shows employees with 3+ lates this month
- [ ] **All Employees Status**:
  - [ ] Lists all employees with current status
  - [ ] Click employee → Go to detail screen

#### Test 3.6: Employee Detail (Admin)
- [ ] From dashboard, click an employee
- [ ] **Summary Tab**:
  - [ ] Shows employee info (name, role, active status)
  - [ ] Shows monthly statistics:
    - Attendance days vs total workdays
    - Total work hours
    - Overtime hours
    - Late/Early leave/Absent counts
  - [ ] Shows status distribution chart
- [ ] **Attendance Records Tab**:
  - [ ] Lists all attendance records for selected month
  - [ ] Shows check-in/out times
  - [ ] Shows late/early leave badges
  - [ ] Shows total work hours per day
- [ ] **Leave Status Tab**:
  - [ ] Shows leave balance with progress bars
  - [ ] Shows leave request history
  - [ ] Shows approval status for each request

#### Test 3.7: Leave Approval (Admin)
- [ ] Go to Leave Approval screen
- [ ] See pending leave requests
- [ ] For each request card:
  - [ ] Shows employee name and photo
  - [ ] Shows leave type and dates
  - [ ] Shows reason
  - [ ] Shows remaining leave days
  - [ ] **Warning**: Red alert if insufficient leave balance
- [ ] Click "Reject":
  - [ ] Enter rejection reason (optional)
  - [ ] Confirm
  - [ ] **Verify**: Request status changes to "Rejected"
- [ ] Click "Approve":
  - [ ] Confirm approval
  - [ ] **Verify**: Request status changes to "Approved"
  - [ ] **Verify**: Leave balance decreased
  - [ ] **Verify**: Absent logs created for leave period

---

### Phase 4: Cloud Backup System (Phase 1 completed)

#### Test 4.1: Manual Backup
- [ ] Go to Settings → Backup
- [ ] Click "Create Backup Now"
- [ ] **Verify**: Backup starts
- [ ] **Verify**: Progress indicator shows
- [ ] **Verify**: Backup log created with:
  - File name with timestamp
  - File size
  - Record count
  - SHA-256 checksum
  - Status: "completed"

#### Test 4.2: Backup History
- [ ] View backup logs
- [ ] **Verify**: Shows recent backups (max 30)
- [ ] **Verify**: Each entry shows:
  - Backup date/time
  - File size
  - Status (completed/failed)
  - Checksum

---

## 🧪 Advanced Testing Scenarios

### Scenario A: Full Employee Workflow (1 Day)
1. **Morning Check-In** (09:00)
   - Employee checks in on time
   - Status: Working
2. **Work During Day**
   - System tracks time automatically
3. **Evening Check-Out** (18:30)
   - Employee checks out
   - Total: 9 hours 30 minutes
   - Regular: 8 hours
   - Overtime: 1 hour 30 minutes
4. **View History**
   - Employee sees completed attendance record
   - All times and calculations correct

### Scenario B: Leave Request Workflow
1. **Employee Requests Leave**
   - Annual leave: 2024-03-01 ~ 2024-03-03 (3 days)
   - Reason: "Family vacation"
   - Status: Pending
2. **Admin Reviews**
   - Sees request in dashboard
   - Checks employee leave balance (15 days)
   - Approves request
3. **System Auto-Processing**
   - Leave balance: 15 → 12 days
   - Creates absent logs for 3/1, 3/2, 3/3
   - Employee receives approval notification
4. **During Leave Period**
   - Employee doesn't check in (expected)
   - Attendance shows "Absent" status
   - No late/early leave flags

### Scenario C: Late Employee Detection
1. **Employee Late** (09:20 check-in)
   - System marks as late (>15 min threshold)
   - Late badge appears
2. **Admin Dashboard**
   - Shows in "Attention Required" section
   - Highlights employee name
3. **Monthly Report**
   - Late count: +1
   - Admin can review pattern

### Scenario D: Point Earning & Redemption
1. **Customer Makes Purchase**
   - Total: $100
   - Points earned: 100 (1% rate for Bronze tier)
   - New balance: Previous + 100
2. **Customer Redeems Points**
   - Has 500 points
   - Uses 50 points on next purchase
   - Total: $60 → Final: $50 (after 50 point discount)
   - New balance: 450 points
3. **Tier Upgrade**
   - Customer reaches $100,000 total spent
   - Auto-upgrade to Silver tier
   - New point rate: 1.5%

---

## 🐛 Known Issues & Edge Cases to Test

### Edge Case 1: Midnight Check-Out
- Employee checks in at 23:30
- Works past midnight to 01:00
- **Verify**: Correctly calculates 1.5 hours work time
- **Verify**: Night shift hours counted (22:00~06:00)

### Edge Case 2: Weekend Leave Request
- Employee requests leave: Friday ~ Monday (4 days)
- **Verify**: System calculates 2 working days (Fri, Mon)
- **Verify**: Weekend (Sat, Sun) not counted

### Edge Case 3: Insufficient Leave Balance
- Employee has 1 day annual leave remaining
- Requests 3 days leave
- **Verify**: Request shows warning in admin screen
- **Verify**: Admin sees "Insufficient balance" alert

### Edge Case 4: Duplicate Check-In
- Employee already checked in
- Tries to check in again
- **Verify**: System shows error "Already checked in today"

---

## 📊 Data Verification

### Database Check
After testing, verify data in SQLite:

```bash
# Open database
sqlite3 oda_pos.db

# Check attendance logs
SELECT * FROM attendance_logs ORDER BY created_at DESC LIMIT 10;

# Check leave requests
SELECT * FROM leave_requests WHERE status = 'pending';

# Check leave balances
SELECT e.name, lb.*
FROM leave_balances lb
JOIN employees e ON lb.employee_id = e.id;

# Check point transactions
SELECT c.name, pt.*
FROM point_transactions pt
JOIN customers c ON pt.customer_id = c.id
ORDER BY pt.created_at DESC LIMIT 10;

# Check backup logs
SELECT * FROM backup_logs ORDER BY created_at DESC LIMIT 5;
```

---

## ✅ Success Criteria

### Attendance System
- ✅ Check-in/out works correctly
- ✅ Late detection accurate (>15 min)
- ✅ Early leave detection accurate (<30 min)
- ✅ Work hours calculated correctly
- ✅ Overtime calculated correctly
- ✅ Leave request workflow complete
- ✅ Leave balance updates correctly
- ✅ Admin dashboard shows real-time status
- ✅ All screens responsive and error-free

### Loyalty Program
- ✅ Points earned automatically
- ✅ Points redeemed correctly
- ✅ Tier upgrades automatic
- ✅ Birthday detection works
- ✅ Dashboard statistics accurate

### Backup System
- ✅ Manual backup creates file
- ✅ Checksum generated correctly
- ✅ Metadata recorded
- ✅ Old backups cleaned up (>30)

---

## 🔍 Performance Testing

### Load Test Scenarios
1. **100+ Employees Check-In**
   - Create 100 test employees
   - Simulate bulk check-in
   - **Verify**: No lag, all records created

2. **1000+ Point Transactions**
   - Create 1000 sales with points
   - **Verify**: Dashboard loads quickly
   - **Verify**: Queries optimized with indexes

3. **Monthly Report Generation**
   - Generate report for employee with 30+ attendance records
   - **Verify**: Loads in <2 seconds
   - **Verify**: Calculations accurate

---

## 📱 UI/UX Testing

### Mobile Responsiveness
- [ ] Test on different screen sizes
- [ ] Buttons large enough for touch (min 44x44)
- [ ] Text readable (min 14sp for body)
- [ ] Cards have proper spacing
- [ ] Lists scroll smoothly

### Accessibility
- [ ] Color contrast sufficient
- [ ] Icons have labels
- [ ] Error messages clear
- [ ] Success feedback visible

---

## 🚨 Critical Bugs to Watch For

1. **Attendance**
   - ❌ Check-in without schedule → Should show error
   - ❌ Check-out without check-in → Should show error
   - ❌ Negative work hours → Should never happen

2. **Leave Management**
   - ❌ Approve with insufficient balance → Should warn
   - ❌ Overlapping leave requests → Should prevent

3. **Points**
   - ❌ Negative points balance → Should prevent
   - ❌ Redeem more than balance → Should show error

4. **Data Integrity**
   - ❌ Orphaned records (employee deleted but attendance remains)
   - ❌ Missing foreign key constraints
   - ❌ Concurrent updates causing race conditions

---

## 📞 Support & Troubleshooting

### Common Issues

**Issue**: App won't start
- **Solution**: Run `flutter clean && flutter pub get`

**Issue**: Database errors
- **Solution**: Delete app data and reinstall (dev only)

**Issue**: Attendance not recording
- **Solution**: Check employee has active schedule for today

**Issue**: Leave approval doesn't work
- **Solution**: Verify admin has proper permissions

---

## 📝 Test Report Template

```
Test Date: _______________
Tester: _______________
App Version: _______________

Features Tested:
[ ] Authentication
[ ] Loyalty Program
[ ] Attendance Check-In/Out
[ ] Leave Request
[ ] Admin Dashboard
[ ] Leave Approval
[ ] Backup System

Bugs Found:
1. [Description] - [Severity: High/Medium/Low]
2. ...

Overall Status: [ ] PASS  [ ] FAIL

Notes:
_______________
```

---

**Happy Testing! 🚀**

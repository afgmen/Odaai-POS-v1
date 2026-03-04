# Odaai POS v1.0

**Flutter Desktop POS System** for restaurants and cafes

## Overview

Odaai POS is a comprehensive, offline-first Point of Sale system built with Flutter Desktop. It features real-time Kitchen Display System (KDS), floor plan management, delivery integration, and advanced Role-Based Access Control (RBAC).

**Current Version:** 1.0.0+1  
**DB Schema Version:** v22  
**Total Tests:** 538 passing  
**Platforms:** macOS, Windows, Linux

## Key Features (29)

### Core POS Features
1. **POS Main Screen** - Multi-order type support (Dine-in, Takeaway, Phone Delivery, Platform Delivery)
2. **Category Management** - Hierarchical category system with CRUD operations (P0-1, 2026-03-02)
3. **Product Management** - Full product catalog with images, barcodes, stock tracking
4. **Product Modifiers** - Customizable options and toppings with 4-table system (P1-3, 2026-03-02)
5. **Tax/VAT System** - Inclusive/Exclusive tax calculation (P0-2, 2026-03-02)
6. **Payment Processing** - Cash, Card, and Mixed payment methods
7. **Split Bill** - Even split for 2-10 people (P1-4, 2026-03-02)
8. **Barcode Scanning** - Quick product lookup

### Kitchen Operations
9. **Kitchen Display System (KDS)** - Real-time order management with 5-status workflow
10. **KDS View Toggle** - Order View ↔ Menu Summary full screen switching (P1-5, 2026-03-02)
11. **KDS Status Filters** - All 5 statuses (Pending, Preparing, Ready, Served, Cancelled) (P2-7, 2026-03-02)
12. **Order Priority** - Normal/Urgent marking
13. **Real-time Notifications** - Audio alerts for new orders

### Floor Plan & Table Management
14. **Floor Plan Designer** - Drag-and-drop table layout with zones
15. **Floor Plan Operational View** - 7-status color coding with real-time sync
16. **Table Management** - Table reservations, assignments, and status tracking
17. **Table Merge** - Combine multiple tables (P2-6, 2026-03-02)
18. **Table Move** - Transfer table assignments
19. **Zone Management** - Organize tables by zones (VIP, Outdoor, etc.)

### Delivery & Customer Management
20. **Phone Delivery** - Phone order entry with customer auto-lookup
21. **Delivery Management** - Delivery address, COD/prepaid payment
22. **Customer Management** - Customer registration, order history
23. **Platform Delivery Integration** - Webhook support for external platforms

### Staff & Operations
24. **RBAC System** - 4 roles (Owner, Area Manager, Store Manager, Staff) with granular permissions
25. **Attendance Management** - Check-in/out, leave requests, work schedules, GPS integration
26. **Employee Management** - Staff registration, role assignment, store assignment
27. **Daily Closing** - Automated cash/card reconciliation with PDF reports

### Reporting & Analytics
28. **Dashboard** - Real-time sales, order count, inventory alerts
29. **Reports** - Weekly/monthly sales, popular items, staff performance

## Recent Updates (2026-03-02)

### Employee Feedback-Driven Improvements

**P0-1: Category Management (P0, Mandatory)**
- Hierarchical category system with CRUD operations
- Categories table with localization (name, nameEn, nameVi)
- Category color and icon customization
- Integration with POS CategoryFilter and Product Management
- DB Migration: v20 → v21

**P0-2: Tax/VAT System (P0, Mandatory)**
- Settings: taxEnabled, taxRate, taxInclusive (inclusive/exclusive toggle)
- Tax calculation provider for real-time updates
- Cart total with tax breakdown
- Payment modal VAT display
- Receipt PDF tax line item

**P1-3: Product Modifier System (P1, High Priority)**
- 4-table architecture: ModifierGroups, ModifierOptions, ProductModifierLinks, SaleItemModifiers
- Full CRUD with ModifierDao
- ModifierSelectionModal with required/multi-select support
- Cart panel modifier display
- Receipt and sale storage with modifiers
- DB Migration: v21 → v22

**P1-4: Split Bill (P1, High Priority)**
- SplitBillModal with even split for 2-10 people
- Creates N sub-sales with equal amounts
- Integration with PaymentModal

**P1-5: KDS View Toggle (P1, High Priority)**
- Order View ↔ Menu Summary full screen switching
- Improved kitchen workflow efficiency

**P2-6: Table Merge (P2, Medium Priority)**
- TableMergeModal for combining multiple tables
- Moves all sale items between tables
- Updates totals and marks source table as available

**P2-7: KDS 5-Status Filter (P2, Medium Priority)**
- All 5 order statuses filterable (Pending, Preparing, Ready, Served, Cancelled)
- Complete workflow support

## Tech Stack

- **Framework:** Flutter 3.10.8+ (Desktop)
- **Language:** Dart 3.10.8+
- **Database:** Drift (SQLite ORM) - Schema v22
- **State Management:** Riverpod 2.5.1
- **Localization:** flutter_localizations + intl (3 languages: EN, KO, VI)
- **Multi-Currency:** KRW, USD, VND
- **PDF Generation:** pdf + printing packages
- **Barcode:** mobile_scanner
- **Audio:** audioplayers (KDS alerts)

## Database Schema

- **Schema Version:** v22
- **Total Tables:** 40+
- **Key Tables:** Sales, SaleItems, Products, Categories, ModifierGroups, ModifierOptions, ProductModifierLinks, SaleItemModifiers, KitchenOrders, StoreTables, FloorZones, Employees, AttendanceLogs, Permissions, DailyClosings, Promotions, Loyalty

**Recent Migrations:**
- v20 → v21: Category system (Products.categoryId FK)
- v21 → v22: Product Modifier system (4 new tables)

## Testing

- **Total Tests:** 538
- **Status:** All passing ✅
- **Test Command:** `flutter test`
- **Analysis:** `flutter analyze` (0 errors)

## Installation

### Prerequisites
- Flutter SDK 3.10.8+
- Dart SDK 3.10.8+
- macOS / Windows / Linux

### Steps
1. Clone the repository
2. Run `flutter pub get`
3. Run `flutter run -d macos` (or windows/linux)
4. Default login PIN: 1234 (Owner role)

## Documentation

- **PRD:** `docs/prd/product-prd.md`
- **UX Phases:** `docs/prd/ux-phases.md`
- **Feature Plans:** `docs/plan/features/*.plan.md`
- **Design Docs:** `docs/design/features/*.design.md`

## License

© 2026 Odaai. All rights reserved.

---

**Last Updated:** 2026-03-04  
**Document Version:** 1.0.0

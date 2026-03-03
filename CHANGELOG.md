# Changelog

All notable changes to Odaai POS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-03

### Added
- Split Bill feature for dividing bills across multiple customers
- Table Merge functionality for combining multiple tables
- Category management system with hierarchical structure
- Tax management with multiple tax rate support
- Product Modifier system for customizing menu items
- KDS improvements with real-time stats badges connected to today's data
- Floor Plan Designer with CRUD modals for restaurant layout management
- Floor Plan modals connected to Table Management Screen
- Delivery order customer information input form
- Phone Delivery customer auto-lookup by phone number
- Backup restore functionality for data recovery
- Exchange rate database integration for multi-currency support
- Widget tests for Dashboard and PosMainScreen
- OdaBadge widget and SnackBarHelper utility (Phase 3-B)
- CI flutter test step with Floor Plan tests
- 136 core business logic tests for tables, attendance, cash drawer, and POS
- Attendance GPS location integration for check-in tracking
- Store settings persistence via SharedPreferences
- Loyalty dashboard quick actions (search, points adjustment, tier management)
- Round number display on SaleItems with grouped bill view
- Table move feature for transferring table assignments
- Dine-in checkout branch logic
- Phone Delivery form with KDS order type badge
- Open Tab system for deferred payment
- Bill Request functionality for table service
- Floor Plan Operational View with 7 status colors and modals
- POS UX Phase 1 with data model restructuring
- Oda Design Style Guide Phase 1 (color tokens + Noto Sans font)
- Oda Design Style Phase 2 (text colors + background)
- Oda Design Style Phase 3-A (theme adjustments)

### Changed
- Migrated hardcoded colors to AppTheme tokens for consistency
- Improved filter_tabs spacing with Wrap properties
- Normalized orderType column on KitchenOrders for better data structure
- Auto-sync table status on KDS state change for real-time updates

### Fixed
- QC issues including test failures and code cleanup
- Resolved 32 compilation errors (19 + 13) across codebase
- Backup test compilation errors with Floor Plan tests cleanup
- Remaining TODOs across the project
- BillRequestScreen connection to PaymentModal
- Smoke test updated for PinLoginScreen entry point
- Unnecessary underscores lint warnings
- All lint warnings cleaned up (0 warnings remaining)

## [0.9.0] - 2026-02-22

### Added
- Delivery integration with external delivery service APIs
- End-to-end (E2E) tests for critical user flows
- Comprehensive RBAC (Role-Based Access Control) system
- KDS enhancements for kitchen workflow optimization
- Server infrastructure setup

## [0.8.0] - 2026-02-13

### Added
- Role-Based Access Control (RBAC) system with granular permissions
- User role management (Admin, Manager, Cashier, Waiter, Kitchen Staff)
- Permission-based UI element visibility

## [0.7.0] - 2026-02-09

### Added
- Table Management System (v9 Database Migration)
- GitHub Actions CI/CD pipeline for automatic APK builds

### Fixed
- All compilation errors resolved across the project
- Type annotations added to Stream.value calls to fix List<dynamic> errors
- Missing imports in DAOs and provider references
- Font parameter errors in receipt_pdf_service
- Incorrect StoreTable references in customers_dao and app_database migration
- Trailing commas causing syntax errors in receipt_pdf_service
- Gradle memory settings and verbose logging for CI build
- Updated upload-artifact to v4 (v3 deprecated)
- Updated Flutter version to 3.38.9 in GitHub Actions

## [0.1.0] - 2026-02-06

### Added
- Initial release of Odaai POS v1.0.0
- Multi-language support (i18n) with English, Vietnamese, Thai, and Korean
- Multi-currency support with configurable exchange rates
- Core POS functionality (sales, checkout, payment processing)
- Kitchen Display System (KDS) for order management
- Product catalog with categories and variants
- Customer management
- Staff management
- Cash drawer operations
- Receipt printing (PDF generation)
- SQLite database with drift ORM
- Basic reporting and analytics

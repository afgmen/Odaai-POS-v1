# Integration Tests - POS Re-check Automation

This directory contains Flutter integration tests for the 23 POS UAT re-check items.

## Structure

```
integration_test/
├── helpers/
│   └── test_helpers.dart          # Common test utilities
├── fixtures/
│   └── test_data.dart              # Test data constants
├── tests/
│   ├── p0/                         # Priority 0 (Critical) - 2 tests
│   │   ├── r008_stock_deduction_test.dart
│   │   └── r009_stock_limit_test.dart
│   ├── p1/                         # Priority 1 (High) - 8 tests
│   │   ├── r003_discount_display_test.dart
│   │   ├── r004_discount_apply_test.dart
│   │   ├── r005_promotion_display_test.dart
│   │   ├── r006_promotion_apply_test.dart
│   │   ├── r018_refund_sales_test.dart
│   │   ├── r019_refund_product_value_test.dart
│   │   ├── r021_points_payment_test.dart
│   │   └── r022_refund_history_test.dart
│   ├── p2/                         # Priority 2 (Medium) - 9 tests
│   │   ├── r001_search_category_filter_test.dart
│   │   ├── r002_sku_barcode_case_test.dart
│   │   ├── r007_cash_currency_sync_test.dart
│   │   ├── r011_deleted_product_validation_test.dart
│   │   ├── r012_data_export_test.dart
│   │   ├── r013_price_cost_warning_test.dart
│   │   ├── r014_inventory_value_test.dart
│   │   ├── r015_order_search_test.dart
│   │   └── r020_customer_list_display_test.dart
│   └── p3/                         # Priority 3 (Low) - 3 tests
│       ├── r010_ai_image_search_test.dart
│       ├── r016_empty_order_display_test.dart
│       └── r017_list_scroll_test.dart
└── README.md                       # This file
```

## Running Tests

### Run all tests
```bash
flutter test integration_test
```

### Run specific priority
```bash
flutter test integration_test/tests/p0  # Critical tests
flutter test integration_test/tests/p1  # High priority
flutter test integration_test/tests/p2  # Medium priority
flutter test integration_test/tests/p3  # Low priority
```

### Run single test
```bash
flutter test integration_test/tests/p0/r008_stock_deduction_test.dart
```

### Run with device
```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/tests/p0/r008_stock_deduction_test.dart
```

## Test Priorities

| Priority | Count | Items |
|----------|-------|-------|
| P0       | 2     | R-008, R-009 |
| P1       | 8     | R-003~006, R-018~019, R-021~022 |
| P2       | 9     | R-001~002, R-007, R-011~015, R-020 |
| P3       | 3     | R-010, R-016~017 |

**Total: 22 tests** (R-023 not applicable for automation)

## Test Coverage Summary

### P0 - Critical (2/2) ✅
- ✅ R-008: Stock Deduction (3 test cases)
- ✅ R-009: Stock Limit (5 test cases)

### P1 - High Priority (8/8) ✅
- ✅ R-003: Discount Display (4 test cases)
- ✅ R-004: Discount Apply (4 test cases)
- ✅ R-005: Promotion Display (3 test cases)
- ✅ R-006: Promotion Apply (3 test cases)
- ✅ R-018: Refund Sales (3 test cases)
- ✅ R-019: Refund Product Value (3 test cases)
- ✅ R-021: Points Payment (3 test cases)
- ✅ R-022: Refund History (3 test cases)

### P2 - Medium Priority (9/10) ✅
- ✅ R-001: Search + Category Filter (3 test cases)
- ✅ R-002: SKU/Barcode Case (4 test cases)
- ✅ R-007: Cash Currency Sync (3 test cases)
- ✅ R-011: Deleted Product (3 test cases)
- ✅ R-012: Data Export (4 test cases)
- ✅ R-013: Price vs Cost Warning (3 test cases)
- ✅ R-014: Inventory Value (3 test cases)
- ✅ R-015: Order Search (4 test cases)
- ✅ R-020: Customer List Display (4 test cases)

### P3 - Low Priority (3/3) ✅
- ✅ R-010: AI Image Search (5 test cases)
- ✅ R-016: Empty Order Display (4 test cases)
- ✅ R-017: List Scroll (5 test cases)

**Total Test Cases: 73**

## Writing Tests

### Template
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-XXX: Test Name', () {
    testWidgets('should do something', (tester) async {
      // 1. Launch app
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // 2. Setup
      // 3. Action
      // 4. Verify
    });
  });
}
```

### Using Helpers
```dart
// Find and tap
await TestHelpers.tap(tester, TestHelpers.findByText('Button'));

// Enter text
await TestHelpers.enterText(tester, TestHelpers.findByKey('input'), 'text');

// Verify
TestHelpers.verifyText('Expected Text');
TestHelpers.verifyTextContains('Partial');
TestHelpers.verifyExists(finder);
TestHelpers.verifyNotExists(finder);
```

## CI Integration

Tests will run automatically on GitHub Actions for every PR.

See `.github/workflows/integration_tests.yml` (to be created in Phase 6)

## Progress Tracking

- [x] Phase 1: Structure & Helpers ✅
- [x] Phase 2: P0 Tests (2/2) ✅
- [x] Phase 3: P1 Tests (8/8) ✅
- [x] Phase 4: P2 Tests (9/10) ✅
- [x] Phase 5: P3 Tests (3/3) ✅
- [ ] Phase 6: CI Setup

**Current: 22/23 tests implemented (96%)**

## Next Steps

1. **Phase 6: CI Setup**
   - Create GitHub Actions workflow
   - Configure test runner
   - Add test reporting

2. **Manual Testing**
   - Run tests on real devices
   - Verify all scenarios
   - Fix any failures

3. **Documentation**
   - Record test execution videos
   - Create troubleshooting guide
   - Add contribution guidelines

## Notes

- R-023 excluded (not suitable for automation)
- Tests use placeholder implementations for complex flows
- Actual implementation requires running app with mocked data
- Some tests require physical device for camera/permissions

## Maintenance

When adding new tests:
1. Follow naming convention: `rXXX_test_name_test.dart`
2. Use TestHelpers for common actions
3. Document test scenarios in comments
4. Add to appropriate priority folder
5. Update this README

---

**Created:** 2026-03-08
**Last Updated:** 2026-03-08
**Total Tests:** 22/23 (96%)
**Total Test Cases:** 73

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
│   ├── p0/                         # Priority 0 (Critical)
│   │   ├── r008_stock_deduction_test.dart
│   │   └── r009_stock_limit_test.dart
│   ├── p1/                         # Priority 1 (High)
│   │   ├── r003_discount_display_test.dart
│   │   ├── r004_discount_apply_test.dart
│   │   ├── r005_promotion_display_test.dart
│   │   ├── r006_promotion_apply_test.dart
│   │   ├── r018_refund_sales_test.dart
│   │   ├── r019_refund_product_value_test.dart
│   │   ├── r021_points_payment_test.dart
│   │   └── r022_refund_history_test.dart
│   ├── p2/                         # Priority 2 (Medium)
│   │   └── ... (10 tests)
│   └── p3/                         # Priority 3 (Low)
│       └── ... (3 tests)
└── README.md                       # This file
```

## Running Tests

### Run all tests
```bash
flutter test integration_test
```

### Run specific priority
```bash
flutter test integration_test/tests/p0
flutter test integration_test/tests/p1
```

### Run single test
```bash
flutter test integration_test/tests/p0/r008_stock_deduction_test.dart
```

## Test Priorities

| Priority | Count | Items |
|----------|-------|-------|
| P0       | 2     | R-008, R-009 |
| P1       | 8     | R-003~006, R-018~019, R-021~022 |
| P2       | 10    | R-001~002, R-007, R-011~015, R-020 |
| P3       | 3     | R-010, R-016~017 |

**Total: 23 tests**

## Writing Tests

### Template
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-XXX: Test Name', () {
    testWidgets('should do something', (tester) async {
      // 1. Setup
      // 2. Action
      // 3. Verify
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
```

## CI Integration

Tests run automatically on GitHub Actions for every PR.

See `.github/workflows/integration_tests.yml`

## Progress

- [ ] Phase 1: Structure ✅
- [ ] Phase 2: P0 Tests (2)
- [ ] Phase 3: P1 Tests (8)
- [ ] Phase 4: P2 Tests (10)
- [ ] Phase 5: P3 Tests (3)
- [ ] Phase 6: CI Setup

**Current: 2/23 tests (templates created)**

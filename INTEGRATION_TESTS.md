# Integration Tests Guide

Complete guide for running and maintaining integration tests.

## Quick Start

### Run all tests
```bash
./integration_test/run_all_tests.sh
```

### Run by priority
```bash
flutter test integration_test/tests/p0  # Critical (P0)
flutter test integration_test/tests/p1  # High (P1)
flutter test integration_test/tests/p2  # Medium (P2)
flutter test integration_test/tests/p3  # Low (P3)
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

## CI/CD Integration

### GitHub Actions

Tests run automatically on:
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual workflow dispatch

**Workflow file:** `.github/workflows/integration_tests.yml`

### Test Priorities

| Priority | Stop on Fail | Description |
|----------|--------------|-------------|
| P0       | ✅ Yes       | Critical - Must pass |
| P1       | ❌ No        | High - Should pass |
| P2       | ❌ No        | Medium - Nice to pass |
| P3       | ❌ No        | Low - Optional |

## Test Coverage

### Summary

- **Total Tests:** 22/23 (96%)
- **Test Cases:** 73
- **Excluded:** R-023 (not automatable)

### By Priority

- **P0 (Critical):** 2 files, 8 test cases
- **P1 (High):** 8 files, 26 test cases
- **P2 (Medium):** 9 files, 31 test cases
- **P3 (Low):** 3 files, 14 test cases

## Writing New Tests

### 1. Choose Priority

Determine test priority:
- **P0:** Critical business logic (stock, payments)
- **P1:** Core features (discounts, refunds, points)
- **P2:** Important UX (search, export, validation)
- **P3:** Nice-to-have (AI, empty states, scroll)

### 2. Create Test File

Location: `integration_test/tests/p{0-3}/rXXX_test_name_test.dart`

Template:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:odaai_pos/main.dart' as app;
import '../../helpers/test_helpers.dart';
import '../../fixtures/test_data.dart';

/// R-XXX: Test Description
/// Priority: PX
/// Steps: ...
/// Expected: ...
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('R-XXX: Test Name', () {
    testWidgets('should do something', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: app.OdaPosApp()),
      );
      await tester.pumpAndSettle();

      // Test implementation
    });
  });
}
```

### 3. Use Test Helpers

```dart
// Navigation
await TestHelpers.tap(tester, TestHelpers.findByText('Tab Name'));

// Input
await TestHelpers.enterText(tester, finder, 'text');

// Verification
TestHelpers.verifyText('Expected');
TestHelpers.verifyTextContains('Partial');
TestHelpers.verifyExists(finder);
TestHelpers.verifyNotExists(finder);
```

### 4. Add Test Data

Update `integration_test/fixtures/test_data.dart`:
```dart
class TestData {
  static const String newTestValue = 'value';
}
```

## Troubleshooting

### Test Fails with "Widget not found"

**Solution:** Add delay or use `pumpAndSettle()`
```dart
await tester.pumpAndSettle(const Duration(seconds: 2));
```

### Test Fails on CI but passes locally

**Check:**
1. Device resolution differences
2. Timezone settings
3. Network mocks
4. Async timing

### Emulator issues

**Android:**
```bash
flutter emulators --launch <emulator-id>
```

**iOS:**
```bash
open -a Simulator
```

## Best Practices

### ✅ Do

- Use descriptive test names
- Test one scenario per test
- Use TestHelpers for common actions
- Clean up after tests
- Document complex flows

### ❌ Don't

- Test internal implementation
- Use hardcoded delays
- Ignore flaky tests
- Skip error handling

## Maintenance

### Update Tests When

1. **Feature changes:** Update affected tests
2. **UI changes:** Update selectors/finders
3. **New features:** Add new tests
4. **Bug fixes:** Add regression tests

### Review Checklist

- [ ] Tests pass locally
- [ ] Tests pass on CI
- [ ] Test names are descriptive
- [ ] Comments explain complex logic
- [ ] No hardcoded values
- [ ] Proper cleanup

## Performance

### Optimize Tests

1. **Minimize app restarts:** Reuse app instance
2. **Mock network calls:** Use fake data
3. **Parallel execution:** Run independent tests
4. **Skip animations:** `WidgetsBinding.instance.disableAnimations`

### Expected Runtimes

- **P0:** ~2-3 minutes
- **P1:** ~5-8 minutes
- **P2:** ~6-10 minutes
- **P3:** ~3-5 minutes
- **Total:** ~15-25 minutes

## Resources

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [WidgetTester API](https://api.flutter.dev/flutter/flutter_test/WidgetTester-class.html)
- [GitHub Actions](https://docs.github.com/en/actions)

---

**Last Updated:** 2026-03-08
**Maintained by:** Development Team

import 'package:integration_test/integration_test_driver.dart';

/// Integration test driver
/// 
/// This file is used by `flutter drive` to run integration tests
/// on a real device or emulator.
/// 
/// Usage:
/// flutter drive \
///   --driver=test_driver/integration_test.dart \
///   --target=integration_test/tests/p0/r008_stock_deduction_test.dart
Future<void> main() => integrationDriver();

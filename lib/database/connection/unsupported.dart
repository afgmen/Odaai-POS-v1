import 'package:drift/drift.dart';

/// 지원되지 않는 플랫폼 (fallback)
QueryExecutor openConnection() {
  throw UnsupportedError(
    'No suitable database implementation was found on this platform.',
  );
}

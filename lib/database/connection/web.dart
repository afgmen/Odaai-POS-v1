import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart' show debugPrint, kReleaseMode;

/// 웹 플랫폼 데이터베이스 연결 (WASM)
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'oda_pos_db',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );

    if (!kReleaseMode) {
      debugPrint('[DB] Web storage: ${result.chosenImplementation}');
      if (result.missingFeatures.isNotEmpty) {
        debugPrint('[DB] Missing browser features: ${result.missingFeatures}');
      }
    }

    return result.resolvedExecutor;
  });
}

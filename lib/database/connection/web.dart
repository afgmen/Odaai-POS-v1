import 'package:drift/drift.dart';
import 'package:drift/web.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

/// 웹 플랫폼 데이터베이스 연결 (IndexedDB)
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    return WebDatabase.withStorage(
      await DriftWebStorage.indexedDbIfSupported('oda_pos_db'),
      logStatements: !kReleaseMode,
    );
  });
}

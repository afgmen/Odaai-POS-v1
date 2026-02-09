import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 네이티브(iOS/Android/macOS/Windows/Linux) 데이터베이스 연결
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'oda_pos.db'));

    if (!kReleaseMode) {
      // ignore: avoid_print
      print('📁 Database path: ${file.path}');
    }

    return NativeDatabase.createInBackground(
      file,
      logStatements: !kReleaseMode,
    );
  });
}

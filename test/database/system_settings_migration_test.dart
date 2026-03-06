import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';

/// B-050: System Settings Table Migration Tests
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('SystemSettings Table', () {
    test('should have system_settings table created', () async {
      final result = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='system_settings'",
      ).get();

      expect(result.isNotEmpty, true);
    });

    test('should be able to insert settings', () async {
      await db.customStatement(
        "INSERT INTO system_settings (key, value, updated_at) VALUES (?, ?, ?)",
        ['test_key', 'test_value', DateTime.now().millisecondsSinceEpoch ~/ 1000],
      );

      final result = await db.customSelect(
        "SELECT key, value FROM system_settings WHERE key = ?",
        variables: [Variable.withString('test_key')],
      ).get();

      expect(result.length, 1);
      expect(result.first.data['key'], 'test_key');
    });

    test('should support INSERT OR REPLACE', () async {
      await db.customStatement(
        "INSERT INTO system_settings (key, value, updated_at) VALUES (?, ?, ?)",
        ['test_update', 'initial', DateTime.now().millisecondsSinceEpoch ~/ 1000],
      );

      await db.customStatement(
        "INSERT OR REPLACE INTO system_settings (key, value, updated_at) VALUES (?, ?, ?)",
        ['test_update', 'updated', DateTime.now().millisecondsSinceEpoch ~/ 1000],
      );

      final result = await db.customSelect(
        "SELECT value FROM system_settings WHERE key = ?",
        variables: [Variable.withString('test_update')],
      ).get();

      expect(result.first.data['value'], 'updated');
    });

    test('should enforce primary key constraint', () async {
      await db.customStatement(
        "INSERT INTO system_settings (key, value, updated_at) VALUES (?, ?, ?)",
        ['dup', 'v1', DateTime.now().millisecondsSinceEpoch ~/ 1000],
      );

      expect(
        () => db.customStatement(
          "INSERT INTO system_settings (key, value, updated_at) VALUES (?, ?, ?)",
          ['dup', 'v2', DateTime.now().millisecondsSinceEpoch ~/ 1000],
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('ensureCriticalTables should not crash', () async {
      // Should complete without error
      await db.ensureCriticalTables();
      expect(true, true);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:oda_pos/database/app_database.dart';

void main() {
  group('B-050: system_settings table fix', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('P0-1: system_settings table exists after onCreate', () async {
      final result = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='system_settings'"
      ).get();
      
      expect(result.isNotEmpty, true, 
        reason: 'system_settings should exist (v13 migration)');
    });

    test('P0-2: CREATE TABLE IF NOT EXISTS is safe (no data loss)', () async {
      // Insert test data
      await db.customStatement('''
        INSERT INTO system_settings (key, value, updated_at)
        VALUES ('test_key', 'test_value', CAST(strftime('%s', 'now') AS INTEGER))
      ''');

      // Re-run CREATE TABLE IF NOT EXISTS (simulates safety net in button)
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS system_settings (
          key TEXT PRIMARY KEY NOT NULL,
          value TEXT NOT NULL,
          updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER))
        )
      ''');

      // Verify data still exists
      final result = await db.customSelect(
        "SELECT * FROM system_settings WHERE key = 'test_key'"
      ).get();

      expect(result.length, 1, 
        reason: 'CREATE TABLE IF NOT EXISTS must not drop existing data');
    });

    test('P0-3: RBAC enablement flow works end-to-end', () async {
      // Step 1: Ensure table exists (safety net)
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS system_settings (
          key TEXT PRIMARY KEY NOT NULL,
          value TEXT NOT NULL,
          updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER))
        )
      ''');

      // Step 2: Enable RBAC (actual insert from button)
      await db.customStatement('''
        INSERT OR REPLACE INTO system_settings (key, value, updated_at)
        VALUES ('rbac_enabled', 'true', CAST(strftime('%s', 'now') AS INTEGER))
      ''');

      // Step 3: Verify
      final result = await db.customSelect(
        "SELECT value FROM system_settings WHERE key = 'rbac_enabled'"
      ).get();

      expect(result.length, 1);
      expect(result.first.data['value'], 'true');
    });
  });
}

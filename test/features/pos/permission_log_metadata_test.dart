import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';

// ---------------------------------------------------------------------------
// U-18: permission_logs table uses `metadata` column (not `reason`)
// Verify that INSERT with `metadata` works and that `reason` column
// does not exist (was renamed to `metadata`).
// ---------------------------------------------------------------------------

AppDatabase _openDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  group('U-18: permission_logs metadata column', () {
    // ── test 1: INSERT with metadata column succeeds ──────────────────
    test('can INSERT into permission_logs using the metadata column', () async {
      final db = _openDb();
      addTearDown(db.close);

      await db.customStatement(
        'INSERT INTO permission_logs '
        '(employee_id, action_type, action_target, permission_granted, metadata) '
        "VALUES (1, 'FORCE_CHECKOUT', 'sale_42', 1, ?)",
        ['{"reason":"manager override","saleId":42}'],
      );

      final rows = await db.customSelect(
        'SELECT * FROM permission_logs WHERE action_type = ?',
        variables: [Variable.withString('FORCE_CHECKOUT')],
      ).get();

      expect(rows.length, 1);
      expect(rows.first.read<String>('action_type'), 'FORCE_CHECKOUT');
      expect(rows.first.read<String?>('metadata'),
          '{"reason":"manager override","saleId":42}');
    });

    // ── test 2: metadata column is nullable (INSERT without metadata) ─
    test('can INSERT into permission_logs without metadata (nullable)', () async {
      final db = _openDb();
      addTearDown(db.close);

      await db.customStatement(
        'INSERT INTO permission_logs '
        '(employee_id, action_type, permission_granted) '
        "VALUES (2, 'DISCOUNT', 1)",
      );

      final rows = await db.customSelect(
        'SELECT * FROM permission_logs WHERE action_type = ?',
        variables: [Variable.withString('DISCOUNT')],
      ).get();

      expect(rows.length, 1);
      expect(rows.first.read<String?>('metadata'), isNull);
    });

    // ── test 3: metadata column exists in the schema ──────────────────
    test('metadata column exists in permission_logs table schema', () async {
      final db = _openDb();
      addTearDown(db.close);

      final columns = await db.customSelect(
        'PRAGMA table_info(permission_logs)',
      ).get();

      final columnNames = columns.map((r) => r.read<String>('name')).toList();
      expect(columnNames, contains('metadata'),
          reason: 'permission_logs must have a metadata column (U-18 fix)');
    });

    // ── test 4: reason column does NOT exist (was renamed to metadata) ─
    test('reason column does NOT exist in permission_logs (renamed to metadata)', () async {
      final db = _openDb();
      addTearDown(db.close);

      final columns = await db.customSelect(
        'PRAGMA table_info(permission_logs)',
      ).get();

      final columnNames = columns.map((r) => r.read<String>('name')).toList();
      expect(columnNames, isNot(contains('reason')),
          reason: 'The old `reason` column must not exist — it was renamed to `metadata`');
    });

    // ── test 5: multiple rows with different action types ─────────────
    test('multiple distinct action types can be inserted and queried', () async {
      final db = _openDb();
      addTearDown(db.close);

      await db.customStatement(
        'INSERT INTO permission_logs '
        '(employee_id, action_type, permission_granted, metadata) '
        "VALUES (1, 'FORCE_CHECKOUT', 1, ?)",
        ['{"note":"checkout override"}'],
      );
      await db.customStatement(
        'INSERT INTO permission_logs '
        '(employee_id, action_type, permission_granted, metadata) '
        "VALUES (1, 'REFUND', 1, ?)",
        ['{"note":"refund approved"}'],
      );
      await db.customStatement(
        'INSERT INTO permission_logs '
        '(employee_id, action_type, permission_granted, metadata) '
        "VALUES (2, 'FORCE_CHECKOUT', 0, ?)",
        ['{"note":"denied"}'],
      );

      final checkoutRows = await db.customSelect(
        'SELECT * FROM permission_logs WHERE action_type = ?',
        variables: [Variable.withString('FORCE_CHECKOUT')],
      ).get();

      expect(checkoutRows.length, 2);

      final refundRows = await db.customSelect(
        'SELECT * FROM permission_logs WHERE action_type = ?',
        variables: [Variable.withString('REFUND')],
      ).get();

      expect(refundRows.length, 1);
      expect(refundRows.first.read<String?>('metadata'), '{"note":"refund approved"}');
    });
  });
}

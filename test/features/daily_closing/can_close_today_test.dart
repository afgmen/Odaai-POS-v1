import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';
import 'package:oda_pos/features/daily_closing/data/daily_closing_dao.dart';
import 'package:oda_pos/features/daily_closing/domain/services/closing_service.dart';

// ---------------------------------------------------------------------------
// T-4: canCloseToday() always returns true regardless of existing closings
// B-106: same-day multiple shift closings are allowed.
// ---------------------------------------------------------------------------

AppDatabase _openDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Build a ClosingService wired to the given database.
/// We pass a null session getter since canCloseToday() does not use session.
ClosingService _buildService(AppDatabase db) {
  return ClosingService(db.dailyClosingDao, () => null, db);
}

/// Ensure employee #1 exists (required FK for daily_closings.closed_by_employee_id).
Future<void> _ensureEmployee(AppDatabase db) async {
  await db.customStatement(
    'INSERT OR IGNORE INTO employees '
    '(id, username, name, password_hash, role, is_active, created_at, updated_at) '
    "VALUES (1, 'admin', 'Manager', 'unused', 'MANAGER', 1, ?, ?)",
    [
      DateTime.now().millisecondsSinceEpoch,
      DateTime.now().millisecondsSinceEpoch,
    ],
  );
}

/// Insert a daily closing record directly via DAO to simulate an existing closing.
Future<void> _insertClosing(AppDatabase db, DateTime date) async {
  await _ensureEmployee(db);
  await db.dailyClosingDao.createDailyClosing(
    closingDate: date,
    aggregation: SalesAggregation(
      totalTransactions: 1,
      totalSales: 10000,
      totalTax: 0,
      totalDiscount: 0,
      cashSales: 10000,
      cardSales: 0,
      qrSales: 0,
      transferSales: 0,
      averageTransaction: 10000,
    ),
    employeeId: 1,
  );
}

void main() {
  group('T-4: canCloseToday()', () {
    // ── test 1: returns true when a closing for today already exists ──
    test('returns true even when a closing for today already exists', () async {
      final db = _openDb();
      addTearDown(db.close);

      final today = DateTime.now();
      await _insertClosing(db, today);

      final service = _buildService(db);
      final result = await service.canCloseToday();
      expect(result, isTrue,
          reason: 'canCloseToday must return true even when today already has a closing');
    });

    // ── test 2: returns true when multiple closings exist for today ───
    test('returns true even when multiple closings exist for today', () async {
      final db = _openDb();
      addTearDown(db.close);

      final now = DateTime.now();
      // Use start-of-day so getClosingsByDate(today) can find them
      final todayDate = DateTime(now.year, now.month, now.day);
      await _insertClosing(db, todayDate);
      await _insertClosing(db, todayDate);
      await _insertClosing(db, todayDate);

      final closings = await db.dailyClosingDao.getClosingsByDate(todayDate);
      expect(closings.length, 3, reason: 'should have 3 closings for today');

      final service = _buildService(db);
      final result = await service.canCloseToday();
      expect(result, isTrue,
          reason: 'canCloseToday must return true even with multiple closings today');
    });

    // ── test 3: returns true when no closings exist ───────────────────
    test('returns true when no closings exist at all', () async {
      final db = _openDb();
      addTearDown(db.close);

      final service = _buildService(db);
      final result = await service.canCloseToday();
      expect(result, isTrue,
          reason: 'canCloseToday must return true when there are no closings');
    });

    // ── test 4: returns true even when yesterday was closed ──────────
    test('returns true when only yesterday has a closing', () async {
      final db = _openDb();
      addTearDown(db.close);

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await _insertClosing(db, yesterday);

      final service = _buildService(db);
      final result = await service.canCloseToday();
      expect(result, isTrue);
    });
  });
}

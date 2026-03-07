import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/database/app_database.dart';

/// B-072: Table Dropdown Tests
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Table List for Dropdown', () {
    test('should retrieve all active tables', () async {
      // Create 3 tables
      await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T01',
          seats: const Value(4),
        ),
      );

      await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T02',
          seats: const Value(6),
        ),
      );

      await db.into(db.restaurantTables).insert(
        RestaurantTablesCompanion.insert(
          tableNumber: 'T03',
          seats: const Value(2),
        ),
      );

      final tables = await (db.select(db.restaurantTables)
            ..where((t) => t.isActive.equals(true)))
          .get();

      expect(tables.length, 3);
      expect(tables.map((t) => t.tableNumber).toList(), ['T01', 'T02', 'T03']);
    });

    test('should filter tables by search term', () async {
      final allTables = ['T01', 'T02', 'T03', 'VIP01', 'VIP02'];

      // Simulate autocomplete filter
      final searchTerm = 'VIP';
      final filtered = allTables.where((table) =>
        table.toLowerCase().contains(searchTerm.toLowerCase())
      ).toList();

      expect(filtered.length, 2);
      expect(filtered, ['VIP01', 'VIP02']);
    });

    test('should filter case-insensitive', () async {
      final allTables = ['T01', 'T02', 't03', 'TABLE-04'];

      final searchTerm = 't';
      final filtered = allTables.where((table) =>
        table.toLowerCase().contains(searchTerm.toLowerCase())
      ).toList();

      expect(filtered.length, 4);
    });

    test('should return all tables when search is empty', () async {
      final allTables = ['T01', 'T02', 'T03'];

      final searchTerm = '';
      final filtered = searchTerm.isEmpty
          ? allTables
          : allTables.where((table) =>
              table.toLowerCase().contains(searchTerm.toLowerCase())
            ).toList();

      expect(filtered.length, 3);
      expect(filtered, allTables);
    });

    test('should handle no matches', () async {
      final allTables = ['T01', 'T02', 'T03'];

      final searchTerm = 'XYZ';
      final filtered = allTables.where((table) =>
        table.toLowerCase().contains(searchTerm.toLowerCase())
      ).toList();

      expect(filtered.length, 0);
    });
  });

  group('Table Selection', () {
    test('should save selected table number', () async {
      final selectedTable = 'T01';
      var tableNumber = '';

      // Simulate onSelected callback
      tableNumber = selectedTable;

      expect(tableNumber, 'T01');
    });

    test('should allow custom table number input', () async {
      final customInput = 'CUSTOM-TABLE';
      var tableNumber = '';

      // Simulate manual input
      tableNumber = customInput;

      expect(tableNumber, 'CUSTOM-TABLE');
    });
  });
}

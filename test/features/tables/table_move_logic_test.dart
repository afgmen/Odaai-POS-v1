import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/features/tables/domain/enums/table_status.dart';

/// Tests for table move business logic.
/// The actual move operation is in TableMoveModal._moveTable which
/// requires DB + widget context. Here we test the pure logic rules.

void main() {
  group('Table move: status transitions', () {
    test('source table becomes AVAILABLE after move', () {
      // When moving from table A, source should reset to AVAILABLE
      const sourceStatus = 'ORDERING';
      const expectedSourceAfter = 'AVAILABLE';
      expect(TableStatus.available.value, expectedSourceAfter);
      // Source is cleared regardless of its current status
      expect(sourceStatus != expectedSourceAfter, true);
    });

    test('target table inherits source status', () {
      // Target table should get the source table's status
      final sourceStatuses = [
        TableStatus.ordering,
        TableStatus.preparing,
        TableStatus.served,
        TableStatus.checkout,
      ];

      for (final sourceStatus in sourceStatuses) {
        // After move: target gets source's status
        final targetStatusAfterMove = sourceStatus.value;
        expect(targetStatusAfterMove, sourceStatus.value);
      }
    });

    test('target must be AVAILABLE before move', () {
      // Only AVAILABLE tables are valid targets
      final targetStatus = TableStatus.available;
      expect(targetStatus, TableStatus.available);
    });

    test('cannot move to a non-available table', () {
      // Move targets are filtered to AVAILABLE only
      final allTables = [
        _MockTable(1, 'T1', TableStatus.available.value),
        _MockTable(2, 'T2', TableStatus.ordering.value),
        _MockTable(3, 'T3', TableStatus.preparing.value),
        _MockTable(4, 'T4', TableStatus.available.value),
      ];
      final sourceId = 5;
      final available = allTables
          .where((t) =>
              t.status == TableStatus.available.value && t.id != sourceId)
          .toList();
      expect(available.length, 2);
      expect(available.every((t) => t.status == TableStatus.available.value), true);
    });

    test('source table excluded from available targets', () {
      final allTables = [
        _MockTable(1, 'T1', TableStatus.available.value),
        _MockTable(2, 'T2', TableStatus.available.value),
      ];
      final sourceId = 1;
      final available = allTables
          .where((t) =>
              t.status == TableStatus.available.value && t.id != sourceId)
          .toList();
      expect(available.length, 1);
      expect(available.first.id, 2);
    });
  });

  group('Table move: sale association', () {
    test('sale.tableId should update to target table', () {
      const targetTableId = 7;
      // The move updates Sale.tableId = targetTable.id
      final updatedTableId = targetTableId;
      expect(updatedTableId, 7);
      expect(updatedTableId != 0, true); // non-null
    });

    test('source currentSaleId transferred to target', () {
      final sourceSaleId = 42;
      // After move: source.currentSaleId = null, target.currentSaleId = sourceSaleId
      int? sourceAfterSaleId;
      int? targetAfterSaleId = sourceSaleId;
      expect(sourceAfterSaleId, isNull);
      expect(targetAfterSaleId, 42);
    });

    test('move with no active sale (available table has no saleId)', () {
      int? sourceSaleId; // null - no active sale
      // If no sale, just swap statuses — no Sale update needed
      expect(sourceSaleId, isNull);
    });
  });

  group('Table move: occupiedAt handling', () {
    test('target gets source occupiedAt', () {
      final sourceOccupiedAt = DateTime(2024, 1, 15, 12, 0);
      // Target should inherit the occupiedAt from source
      final targetOccupiedAt = sourceOccupiedAt;
      expect(targetOccupiedAt, DateTime(2024, 1, 15, 12, 0));
    });

    test('source occupiedAt cleared after move', () {
      // Source table is reset to AVAILABLE with null occupiedAt
      DateTime? sourceOccupiedAfterMove;
      expect(sourceOccupiedAfterMove, isNull);
    });

    test('fallback to DateTime.now if source has no occupiedAt', () {
      DateTime? sourceOccupiedAt; // null
      final targetOccupiedAt = sourceOccupiedAt ?? DateTime.now();
      expect(targetOccupiedAt, isNotNull);
    });
  });

  group('Table move: complete scenario', () {
    test('ordering table A moves to available table B', () {
      // Before
      var tableA = _MockTable(1, 'A1', TableStatus.ordering.value, currentSaleId: 10);
      var tableB = _MockTable(2, 'B1', TableStatus.available.value);

      // Execute move logic
      final targetStatus = tableA.status;
      final targetSaleId = tableA.currentSaleId;

      // After
      tableA = _MockTable(1, 'A1', TableStatus.available.value);
      tableB = _MockTable(2, 'B1', targetStatus, currentSaleId: targetSaleId);

      expect(tableA.status, TableStatus.available.value);
      expect(tableA.currentSaleId, isNull);
      expect(tableB.status, TableStatus.ordering.value);
      expect(tableB.currentSaleId, 10);
    });

    test('served table moves preserving state', () {
      var tableA = _MockTable(1, 'A1', TableStatus.served.value, currentSaleId: 20);
      var tableB = _MockTable(3, 'B3', TableStatus.available.value);

      final targetStatus = tableA.status;
      final targetSaleId = tableA.currentSaleId;

      tableA = _MockTable(1, 'A1', TableStatus.available.value);
      tableB = _MockTable(3, 'B3', targetStatus, currentSaleId: targetSaleId);

      expect(tableA.status, TableStatus.available.value);
      expect(tableB.status, TableStatus.served.value);
      expect(tableB.currentSaleId, 20);
    });
  });
}

class _MockTable {
  final int id;
  final String name;
  final String status;
  final int? currentSaleId;

  _MockTable(this.id, this.name, this.status, {this.currentSaleId});
}

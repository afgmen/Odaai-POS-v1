import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';
import '../../../tables/data/tables_providers.dart';
import '../../../tables/domain/enums/table_status.dart';

/// 테이블 이동 모달 — AVAILABLE 테이블 그리드에서 이동 대상 선택
class TableMoveModal extends ConsumerWidget {
  final RestaurantTable sourceTable;

  const TableMoveModal({super.key, required this.sourceTable});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(allTablesStreamProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              const Icon(Icons.swap_horiz, color: Colors.orange, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Move Table ${sourceTable.tableNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select an available table to move to:',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // AVAILABLE 테이블 그리드
          tablesAsync.when(
            data: (tables) {
              final available = tables
                  .where((t) =>
                      t.status == TableStatus.available.value &&
                      t.id != sourceTable.id)
                  .toList();

              if (available.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No available tables',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: available.length,
                  itemBuilder: (context, index) {
                    final target = available[index];
                    return _TargetTableCard(
                      table: target,
                      onTap: () => _moveTable(context, ref, target),
                    );
                  },
                ),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Failed to load tables')),
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _moveTable(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable targetTable,
  ) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final sourceStatus = sourceTable.status;

    try {
      final db = ref.read(databaseProvider);
      final tablesDao = ref.read(tablesDaoProvider);

      // 1. Update Sale.tableId to new tableId
      if (sourceTable.currentSaleId != null) {
        await (db.update(db.sales)
              ..where((s) => s.id.equals(sourceTable.currentSaleId!)))
            .write(SalesCompanion(
          tableId: Value(targetTable.id),
        ));
      }

      // 2. Source table → AVAILABLE (clear currentSaleId, occupiedAt)
      await tablesDao.updateTableStatus(
        tableId: sourceTable.id,
        status: TableStatus.available.value,
        currentSaleId: null,
        occupiedAt: null,
      );

      // 3. Target table → same status as source, with currentSaleId + occupiedAt
      await tablesDao.updateTableStatus(
        tableId: targetTable.id,
        status: sourceStatus,
        currentSaleId: sourceTable.currentSaleId,
        occupiedAt: sourceTable.occupiedAt ?? DateTime.now(),
      );

      navigator.pop();
      scaffoldMessenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Table ${sourceTable.tableNumber} → ${targetTable.tableNumber} moved',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Table move failed: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
      }
    }
  }
}

class _TargetTableCard extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onTap;

  const _TargetTableCard({required this.table, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TableStatus.available.color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: TableStatus.available.color.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                table.tableNumber,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TableStatus.available.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${table.seats} seats',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

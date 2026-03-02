import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';

class TableMergeModal extends ConsumerWidget {
  final RestaurantTable currentTable;
  final int? currentSaleIdId;

  const TableMergeModal({
    super.key,
    required this.currentTable,
    this.currentSaleId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    
    return FutureBuilder<List<RestaurantTable>>(
      future: _getOccupiedTables(db),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final availableTables = snapshot.data!
            .where((t) => t.id != currentTable.id && t.status == 'OCCUPIED')
            .toList();

        return AlertDialog(
          title: Text('Merge Table ${currentTable.tableNumber}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: availableTables.isEmpty
                ? const Center(child: Text('No other occupied tables available'))
                : ListView.builder(
                    itemCount: availableTables.length,
                    itemBuilder: (context, index) {
                      final table = availableTables[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary,
                            child: Text(
                              table.tableNumber.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text('Table ${table.tableNumber}'),
                          subtitle: Text('Zone: ${table.zone ?? "N/A"}'),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () => _confirmMerge(context, ref, table),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<List<RestaurantTable>> _getOccupiedTables(AppDatabase db) async {
    return await (db.select(db.restaurantTables)
          ..where((t) => t.status.equals('OCCUPIED')))
        .get();
  }

  void _confirmMerge(BuildContext context, WidgetRef ref, RestaurantTable targetTable) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Merge'),
        content: Text(
          'Merge Table ${targetTable.tableNumber} into Table ${currentTable.tableNumber}?\n\n'
          'Table ${targetTable.tableNumber} will be cleared and marked as available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              await _performMerge(context, ref, targetTable);
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Merge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performMerge(
    BuildContext context,
  Future<void> _performMerge(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable targetTable,
  ) async {
    final db = ref.read(databaseProvider);
    
    try {
      if (currentSaleId == null) {
        throw Exception('Current sale not found');
      }

      // Get current sale
      final currentSale = await (db.select(db.sales)
            ..where((s) => s.id.equals(currentSaleId!)))
          .getSingleOrNull();

      if (currentSale == null) {
        throw Exception('Current sale not found');
      }

      // Find target table's sale
      final targetSale = await (db.select(db.sales)
            ..where((s) => s.tableId.equals(targetTable.id))
            ..where((s) => s.status.equals('pending')))
          .getSingleOrNull();

      if (targetSale == null) {
        throw Exception('Target table has no active sale');
      }

      // Move all sale items from target sale to current sale
      final targetItems = await (db.select(db.saleItems)
            ..where((si) => si.saleId.equals(targetSale.id)))
          .get();

      for (var item in targetItems) {
        await db.into(db.saleItems).insert(
          SaleItemsCompanion.insert(
            saleId: currentSaleId!,
            productId: item.productId,
            productName: item.productName,
            sku: item.sku,
            unitPrice: item.unitPrice,
            quantity: item.quantity,
            total: item.total,
          ),
        );
      }

      // Update totals on current sale
      final newSubtotal = currentSale.subtotal + targetSale.subtotal;
      final newTotal = currentSale.total + targetSale.total;
      
      await (db.update(db.sales)..where((s) => s.id.equals(currentSaleId!)))
          .write(SalesCompanion(
        subtotal: drift.Value(newSubtotal),
        total: drift.Value(newTotal),
      ));

      // Mark target sale as merged
      await (db.update(db.sales)..where((s) => s.id.equals(targetSale.id)))
          .write(const SalesCompanion(status: drift.Value('merged')));

      // Clear target table
      await (db.update(db.restaurantTables)
            ..where((t) => t.id.equals(targetTable.id)))
          .write(const RestaurantTablesCompanion(
        status: drift.Value('AVAILABLE'),
        currentSaleId: drift.Value.absent(),
      ));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Table ${targetTable.tableNumber} merged into Table ${currentTable.tableNumber}',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error merging tables: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}

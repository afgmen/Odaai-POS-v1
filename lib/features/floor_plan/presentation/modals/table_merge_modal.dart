import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';

class TableMergeModal extends ConsumerWidget {
  final RestaurantTable currentTable;
  final int? currentSaleId;

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
            .where((t) => t.id != currentTable.id && ['ORDERING', 'PREPARING', 'SERVED', 'CHECKOUT'].contains(t.status))
            .toList();

        debugPrint('[MergeTable] Merge candidates (excluding current): ${availableTables.length}');
        if (availableTables.isNotEmpty) {
          debugPrint('[MergeTable] Available: ${availableTables.map((t) => t.tableNumber).join(", ")}');
        }

        return AlertDialog(
          title: Text('Merge Table ${currentTable.tableNumber}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: availableTables.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No other occupied tables available',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'At least 2 tables must be occupied to merge.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
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
                          subtitle: Text('Capacity: ${table.seats} | Status: ${table.status}'),
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
    final tables = await (db.select(db.restaurantTables)
          ..where((t) => t.status.isIn(['ORDERING', 'PREPARING', 'SERVED', 'CHECKOUT'])))
        .get();
    
    debugPrint('[MergeTable] Found ${tables.length} active tables total');
    debugPrint('[MergeTable] Current table: ${currentTable.tableNumber} (ID: ${currentTable.id})');
    
    return tables;
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

      // B-107: 합산 후 소계/합계/할인/세금 모두 업데이트
      final newSubtotal = currentSale.subtotal + targetSale.subtotal;
      final newDiscount = (currentSale.discount ?? 0) + (targetSale.discount ?? 0);
      final newTax = (currentSale.tax ?? 0) + (targetSale.tax ?? 0);
      final newTotal = newSubtotal - newDiscount + newTax;
      
      await (db.update(db.sales)..where((s) => s.id.equals(currentSaleId!)))
          .write(SalesCompanion(
        subtotal: drift.Value(newSubtotal),
        discount: drift.Value(newDiscount),
        tax: drift.Value(newTax),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';
import '../../../tables/data/tables_providers.dart';

final vndFormat = NumberFormat('#,###', 'en_US');

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
    final tablesAsync = ref.watch(allTablesStreamProvider);

    return tablesAsync.when(
      loading: () => const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const AlertDialog(
        content: Text('Failed to load tables'),
      ),
      data: (allTables) {
        final availableTables = allTables
            .where((t) =>
                t.id != currentTable.id &&
                ['ORDERING', 'PREPARING', 'SERVED', 'CHECKOUT'].contains(t.status))
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
                          onTap: () => _handleTableSelection(context, ref, table),
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

  /// Step 1: load both sales, decide whether to show promotion picker or go
  /// straight to the confirm dialog.
  Future<void> _handleTableSelection(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable targetTable,
  ) async {
    if (currentSaleId == null) {
      _showConfirmDialog(context, ref, targetTable, chosenDiscount: 0);
      return;
    }

    final db = ref.read(databaseProvider);

    final currentSale = await (db.select(db.sales)
          ..where((s) => s.id.equals(currentSaleId!)))
        .getSingleOrNull();

    final targetSale = await (db.select(db.sales)
          ..where((s) => s.tableId.equals(targetTable.id))
          ..where((s) => s.status.isIn(['open', 'pending'])))
        .getSingleOrNull();

    if (!context.mounted) return;

    final currentDiscount = currentSale?.discount ?? 0;
    final targetDiscount = targetSale?.discount ?? 0;

    // T-2: at least one table has a promotion → ask user
    if (currentDiscount > 0 || targetDiscount > 0) {
      _showPromotionPickerDialog(
        context,
        ref,
        targetTable,
        currentDiscount: currentDiscount,
        targetDiscount: targetDiscount,
      );
    } else {
      // Neither table has a promotion
      _showConfirmDialog(context, ref, targetTable, chosenDiscount: 0);
    }
  }

  /// Step 2a: show promotion picker when at least one table has a discount.
  void _showPromotionPickerDialog(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable targetTable, {
    required double currentDiscount,
    required double targetDiscount,
  }) {
    final bothHavePromo = currentDiscount > 0 && targetDiscount > 0;
    final activeDiscount = currentDiscount > 0 ? currentDiscount : targetDiscount;
    final activeTableNumber =
        currentDiscount > 0 ? currentTable.tableNumber : targetTable.tableNumber;

    final description = bothHavePromo
        ? 'Both Table ${currentTable.tableNumber} and Table ${targetTable.tableNumber} '
            'have promotions applied.\n\nWhich promotion should apply to the merged table?'
        : 'Table $activeTableNumber has a promotion applied.\n\n'
            'Should the merged table keep this promotion?';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Promotion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 20),
            if (currentDiscount > 0) ...[
              _PromoOptionTile(
                tableNumber: currentTable.tableNumber,
                discount: currentDiscount,
                onTap: () {
                  Navigator.pop(ctx);
                  _showConfirmDialog(context, ref, targetTable, chosenDiscount: currentDiscount);
                },
              ),
              const SizedBox(height: 8),
            ],
            if (targetDiscount > 0) ...[
              _PromoOptionTile(
                tableNumber: targetTable.tableNumber,
                discount: targetDiscount,
                onTap: () {
                  Navigator.pop(ctx);
                  _showConfirmDialog(context, ref, targetTable, chosenDiscount: targetDiscount);
                },
              ),
              const SizedBox(height: 8),
            ],
            _PromoOptionTile(
              tableNumber: null,
              discount: activeDiscount, // passed but unused when isNoPromo=true
              onTap: () {
                Navigator.pop(ctx);
                _showConfirmDialog(context, ref, targetTable, chosenDiscount: 0);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Step 2b: confirm merge with the already-chosen discount.
  void _showConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    RestaurantTable targetTable, {
    required double chosenDiscount,
  }) {
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
              await _performMerge(context, ref, targetTable, chosenDiscount: chosenDiscount);
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
    RestaurantTable targetTable, {
    required double chosenDiscount,
  }) async {
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
            ..where((s) => s.status.isIn(['open', 'pending'])))
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

      // B-107 / T-2: use the user-chosen discount, not a blind sum
      final newSubtotal = currentSale.subtotal + targetSale.subtotal;
      final newTax = currentSale.tax + targetSale.tax;
      final newTotal = newSubtotal - chosenDiscount + newTax;

      await (db.update(db.sales)..where((s) => s.id.equals(currentSaleId!)))
          .write(SalesCompanion(
        subtotal: drift.Value(newSubtotal),
        discount: drift.Value(chosenDiscount),
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

/// A tappable card showing one promotion option in the picker dialog.
class _PromoOptionTile extends StatelessWidget {
  final String? tableNumber; // null = "No promotion"
  final double discount;
  final VoidCallback onTap;

  const _PromoOptionTile({
    required this.tableNumber,
    required this.discount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNoPromo = tableNumber == null;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: isNoPromo ? Colors.grey.shade300 : AppTheme.primary),
          borderRadius: BorderRadius.circular(8),
          color: isNoPromo ? Colors.transparent : AppTheme.primary.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(
              isNoPromo ? Icons.remove_circle_outline : Icons.local_offer_outlined,
              color: isNoPromo ? Colors.grey : AppTheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isNoPromo ? 'No promotion' : 'Table $tableNumber\'s promotion',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isNoPromo ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
                  if (!isNoPromo)
                    Text(
                      'Discount: -₫${vndFormat.format(discount)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

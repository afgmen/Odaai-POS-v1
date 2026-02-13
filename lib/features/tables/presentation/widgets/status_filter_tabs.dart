import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/tables_providers.dart';
import '../../domain/enums/table_status.dart';

/// Table status filter tabs
class StatusFilterTabs extends ConsumerWidget {
  const StatusFilterTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedStatus = ref.watch(selectedTableStatusProvider);
    final tableCountAsync = ref.watch(tableCountByStatusProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: tableCountAsync.when(
        data: (counts) => Row(
          children: [
            // All tab
            _buildFilterTab(
              context: context,
              label: l10n.allTables,
              status: null,
              count: counts.values.fold(0, (sum, count) => sum + count),
              isSelected: selectedStatus == null,
              color: Colors.grey[700]!,
              onTap: () {
                ref.read(selectedTableStatusProvider.notifier).state = null;
              },
            ),
            const SizedBox(width: 8),

            // Status tabs
            ...TableStatus.allStatuses.map((status) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterTab(
                  context: context,
                  label: _getLocalizedStatusLabel(l10n, status.value),
                  status: status.value,
                  count: counts[status.value] ?? 0,
                  isSelected: selectedStatus == status.value,
                  color: status.color,
                  onTap: () {
                    ref.read(selectedTableStatusProvider.notifier).state =
                        status.value;
                  },
                ),
              );
            }),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(l10n.errorOccurred(err.toString())),
        ),
      ),
    );
  }

  Widget _buildFilterTab({
    required BuildContext context,
    required String label,
    required String? status,
    required int count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLocalizedStatusLabel(AppLocalizations l10n, String statusValue) {
    switch (statusValue) {
      case 'available':
        return l10n.emptyTables;
      case 'occupied':
        return l10n.occupiedTables;
      case 'reserved':
        return l10n.tableReserved;
      case 'seated':
        return l10n.tableSeated;
      case 'payment_complete':
        return l10n.tablePaymentComplete;
      case 'cleaning':
        return l10n.tableCleaning;
      default:
        return statusValue;
    }
  }
}

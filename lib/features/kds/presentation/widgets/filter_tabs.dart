import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/enums/order_status.dart';
import '../providers/kds_screen_provider.dart';

class FilterTabs extends ConsumerWidget {
  const FilterTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedFilter = ref.watch(selectedFilterProvider);
    // B-UAT: 상태별 주문 건수 조회
    final countsAsync = ref.watch(orderCountByStatusProvider);
    final counts = countsAsync.valueOrNull ?? {};

    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildFilterChip(
            context: context,
            ref: ref,
            label: l10n.kdsFilterAll,
            status: null,
            isSelected: selectedFilter == null,
            color: Colors.grey,
            count: counts[null] ?? 0,
          ),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: l10n.kdsFilterPending,
            status: OrderStatus.pending,
            isSelected: selectedFilter == OrderStatus.pending,
            color: Color(int.parse(OrderStatus.pending.colorHex.replaceFirst('#', '0xFF'))),
            count: counts[OrderStatus.pending.value] ?? 0,
          ),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: l10n.kdsFilterPreparing,
            status: OrderStatus.preparing,
            isSelected: selectedFilter == OrderStatus.preparing,
            color: Color(int.parse(OrderStatus.preparing.colorHex.replaceFirst('#', '0xFF'))),
            count: counts[OrderStatus.preparing.value] ?? 0,
          ),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: l10n.kdsFilterReady,
            status: OrderStatus.ready,
            isSelected: selectedFilter == OrderStatus.ready,
            color: Color(int.parse(OrderStatus.ready.colorHex.replaceFirst('#', '0xFF'))),
            count: counts[OrderStatus.ready.value] ?? 0,
          ),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: 'Served',
            status: OrderStatus.served,
            isSelected: selectedFilter == OrderStatus.served,
            color: Color(int.parse(OrderStatus.served.colorHex.replaceFirst('#', '0xFF'))),
            count: counts[OrderStatus.served.value] ?? 0,
          ),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: 'Cancelled',
            status: OrderStatus.cancelled,
            isSelected: selectedFilter == OrderStatus.cancelled,
            color: Color(int.parse(OrderStatus.cancelled.colorHex.replaceFirst('#', '0xFF'))),
            count: counts[OrderStatus.cancelled.value] ?? 0,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required OrderStatus? status,
    required bool isSelected,
    required Color color,
    int count = 0,
  }) {
    // B-UAT: 주문 건수가 있으면 배지로 표시
    final labelText = count > 0 ? '$label ($count)' : label;
    return FilterChip(
      label: Text(
        labelText,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        ref.read(selectedFilterProvider.notifier).state = status;
      },
      selectedColor: color,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }
}

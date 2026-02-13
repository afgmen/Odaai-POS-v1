import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/enums/order_status.dart';
import '../providers/kds_screen_provider.dart';

/// 상태 필터 탭 위젯
class FilterTabs extends ConsumerWidget {
  const FilterTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selectedFilter = ref.watch(selectedFilterProvider);

    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(
            context: context,
            ref: ref,
            label: l10n.kdsFilterAll,
            status: null,
            isSelected: selectedFilter == null,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: l10n.kdsFilterPending,
            status: OrderStatus.pending,
            isSelected: selectedFilter == OrderStatus.pending,
            color: Color(int.parse(
                OrderStatus.pending.colorHex.replaceFirst('#', '0xFF'))),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: l10n.kdsFilterPreparing,
            status: OrderStatus.preparing,
            isSelected: selectedFilter == OrderStatus.preparing,
            color: Color(int.parse(
                OrderStatus.preparing.colorHex.replaceFirst('#', '0xFF'))),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            ref: ref,
            label: l10n.kdsFilterReady,
            status: OrderStatus.ready,
            isSelected: selectedFilter == OrderStatus.ready,
            color: Color(int.parse(
                OrderStatus.ready.colorHex.replaceFirst('#', '0xFF'))),
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
  }) {
    return FilterChip(
      label: Text(
        label,
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

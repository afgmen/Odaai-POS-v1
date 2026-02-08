import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/tables_providers.dart';
import '../../domain/enums/table_status.dart';

/// 테이블 상태 필터 탭
class StatusFilterTabs extends ConsumerWidget {
  const StatusFilterTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            // 전체 탭
            _buildFilterTab(
              context: context,
              label: '전체',
              status: null,
              count: counts.values.fold(0, (sum, count) => sum + count),
              isSelected: selectedStatus == null,
              color: Colors.grey[700]!,
              onTap: () {
                ref.read(selectedTableStatusProvider.notifier).state = null;
              },
            ),
            const SizedBox(width: 8),

            // 각 상태별 탭
            ...TableStatus.allStatuses.map((status) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterTab(
                  context: context,
                  label: status.label,
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
          child: Text('오류 발생: ${err.toString()}'),
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
}

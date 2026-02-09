import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/kitchen_service_provider.dart';

/// 주방 성과 헤더 위젯
class PerformanceHeader extends ConsumerWidget {
  const PerformanceHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performanceAsync = ref.watch(kitchenPerformanceProvider);

    return performanceAsync.when(
      data: (performance) => Row(
        children: [
          // 오늘 처리된 주문
          _buildStatItem(
            icon: Icons.check_circle,
            label: '완료',
            value: '${performance.todayServedCount}건',
            color: Colors.green,
          ),
          const SizedBox(width: 16),

          // 활성 주문 수
          _buildStatItem(
            icon: Icons.pending,
            label: '진행중',
            value: '${performance.totalActiveOrders}건',
            color: Colors.orange,
          ),
          const SizedBox(width: 16),

          // 평균 조리 시간
          _buildStatItem(
            icon: Icons.timer,
            label: '평균',
            value: performance.averagePrepTimeFormatted,
            color: Colors.blue,
          ),
        ],
      ),
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const Icon(Icons.error, color: Colors.red),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

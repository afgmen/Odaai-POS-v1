import 'package:flutter/material.dart';
import '../../../../database/app_database.dart';
import '../../domain/enums/table_status.dart';

/// 드래그 가능한 테이블 위젯
class TableWidget extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onTap;
  final Function(Offset)? onDragEnd;
  final bool isDraggable;

  const TableWidget({
    super.key,
    required this.table,
    required this.onTap,
    this.onDragEnd,
    this.isDraggable = true,
  });

  @override
  Widget build(BuildContext context) {
    final status = TableStatus.fromString(table.status);

    if (!isDraggable) {
      return GestureDetector(
        onTap: onTap,
        child: _buildTableCard(status),
      );
    }

    return Positioned(
      left: table.positionX,
      top: table.positionY,
      child: Draggable<RestaurantTable>(
        data: table,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: 0.8,
            child: _buildTableCard(status, isDragging: true),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildTableCard(status),
        ),
        onDragEnd: (details) {
          if (onDragEnd != null) {
            onDragEnd!(details.offset);
          }
        },
        child: GestureDetector(
          onTap: onTap,
          child: _buildTableCard(status),
        ),
      ),
    );
  }

  /// 테이블 모양에 따른 크기와 BorderRadius 계산
  ({double w, double h, BorderRadius radius}) _shapeMetrics() {
    final shape = table.shape;
    switch (shape) {
      case 'round':
        return (w: 100.0, h: 100.0, radius: BorderRadius.circular(50));
      case 'rectangle':
        return (w: 160.0, h: 100.0, radius: BorderRadius.circular(12));
      case 'square':
      default:
        return (w: 100.0, h: 100.0, radius: BorderRadius.circular(12));
    }
  }

  Widget _buildTableCard(TableStatus status, {bool isDragging = false}) {
    final metrics = _shapeMetrics();
    return Container(
      width: metrics.w,
      height: metrics.h,
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        border: Border.all(
          color: status.color,
          width: isDragging ? 3 : 2,
        ),
        borderRadius: metrics.radius,
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: status.color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 테이블 번호
          Text(
            table.tableNumber,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: status.color,
            ),
          ),
          const SizedBox(height: 4),

          // 상태 표시
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: status.color,
              ),
            ),
          ),
          const SizedBox(height: 2),

          // 좌석 수
          if (table.seats > 0)
            Text(
              '${table.seats} seats',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
              ),
            ),

          // 착석 시간 (OCCUPIED 상태일 때)
          if (status == TableStatus.occupied && table.occupiedAt != null)
            Text(
              _formatDuration(DateTime.now().difference(table.occupiedAt!)),
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }

  /// 경과 시간 포맷 (예: 25분)
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }
}

import 'package:flutter/material.dart';
import '../../../../database/app_database.dart';
import '../../domain/enums/table_status.dart';

/// 드래그 가능한 테이블 위젯
class TableWidget extends StatefulWidget {
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
  State<TableWidget> createState() => _TableWidgetState();
}

class _TableWidgetState extends State<TableWidget> {
  late double _displayX;
  late double _displayY;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _displayX = widget.table.positionX;
    _displayY = widget.table.positionY;
  }

  @override
  void didUpdateWidget(TableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update position if:
    // 1. Not currently dragging
    // 2. Same table (by ID)
    // 3. Position actually changed (avoid unnecessary setState)
    if (!_isDragging && 
        oldWidget.table.id == widget.table.id &&
        (oldWidget.table.positionX != widget.table.positionX ||
         oldWidget.table.positionY != widget.table.positionY)) {
      setState(() {
        _displayX = widget.table.positionX;
        _displayY = widget.table.positionY;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = TableStatus.fromString(widget.table.status);

    if (!widget.isDraggable) {
      return Positioned(
        left: widget.table.positionX,
        top: widget.table.positionY,
        child: GestureDetector(
          onTap: widget.onTap,
          child: _buildTableCard(status),
        ),
      );
    }

    return Positioned(
      left: _displayX,
      top: _displayY,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (details) {
          final metrics = _shapeMetrics();
          setState(() {
            _displayX = (_displayX + details.delta.dx)
                .clamp(0, 2000 - metrics.w);
            _displayY = (_displayY + details.delta.dy)
                .clamp(0, 2000 - metrics.h);
          });
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          widget.onDragEnd?.call(Offset(_displayX, _displayY));
        },
        child: AnimatedOpacity(
          opacity: _isDragging ? 0.75 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: _buildTableCard(status, isDragging: _isDragging),
        ),
      ),
    );
  }

  /// 테이블 모양에 따른 크기와 BorderRadius 계산
  ({double w, double h, BorderRadius radius}) _shapeMetrics() {
    final shape = widget.table.shape;
    switch (shape) {
      case 'round':
      case 'circle':
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
            widget.table.tableNumber,
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
          if (widget.table.seats > 0)
            Text(
              '${widget.table.seats} seats',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey[600],
              ),
            ),

          // 착석 시간 (OCCUPIED 상태일 때)
          if (widget.table.occupiedAt != null &&
              status != TableStatus.available &&
              status != TableStatus.cleaning)
            Text(
              _formatDuration(
                  DateTime.now().difference(widget.table.occupiedAt!)),
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

import 'package:flutter/material.dart';
import '../../../../database/app_database.dart';

/// 드래그 가능한 구역 위젯 (반투명 색상 사각형)
class FloorZoneWidget extends StatelessWidget {
  final FloorZone zone;
  final bool isDraggable;
  final VoidCallback? onTap;
  final Function(Offset)? onDragEnd;

  const FloorZoneWidget({
    super.key,
    required this.zone,
    this.isDraggable = true,
    this.onTap,
    this.onDragEnd,
  });

  Color _parseColor() {
    try {
      final hex = zone.colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.blue.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor();
    final child = _buildZoneRect(color);

    if (!isDraggable) {
      return Positioned(
        left: zone.posX,
        top: zone.posY,
        child: child,
      );
    }

    return Positioned(
      left: zone.posX,
      top: zone.posY,
      child: Draggable<FloorZone>(
        data: zone,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(opacity: 0.6, child: _buildZoneRect(color)),
        ),
        childWhenDragging: Opacity(
          opacity: 0.2,
          child: _buildZoneRect(color),
        ),
        onDragEnd: (details) {
          onDragEnd?.call(details.offset);
        },
        child: GestureDetector(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }

  Widget _buildZoneRect(Color color) {
    return Container(
      width: zone.width,
      height: zone.height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Text(
          zone.name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

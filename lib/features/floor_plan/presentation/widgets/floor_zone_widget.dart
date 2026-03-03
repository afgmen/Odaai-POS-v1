import 'package:flutter/material.dart';
import '../../../../database/app_database.dart';

/// 드래그 가능한 구역 위젯 (반투명 색상 사각형)
class FloorZoneWidget extends StatefulWidget {
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

  @override
  State<FloorZoneWidget> createState() => _FloorZoneWidgetState();
}

class _FloorZoneWidgetState extends State<FloorZoneWidget> {
  late double _displayX;
  late double _displayY;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _displayX = widget.zone.posX;
    _displayY = widget.zone.posY;
  }

  @override
  void didUpdateWidget(FloorZoneWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // DB 갱신 시 위치 반영 (드래그 중이 아닐 때만)
    if (!_isDragging) {
      _displayX = widget.zone.posX;
      _displayY = widget.zone.posY;
    }
  }

  Color _parseColor() {
    try {
      final hex = widget.zone.colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.blue.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor();
    final child = _buildZoneRect(color);

    if (!widget.isDraggable) {
      return Positioned(
        left: widget.zone.posX,
        top: widget.zone.posY,
        child: child,
      );
    }

    return Positioned(
      left: _displayX,
      top: _displayY,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (details) {
          setState(() {
            _displayX = (_displayX + details.delta.dx)
                .clamp(0, 2000 - widget.zone.width);
            _displayY = (_displayY + details.delta.dy)
                .clamp(0, 2000 - widget.zone.height);
          });
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          widget.onDragEnd?.call(Offset(_displayX, _displayY));
        },
        child: AnimatedOpacity(
          opacity: _isDragging ? 0.7 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: child,
        ),
      ),
    );
  }

  Widget _buildZoneRect(Color color) {
    return Container(
      width: widget.zone.width,
      height: widget.zone.height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: _isDragging ? 2.5 : 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: _isDragging
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Text(
          widget.zone.name,
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

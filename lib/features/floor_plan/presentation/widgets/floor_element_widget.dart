import 'package:flutter/material.dart';
import '../../../../database/app_database.dart';

/// 드래그 가능한 매장 요소 위젯 (입구, 카운터, 화장실 등)
class FloorElementWidget extends StatefulWidget {
  final FloorElement element;
  final bool isDraggable;
  final VoidCallback? onTap;
  final Function(Offset)? onDragEnd;

  const FloorElementWidget({
    super.key,
    required this.element,
    this.isDraggable = true,
    this.onTap,
    this.onDragEnd,
  });

  @override
  State<FloorElementWidget> createState() => _FloorElementWidgetState();
}

class _FloorElementWidgetState extends State<FloorElementWidget> {
  late double _displayX;
  late double _displayY;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _displayX = widget.element.posX;
    _displayY = widget.element.posY;
  }

  @override
  void didUpdateWidget(FloorElementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update position if:
    // 1. Not currently dragging
    // 2. Same element (by ID)
    // 3. Position actually changed
    if (!_isDragging && 
        oldWidget.element.id == widget.element.id &&
        (oldWidget.element.posX != widget.element.posX ||
         oldWidget.element.posY != widget.element.posY)) {
      setState(() {
        _displayX = widget.element.posX;
        _displayY = widget.element.posY;
      });
    }
  }

  /// 요소 유형별 아이콘
  static IconData iconForType(String type) {
    switch (type) {
      case 'entrance':
        return Icons.door_front_door;
      case 'counter':
        return Icons.point_of_sale;
      case 'restroom':
        return Icons.wc;
      case 'window':
        return Icons.window;
      case 'wall':
        return Icons.crop_square;
      case 'bar_counter':
        return Icons.local_bar;
      default:
        return Icons.help_outline;
    }
  }

  /// 요소 유형별 색상
  static Color colorForType(String type) {
    switch (type) {
      case 'entrance':
        return Colors.green;
      case 'counter':
        return Colors.indigo;
      case 'restroom':
        return Colors.teal;
      case 'window':
        return Colors.lightBlue;
      case 'wall':
        return Colors.grey;
      case 'bar_counter':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _buildElementCard();

    if (!widget.isDraggable) {
      return Positioned(
        left: widget.element.posX,
        top: widget.element.posY,
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
                .clamp(0, 2000 - widget.element.width);
            _displayY = (_displayY + details.delta.dy)
                .clamp(0, 2000 - widget.element.height);
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

  Widget _buildElementCard() {
    final color = colorForType(widget.element.elementType);
    final icon = iconForType(widget.element.elementType);
    final displayLabel = widget.element.label ?? widget.element.elementType;

    return Transform.rotate(
      angle: widget.element.rotation * 3.14159265 / 180,
      child: Container(
        width: widget.element.width,
        height: widget.element.height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(
            color: color.withValues(alpha: _isDragging ? 0.7 : 0.4),
            width: _isDragging ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: _isDragging
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              displayLabel,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

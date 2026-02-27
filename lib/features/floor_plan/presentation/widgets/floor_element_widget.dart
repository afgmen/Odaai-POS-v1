import 'package:flutter/material.dart';
import '../../../../database/app_database.dart';

/// 드래그 가능한 매장 요소 위젯 (입구, 카운터, 화장실 등)
class FloorElementWidget extends StatelessWidget {
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

    if (!isDraggable) {
      return Positioned(
        left: element.posX,
        top: element.posY,
        child: child,
      );
    }

    return Positioned(
      left: element.posX,
      top: element.posY,
      child: Draggable<FloorElement>(
        data: element,
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(opacity: 0.7, child: _buildElementCard()),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildElementCard(),
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

  Widget _buildElementCard() {
    final color = colorForType(element.elementType);
    final icon = iconForType(element.elementType);
    final displayLabel = element.label ?? element.elementType;

    return Transform.rotate(
      angle: element.rotation * 3.14159265 / 180,
      child: Container(
        width: element.width,
        height: element.height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          borderRadius: BorderRadius.circular(6),
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

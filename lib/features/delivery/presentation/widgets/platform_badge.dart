import 'package:flutter/material.dart';
import '../../domain/enums/delivery_platform.dart';

/// Small colored badge showing the delivery platform name + icon.
/// Grab = green, ShopeeFood = orange-red, Manual = grey.
class PlatformBadge extends StatelessWidget {
  final DeliveryPlatform platform;
  final bool compact;

  const PlatformBadge({
    super.key,
    required this.platform,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: platform.brandColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            platform.icon,
            color: Colors.white,
            size: compact ? 10 : 12,
          ),
          const SizedBox(width: 4),
          Text(
            platform.displayName,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Supported delivery platforms.
enum DeliveryPlatform {
  grab,
  shopeefood,
  manual;

  String get displayName {
    switch (this) {
      case DeliveryPlatform.grab:
        return 'GrabFood';
      case DeliveryPlatform.shopeefood:
        return 'ShopeeFood';
      case DeliveryPlatform.manual:
        return 'Manual';
    }
  }

  String get value {
    switch (this) {
      case DeliveryPlatform.grab:
        return 'grab';
      case DeliveryPlatform.shopeefood:
        return 'shopeefood';
      case DeliveryPlatform.manual:
        return 'manual';
    }
  }

  Color get brandColor {
    switch (this) {
      case DeliveryPlatform.grab:
        return const Color(0xFF00B14F); // GrabFood green
      case DeliveryPlatform.shopeefood:
        return const Color(0xFFEE4D2D); // ShopeeFood orange-red
      case DeliveryPlatform.manual:
        return const Color(0xFF9E9E9E); // grey
    }
  }

  IconData get icon {
    switch (this) {
      case DeliveryPlatform.grab:
        return Icons.delivery_dining;
      case DeliveryPlatform.shopeefood:
        return Icons.fastfood;
      case DeliveryPlatform.manual:
        return Icons.add_box_outlined;
    }
  }

  static DeliveryPlatform fromString(String value) {
    switch (value.toLowerCase()) {
      case 'grab':
        return DeliveryPlatform.grab;
      case 'shopeefood':
        return DeliveryPlatform.shopeefood;
      default:
        return DeliveryPlatform.manual;
    }
  }
}

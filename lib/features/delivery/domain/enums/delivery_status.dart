import 'package:flutter/material.dart';

/// Delivery order status flow:
///   NEW → ACCEPTED → PREPARING → READY_FOR_PICKUP → PICKED_UP → COMPLETED
///                                                             ↘ CANCELLED
enum DeliveryStatus {
  newOrder,
  accepted,
  preparing,
  readyForPickup,
  pickedUp,
  completed,
  cancelled;

  String get value {
    switch (this) {
      case DeliveryStatus.newOrder:
        return 'NEW';
      case DeliveryStatus.accepted:
        return 'ACCEPTED';
      case DeliveryStatus.preparing:
        return 'PREPARING';
      case DeliveryStatus.readyForPickup:
        return 'READY_FOR_PICKUP';
      case DeliveryStatus.pickedUp:
        return 'PICKED_UP';
      case DeliveryStatus.completed:
        return 'COMPLETED';
      case DeliveryStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color get color {
    switch (this) {
      case DeliveryStatus.newOrder:
        return const Color(0xFF2196F3); // blue
      case DeliveryStatus.accepted:
        return const Color(0xFF9C27B0); // purple
      case DeliveryStatus.preparing:
        return const Color(0xFFFF9800); // orange
      case DeliveryStatus.readyForPickup:
        return const Color(0xFF4CAF50); // green
      case DeliveryStatus.pickedUp:
        return const Color(0xFF00BCD4); // cyan
      case DeliveryStatus.completed:
        return const Color(0xFF607D8B); // blue-grey
      case DeliveryStatus.cancelled:
        return const Color(0xFFF44336); // red
    }
  }

  IconData get icon {
    switch (this) {
      case DeliveryStatus.newOrder:
        return Icons.notifications_active;
      case DeliveryStatus.accepted:
        return Icons.check_circle_outline;
      case DeliveryStatus.preparing:
        return Icons.soup_kitchen;
      case DeliveryStatus.readyForPickup:
        return Icons.done_all;
      case DeliveryStatus.pickedUp:
        return Icons.delivery_dining;
      case DeliveryStatus.completed:
        return Icons.task_alt;
      case DeliveryStatus.cancelled:
        return Icons.cancel;
    }
  }

  bool get isActive {
    return this == DeliveryStatus.newOrder ||
        this == DeliveryStatus.accepted ||
        this == DeliveryStatus.preparing ||
        this == DeliveryStatus.readyForPickup;
  }

  bool get isTerminal {
    return this == DeliveryStatus.completed || this == DeliveryStatus.cancelled;
  }

  /// Returns the next logical status, or null if terminal.
  DeliveryStatus? get nextStatus {
    switch (this) {
      case DeliveryStatus.newOrder:
        return DeliveryStatus.accepted;
      case DeliveryStatus.accepted:
        return DeliveryStatus.preparing;
      case DeliveryStatus.preparing:
        return DeliveryStatus.readyForPickup;
      case DeliveryStatus.readyForPickup:
        return DeliveryStatus.pickedUp;
      case DeliveryStatus.pickedUp:
        return DeliveryStatus.completed;
      case DeliveryStatus.completed:
      case DeliveryStatus.cancelled:
        return null;
    }
  }

  static DeliveryStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'NEW':
        return DeliveryStatus.newOrder;
      case 'ACCEPTED':
        return DeliveryStatus.accepted;
      case 'PREPARING':
        return DeliveryStatus.preparing;
      case 'READY_FOR_PICKUP':
        return DeliveryStatus.readyForPickup;
      case 'PICKED_UP':
        return DeliveryStatus.pickedUp;
      case 'COMPLETED':
        return DeliveryStatus.completed;
      case 'CANCELLED':
        return DeliveryStatus.cancelled;
      default:
        return DeliveryStatus.newOrder;
    }
  }
}

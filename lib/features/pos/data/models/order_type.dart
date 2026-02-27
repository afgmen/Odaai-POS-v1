import 'package:flutter/material.dart';

/// 주문 유형 enum (Phase 1: POS UX 개편)
/// - dineIn: 매장 식사
/// - takeaway: 포장
/// - phoneDelivery: 전화 배달
/// - platformDelivery: 플랫폼 배달 (GrabFood, ShopeeFood 등)
enum OrderType {
  dineIn,
  takeaway,
  phoneDelivery,
  platformDelivery;

  String get displayNameEn {
    switch (this) {
      case OrderType.dineIn:
        return 'Dine In';
      case OrderType.takeaway:
        return 'Takeaway';
      case OrderType.phoneDelivery:
        return 'Phone Delivery';
      case OrderType.platformDelivery:
        return 'Platform Delivery';
    }
  }

  String get displayNameVi {
    switch (this) {
      case OrderType.dineIn:
        return 'Ăn tại chỗ';
      case OrderType.takeaway:
        return 'Mang đi';
      case OrderType.phoneDelivery:
        return 'Giao hàng qua điện thoại';
      case OrderType.platformDelivery:
        return 'Giao hàng qua nền tảng';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderType.dineIn:
        return Icons.restaurant;
      case OrderType.takeaway:
        return Icons.shopping_bag_outlined;
      case OrderType.phoneDelivery:
        return Icons.phone_in_talk;
      case OrderType.platformDelivery:
        return Icons.delivery_dining;
    }
  }

  /// DB에 저장되는 문자열 값
  String get dbValue {
    switch (this) {
      case OrderType.dineIn:
        return 'dineIn';
      case OrderType.takeaway:
        return 'takeaway';
      case OrderType.phoneDelivery:
        return 'phoneDelivery';
      case OrderType.platformDelivery:
        return 'platformDelivery';
    }
  }

  /// DB 문자열에서 OrderType으로 변환
  static OrderType fromDb(String value) {
    switch (value) {
      case 'dineIn':
        return OrderType.dineIn;
      case 'takeaway':
        return OrderType.takeaway;
      case 'phoneDelivery':
        return OrderType.phoneDelivery;
      case 'platformDelivery':
        return OrderType.platformDelivery;
      default:
        return OrderType.dineIn;
    }
  }

  /// 주문 유형별 테마 색상
  Color get color {
    switch (this) {
      case OrderType.dineIn:
        return const Color(0xFF4CAF50); // Green
      case OrderType.takeaway:
        return const Color(0xFFFF9800); // Orange
      case OrderType.phoneDelivery:
        return const Color(0xFF2196F3); // Blue
      case OrderType.platformDelivery:
        return const Color(0xFF9C27B0); // Purple
    }
  }
}

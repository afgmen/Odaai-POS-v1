import 'package:flutter/material.dart';

/// 테이블 상태 — Phase 2: 7가지 상태 색상 코딩
enum TableStatus {
  /// 빈 테이블 (사용 가능) — Green
  available('AVAILABLE', 'Available', Color(0xFF4CAF50)),

  /// Reserved (예약 배정됨) — Amber
  reserved('RESERVED', 'Reserved', Color(0xFFFF9800)),

  /// Ordering (주문 중) — Yellow
  ordering('ORDERING', 'Ordering', Color(0xFFFFC107)),

  /// Preparing (조리 중, KDS 연동) — Orange
  preparing('PREPARING', 'Preparing', Color(0xFFFF5722)),

  /// Served (서빙 완료) — Blue
  served('SERVED', 'Served', Color(0xFF2196F3)),

  /// Checkout (결제 대기) — Purple (펄싱 애니메이션)
  checkout('CHECKOUT', 'Checkout', Color(0xFF9C27B0)),

  /// Cleaning (정리 중) — Cyan
  cleaning('CLEANING', 'Cleaning', Color(0xFF00BCD4));

  final String value;
  final String label;
  final Color color;

  const TableStatus(this.value, this.label, this.color);

  /// String → Enum 변환
  static TableStatus fromString(String value) {
    return TableStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TableStatus.available,
    );
  }

  /// 다음 상태로 전환 가능 여부
  bool canTransitionTo(TableStatus next) {
    switch (this) {
      case TableStatus.available:
        return next == TableStatus.reserved || next == TableStatus.ordering;

      case TableStatus.reserved:
        return next == TableStatus.ordering || next == TableStatus.available;

      case TableStatus.ordering:
        return next == TableStatus.preparing;

      case TableStatus.preparing:
        return next == TableStatus.served;

      case TableStatus.served:
        return next == TableStatus.checkout || next == TableStatus.ordering;

      case TableStatus.checkout:
        return next == TableStatus.cleaning;

      case TableStatus.cleaning:
        return next == TableStatus.available;
    }
  }

  /// 자동 전환 가능한 다음 상태 (시간 기반)
  TableStatus? getAutoTransition() {
    switch (this) {
      case TableStatus.checkout:
        return TableStatus.cleaning;
      case TableStatus.cleaning:
        return TableStatus.available;
      default:
        return null;
    }
  }

  /// 자동 전환까지 대기 시간 (분)
  int? getAutoTransitionDelayMinutes() {
    switch (this) {
      case TableStatus.checkout:
        return 5;
      case TableStatus.cleaning:
        return 10;
      default:
        return null;
    }
  }

  /// 상태 아이콘
  IconData get icon {
    switch (this) {
      case TableStatus.available:
        return Icons.check_circle_outline;
      case TableStatus.reserved:
        return Icons.event;
      case TableStatus.ordering:
        return Icons.menu_book;
      case TableStatus.preparing:
        return Icons.restaurant;
      case TableStatus.served:
        return Icons.room_service;
      case TableStatus.checkout:
        return Icons.payment;
      case TableStatus.cleaning:
        return Icons.cleaning_services;
    }
  }

  /// 사용 가능한 모든 상태 목록
  static List<TableStatus> get allStatuses => TableStatus.values;

  /// 활성 상태 목록 (통계용)
  static List<TableStatus> get activeStatuses => [
        TableStatus.reserved,
        TableStatus.ordering,
        TableStatus.preparing,
        TableStatus.served,
        TableStatus.checkout,
        TableStatus.cleaning,
      ];
}

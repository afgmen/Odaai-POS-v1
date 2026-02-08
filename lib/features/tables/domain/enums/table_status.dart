import 'package:flutter/material.dart';

/// 테이블 상태
enum TableStatus {
  /// 빈 테이블 (사용 가능)
  available('AVAILABLE', '빈 테이블', Color(0xFF4CAF50)),

  /// 예약됨 (예약이 배정된 테이블)
  reserved('RESERVED', '예약됨', Color(0xFFFF9800)),

  /// 착석 중 (고객이 식사 중)
  occupied('OCCUPIED', '착석 중', Color(0xFFF44336)),

  /// 계산 완료 (식사 종료, 정리 대기)
  checkout('CHECKOUT', '계산 완료', Color(0xFF9C27B0)),

  /// 정리 중 (테이블 청소/정리)
  cleaning('CLEANING', '정리 중', Color(0xFF2196F3));

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
        // 빈 테이블 → 예약됨 또는 착석 중
        return next == TableStatus.reserved || next == TableStatus.occupied;

      case TableStatus.reserved:
        // 예약됨 → 착석 중 또는 빈 테이블 (예약 취소)
        return next == TableStatus.occupied || next == TableStatus.available;

      case TableStatus.occupied:
        // 착석 중 → 계산 완료
        return next == TableStatus.checkout;

      case TableStatus.checkout:
        // 계산 완료 → 정리 중
        return next == TableStatus.cleaning;

      case TableStatus.cleaning:
        // 정리 중 → 빈 테이블
        return next == TableStatus.available;
    }
  }

  /// 자동 전환 가능한 다음 상태 (시간 기반)
  TableStatus? getAutoTransition() {
    switch (this) {
      case TableStatus.checkout:
        // 결제 완료 후 5분 → 정리 중
        return TableStatus.cleaning;

      case TableStatus.cleaning:
        // 정리 중 10분 후 → 빈 테이블
        return TableStatus.available;

      default:
        return null;
    }
  }

  /// 자동 전환까지 대기 시간 (분)
  int? getAutoTransitionDelayMinutes() {
    switch (this) {
      case TableStatus.checkout:
        return 5; // 5분 후 정리 중으로 전환
      case TableStatus.cleaning:
        return 10; // 10분 후 빈 테이블로 전환
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
      case TableStatus.occupied:
        return Icons.people;
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
        TableStatus.occupied,
        TableStatus.checkout,
        TableStatus.cleaning,
      ];
}

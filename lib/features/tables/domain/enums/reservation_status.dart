import 'package:flutter/material.dart';

/// 예약 상태
enum ReservationStatus {
  /// 예약 대기 (신규 예약, 확인 전)
  pending('PENDING', '예약 대기', Color(0xFF9E9E9E)),

  /// 예약 확정 (매니저 확인 완료)
  confirmed('CONFIRMED', '예약 확정', Color(0xFF4CAF50)),

  /// 착석 완료 (고객이 도착하여 착석)
  seated('SEATED', '착석 완료', Color(0xFF2196F3)),

  /// 예약 취소 (고객 또는 매장에서 취소)
  cancelled('CANCELLED', '예약 취소', Color(0xFFE0E0E0)),

  /// 노쇼 (예약 시간에 나타나지 않음)
  noShow('NO_SHOW', '노쇼', Color(0xFFF44336));

  final String value;
  final String label;
  final Color color;

  const ReservationStatus(this.value, this.label, this.color);

  /// String → Enum 변환
  static ReservationStatus fromString(String value) {
    return ReservationStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReservationStatus.pending,
    );
  }

  /// 다음 상태로 전환 가능 여부
  bool canTransitionTo(ReservationStatus next) {
    switch (this) {
      case ReservationStatus.pending:
        // 예약 대기 → 확정 또는 취소
        return next == ReservationStatus.confirmed ||
            next == ReservationStatus.cancelled;

      case ReservationStatus.confirmed:
        // 예약 확정 → 착석 완료, 노쇼, 취소
        return next == ReservationStatus.seated ||
            next == ReservationStatus.noShow ||
            next == ReservationStatus.cancelled;

      case ReservationStatus.seated:
      case ReservationStatus.cancelled:
      case ReservationStatus.noShow:
        // 종료 상태 → 전환 불가
        return false;
    }
  }

  /// 종료 상태 여부 (더 이상 변경 불가)
  bool get isFinal {
    return this == ReservationStatus.seated ||
        this == ReservationStatus.cancelled ||
        this == ReservationStatus.noShow;
  }

  /// 활성 상태 여부 (현재 유효한 예약)
  bool get isActive {
    return this == ReservationStatus.pending ||
        this == ReservationStatus.confirmed;
  }

  /// 상태 아이콘
  IconData get icon {
    switch (this) {
      case ReservationStatus.pending:
        return Icons.schedule;
      case ReservationStatus.confirmed:
        return Icons.check_circle;
      case ReservationStatus.seated:
        return Icons.event_seat;
      case ReservationStatus.cancelled:
        return Icons.cancel;
      case ReservationStatus.noShow:
        return Icons.error_outline;
    }
  }

  /// 자동 노쇼 처리 가능 여부
  /// 예약 확정 상태에서 예약 시간 + 버퍼(15분) 경과 시 노쇼 처리
  bool canAutoMarkAsNoShow(DateTime reservationDateTime, {int bufferMinutes = 15}) {
    if (this != ReservationStatus.confirmed) return false;

    final now = DateTime.now();
    final deadline = reservationDateTime.add(Duration(minutes: bufferMinutes));
    return now.isAfter(deadline);
  }

  /// 사용 가능한 모든 상태 목록
  static List<ReservationStatus> get allStatuses => ReservationStatus.values;

  /// 활성 상태 목록 (통계용)
  static List<ReservationStatus> get activeStatuses => [
        ReservationStatus.pending,
        ReservationStatus.confirmed,
      ];

  /// 완료 상태 목록 (통계용)
  static List<ReservationStatus> get completedStatuses => [
        ReservationStatus.seated,
        ReservationStatus.cancelled,
        ReservationStatus.noShow,
      ];
}

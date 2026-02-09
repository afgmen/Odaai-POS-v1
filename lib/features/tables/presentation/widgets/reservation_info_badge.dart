import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../database/app_database.dart';
import '../../data/reservations_providers.dart';
import '../../domain/enums/reservation_status.dart';

/// KDS 통합: 예약 정보 배지
/// 주방 디스플레이에서 예약 정보를 표시하는 위젯
class ReservationInfoBadge extends ConsumerWidget {
  final int? reservationId;
  final bool compact;

  const ReservationInfoBadge({
    super.key,
    this.reservationId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reservationId == null) {
      return const SizedBox.shrink();
    }

    final reservationAsync = ref.watch(reservationStreamProvider(reservationId!));

    return reservationAsync.when(
      data: (reservation) {
        if (reservation == null) {
          return const SizedBox.shrink();
        }

        return compact
            ? _buildCompactBadge(reservation)
            : _buildFullBadge(reservation);
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildCompactBadge(Reservation reservation) {
    final status = ReservationStatus.fromString(reservation.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.purple, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_note, size: 12, color: Colors.purple),
          const SizedBox(width: 4),
          Text(
            reservation.customerName,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBadge(Reservation reservation) {
    final status = ReservationStatus.fromString(reservation.status);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note, size: 16, color: Colors.purple),
              const SizedBox(width: 6),
              const Text(
                '예약 주문',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildInfoRow(
            Icons.person,
            '고객',
            reservation.customerName,
          ),
          const SizedBox(height: 4),
          _buildInfoRow(
            Icons.people,
            '인원',
            '${reservation.partySize}명',
          ),
          const SizedBox(height: 4),
          _buildInfoRow(
            Icons.access_time,
            '예약시간',
            reservation.reservationTime,
          ),
          if (reservation.specialRequests != null &&
              reservation.specialRequests!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, size: 14, color: Colors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      reservation.specialRequests!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// KDS에서 예약 주문 여부를 확인하는 헬퍼
class ReservationOrderHelper {
  /// 주문이 예약 주문인지 확인
  static bool isReservationOrder(int? reservationId) {
    return reservationId != null;
  }

  /// 예약 주문 우선순위 계산
  /// 예약 주문은 일반 주문보다 높은 우선순위를 가짐
  static int calculatePriority({
    required bool isReservationOrder,
    required DateTime orderTime,
    String? reservationTime,
  }) {
    if (isReservationOrder && reservationTime != null) {
      // 예약 시간이 가까울수록 우선순위 높음
      final now = DateTime.now();
      final parts = reservationTime.split(':');
      final reservationDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      final diff = reservationDateTime.difference(now).inMinutes;

      if (diff < 15) {
        return 100; // 긴급 (15분 이내)
      } else if (diff < 30) {
        return 80; // 높음 (30분 이내)
      } else {
        return 60; // 중간
      }
    }

    // 일반 주문 우선순위
    final waitingTime = DateTime.now().difference(orderTime).inMinutes;
    if (waitingTime > 20) {
      return 50; // 대기 시간 초과
    } else if (waitingTime > 10) {
      return 30; // 보통
    } else {
      return 10; // 낮음
    }
  }

  /// 예약 주문 알림 메시지 생성
  static String getReservationAlertMessage(
    String customerName,
    String reservationTime,
    int partySize,
  ) {
    final now = DateTime.now();
    final parts = reservationTime.split(':');
    final reservationDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    final diff = reservationDateTime.difference(now).inMinutes;

    if (diff <= 0) {
      return '⚠️ $customerName님 예약 시간 도과! ($partySize명)';
    } else if (diff <= 15) {
      return '🔥 $customerName님 예약 $diff분 전! ($partySize명)';
    } else if (diff <= 30) {
      return '⏰ $customerName님 예약 $diff분 전 ($partySize명)';
    } else {
      return '📋 $customerName님 예약 주문 ($reservationTime, $partySize명)';
    }
  }
}

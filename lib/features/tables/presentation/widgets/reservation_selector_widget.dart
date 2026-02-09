import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../database/app_database.dart';
import '../../data/reservations_providers.dart';
import '../../domain/enums/reservation_status.dart';

/// POS 통합: 예약 선택 위젯
/// 장바구니에서 예약과 연결할 수 있도록 하는 컴포넌트
class ReservationSelectorWidget extends ConsumerStatefulWidget {
  final Function(Reservation?) onReservationSelected;
  final Reservation? selectedReservation;

  const ReservationSelectorWidget({
    super.key,
    required this.onReservationSelected,
    this.selectedReservation,
  });

  @override
  ConsumerState<ReservationSelectorWidget> createState() =>
      _ReservationSelectorWidgetState();
}

class _ReservationSelectorWidgetState
    extends ConsumerState<ReservationSelectorWidget> {
  @override
  Widget build(BuildContext context) {
    final todayReservationsAsync = ref.watch(todayReservationsStreamProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '예약 연결',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (widget.selectedReservation != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: '예약 연결 해제',
                    onPressed: () => widget.onReservationSelected(null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            todayReservationsAsync.when(
              data: (reservations) {
                // 확정된 예약만 필터링
                final confirmedReservations = reservations
                    .where((r) =>
                        r.status == ReservationStatus.confirmed.value ||
                        r.status == ReservationStatus.pending.value)
                    .toList();

                if (confirmedReservations.isEmpty) {
                  return Text(
                    '오늘 예약이 없습니다',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  );
                }

                if (widget.selectedReservation != null) {
                  return _buildSelectedReservation(widget.selectedReservation!);
                }

                return SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: confirmedReservations.length,
                    itemBuilder: (context, index) {
                      final reservation = confirmedReservations[index];
                      return _buildReservationChip(reservation);
                    },
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Text(
                '오류: ${err.toString()}',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationChip(Reservation reservation) {
    final status = ReservationStatus.fromString(reservation.status);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => widget.onReservationSelected(reservation),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(status.icon, size: 14, color: status.color),
                  const SizedBox(width: 4),
                  Text(
                    reservation.customerName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${reservation.reservationTime} / ${reservation.partySize}명',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedReservation(Reservation reservation) {
    final status = ReservationStatus.fromString(reservation.status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.customerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reservation.reservationTime} / ${reservation.partySize}명 / ${reservation.customerPhone}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// POS에서 사용할 예약 선택 상태 Provider
final selectedReservationForPosProvider = StateProvider<Reservation?>((ref) => null);

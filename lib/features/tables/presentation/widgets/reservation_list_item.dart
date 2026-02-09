import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../database/app_database.dart';
import '../../domain/enums/reservation_status.dart';

/// 예약 목록 아이템 위젯
class ReservationListItem extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String) onStatusChange;

  const ReservationListItem({
    super.key,
    required this.reservation,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final status = ReservationStatus.fromString(reservation.status);
    final dateFormat = DateFormat('yyyy-MM-dd (E)', 'ko_KR');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 (이름 + 상태)
              Row(
                children: [
                  Icon(status.icon, color: status.color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reservation.customerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: status.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: status.color),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: status.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 정보 행
              Row(
                children: [
                  _buildInfoChip(
                    Icons.phone,
                    reservation.customerPhone,
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.people,
                    '${reservation.partySize}명',
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 날짜 및 시간
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(reservation.reservationDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    reservation.reservationTime,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // 테이블 정보 (있을 경우)
              if (reservation.tableId != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.table_restaurant, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '테이블 ${reservation.tableId}번',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],

              // 특이사항 (있을 경우)
              if (reservation.specialRequests != null &&
                  reservation.specialRequests!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notes, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reservation.specialRequests!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 액션 버튼 (종료 상태가 아닐 때만)
              if (!status.isFinal) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 상태 변경 버튼
                    _buildActionButton(
                      context,
                      label: _getNextStatusLabel(status),
                      icon: Icons.arrow_forward,
                      color: Colors.blue,
                      onPressed: () {
                        final nextStatus = _getNextStatus(status);
                        if (nextStatus != null) {
                          onStatusChange(nextStatus.value);
                        }
                      },
                    ),
                    const SizedBox(width: 8),

                    // 수정 버튼
                    _buildActionButton(
                      context,
                      label: '수정',
                      icon: Icons.edit,
                      color: Colors.orange,
                      onPressed: onEdit,
                    ),
                    const SizedBox(width: 8),

                    // 삭제 버튼
                    _buildActionButton(
                      context,
                      label: '삭제',
                      icon: Icons.delete,
                      color: Colors.red,
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
    );
  }

  String _getNextStatusLabel(ReservationStatus currentStatus) {
    final nextStatus = _getNextStatus(currentStatus);
    return nextStatus?.label ?? '확정';
  }

  ReservationStatus? _getNextStatus(ReservationStatus currentStatus) {
    switch (currentStatus) {
      case ReservationStatus.pending:
        return ReservationStatus.confirmed;
      case ReservationStatus.confirmed:
        return ReservationStatus.seated;
      default:
        return null;
    }
  }
}

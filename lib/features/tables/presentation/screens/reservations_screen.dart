import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../database/app_database.dart';
import '../../data/reservations_providers.dart';
import '../../domain/enums/reservation_status.dart';
import '../widgets/reservation_form.dart';
import '../widgets/reservation_list_item.dart';

/// 예약 관리 화면 (캘린더 + 예약 목록)
class ReservationsScreen extends ConsumerStatefulWidget {
  const ReservationsScreen({super.key});

  @override
  ConsumerState<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends ConsumerState<ReservationsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedStatus = ref.watch(selectedReservationStatusProvider);
    final filteredReservationsAsync = ref.watch(filteredReservationsProvider);
    final reservationCountAsync = ref.watch(reservationCountByStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('예약 관리'),
        actions: [
          // 통계 표시
          reservationCountAsync.when(
            data: (counts) => _buildStatistics(counts),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),

          // 예약 추가 버튼
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: '예약 추가',
            onPressed: () => _showReservationForm(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 캘린더
          _buildCalendar(selectedDate),

          // 상태 필터
          _buildStatusFilter(selectedStatus),

          // 예약 목록
          Expanded(
            child: filteredReservationsAsync.when(
              data: (reservations) {
                if (reservations.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildReservationList(reservations);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('오류 발생: ${err.toString()}'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 통계 표시
  Widget _buildStatistics(Map<String, int> counts) {
    final confirmedCount = counts['CONFIRMED'] ?? 0;
    final pendingCount = counts['PENDING'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _buildStatBadge('확정', confirmedCount, Colors.green),
          const SizedBox(width: 8),
          _buildStatBadge('대기', pendingCount, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 캘린더 위젯
  Widget _buildCalendar(DateTime selectedDate) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDate, day),
        calendarFormat: _calendarFormat,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
          ref.read(selectedDateProvider.notifier).state = selectedDay;
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          weekendTextStyle: const TextStyle(color: Colors.red),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonShowsNext: false,
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            return FutureBuilder<int>(
              future: ref.read(reservationsDaoProvider).getReservationCountByDate(date),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data! > 0) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${snapshot.data}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),
      ),
    );
  }

  /// 상태 필터
  Widget _buildStatusFilter(String? selectedStatus) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 전체 탭
          _buildFilterTab(
            label: '전체',
            status: null,
            isSelected: selectedStatus == null,
            color: Colors.grey[700]!,
            onTap: () {
              ref.read(selectedReservationStatusProvider.notifier).state = null;
            },
          ),
          const SizedBox(width: 8),

          // 각 상태별 탭
          ...ReservationStatus.allStatuses.map((status) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterTab(
                label: status.label,
                status: status.value,
                isSelected: selectedStatus == status.value,
                color: status.color,
                onTap: () {
                  ref.read(selectedReservationStatusProvider.notifier).state =
                      status.value;
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required String? status,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? color : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  /// 예약 목록
  Widget _buildReservationList(List<Reservation> reservations) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        return ReservationListItem(
          reservation: reservation,
          onTap: () => _showReservationDetail(reservation),
          onEdit: () => _showReservationForm(context, reservation: reservation),
          onDelete: () => _deleteReservation(reservation),
          onStatusChange: (newStatus) =>
              _updateReservationStatus(reservation, newStatus),
        );
      },
    );
  }

  /// 빈 상태
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '예약이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showReservationForm(context),
            icon: const Icon(Icons.add),
            label: const Text('예약 추가'),
          ),
        ],
      ),
    );
  }

  /// 예약 폼 표시
  void _showReservationForm(BuildContext context, {Reservation? reservation}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: ReservationForm(reservation: reservation),
        ),
      ),
    );
  }

  /// 예약 상세 표시
  void _showReservationDetail(Reservation reservation) {
    final status = ReservationStatus.fromString(reservation.status);
    final dateFormat = DateFormat('yyyy-MM-dd (E)', 'ko_KR');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(status.icon, color: status.color),
            const SizedBox(width: 8),
            Text('예약 상세'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('고객명', reservation.customerName),
              _buildDetailRow('연락처', reservation.customerPhone),
              _buildDetailRow('인원', '${reservation.partySize}명'),
              _buildDetailRow(
                '예약일',
                dateFormat.format(reservation.reservationDate),
              ),
              _buildDetailRow('예약 시간', reservation.reservationTime),
              _buildDetailRow('상태', status.label),
              if (reservation.tableId != null)
                _buildDetailRow('테이블', '${reservation.tableId}번'),
              if (reservation.specialRequests != null)
                _buildDetailRow('특이사항', reservation.specialRequests!),
              _buildDetailRow(
                '생성일',
                DateFormat('yyyy-MM-dd HH:mm').format(reservation.createdAt),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          if (!status.isFinal)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showReservationForm(context, reservation: reservation);
              },
              child: const Text('수정'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// 예약 상태 변경
  Future<void> _updateReservationStatus(
      Reservation reservation, String newStatus) async {
    final dao = ref.read(reservationsDaoProvider);
    final success = await dao.updateReservationStatus(
      reservationId: reservation.id,
      status: newStatus,
    );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '예약 상태가 ${ReservationStatus.fromString(newStatus).label}(으)로 변경되었습니다',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 예약 삭제
  Future<void> _deleteReservation(Reservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('예약 삭제'),
        content: Text('${reservation.customerName}님의 예약을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final dao = ref.read(reservationsDaoProvider);
      await dao.deleteReservation(reservation.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약이 삭제되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

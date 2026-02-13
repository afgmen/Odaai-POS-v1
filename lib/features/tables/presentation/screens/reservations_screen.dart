import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedStatus = ref.watch(selectedReservationStatusProvider);
    final filteredReservationsAsync = ref.watch(filteredReservationsProvider);
    final reservationCountAsync = ref.watch(reservationCountByStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reservations),
        actions: [
          // 통계 표시
          reservationCountAsync.when(
            data: (counts) => _buildStatistics(context, counts),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),

          // 예약 추가 버튼
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: l10n.addReservation,
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
                    Text(l10n.errorOccurredWithMessage(err.toString())),
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
  Widget _buildStatistics(BuildContext context, Map<String, int> counts) {
    final l10n = AppLocalizations.of(context)!;
    final confirmedCount = counts['CONFIRMED'] ?? 0;
    final pendingCount = counts['PENDING'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _buildStatBadge(l10n.confirmed, confirmedCount, Colors.green),
          const SizedBox(width: 8),
          _buildStatBadge(l10n.pending, pendingCount, Colors.orange),
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
    final l10n = AppLocalizations.of(context)!;

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
            label: l10n.allReservations,
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
                label: _getLocalizedStatusLabel(l10n, status),
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

  String _getLocalizedStatusLabel(AppLocalizations l10n, ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return l10n.reservationPending;
      case ReservationStatus.confirmed:
        return l10n.reservationConfirmed;
      case ReservationStatus.seated:
        return l10n.reservationSeated;
      case ReservationStatus.cancelled:
        return l10n.reservationCancelled;
      case ReservationStatus.noShow:
        return l10n.reservationNoShow;
    }
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
    final l10n = AppLocalizations.of(context)!;

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
            l10n.noReservations,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showReservationForm(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.addReservation),
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
    final l10n = AppLocalizations.of(context)!;
    final status = ReservationStatus.fromString(reservation.status);
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat('yyyy-MM-dd (E)', locale);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(status.icon, color: status.color),
            const SizedBox(width: 8),
            Text(l10n.reservationDetail),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(l10n.customerName, reservation.customerName),
              _buildDetailRow(l10n.customerPhone, reservation.customerPhone),
              _buildDetailRow(l10n.partySize, l10n.partySizePeople(reservation.partySize)),
              _buildDetailRow(
                l10n.reservationDate,
                dateFormat.format(reservation.reservationDate),
              ),
              _buildDetailRow(l10n.reservationTime, reservation.reservationTime),
              _buildDetailRow(l10n.status, _getLocalizedStatusLabel(l10n, status)),
              if (reservation.tableId != null)
                _buildDetailRow(l10n.table, '${reservation.tableId}'),
              if (reservation.specialRequests != null)
                _buildDetailRow(l10n.specialRequests, reservation.specialRequests!),
              _buildDetailRow(
                l10n.createdAt,
                DateFormat('yyyy-MM-dd HH:mm').format(reservation.createdAt),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          if (!status.isFinal)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showReservationForm(context, reservation: reservation);
              },
              child: Text(l10n.edit),
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
    final l10n = AppLocalizations.of(context)!;
    final dao = ref.read(reservationsDaoProvider);
    final success = await dao.updateReservationStatus(
      reservationId: reservation.id,
      status: newStatus,
    );

    if (mounted && success) {
      final statusLabel = _getLocalizedStatusLabel(l10n, ReservationStatus.fromString(newStatus));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.reservationStatusChanged(statusLabel)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 예약 삭제
  Future<void> _deleteReservation(Reservation reservation) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteReservation),
        content: Text(l10n.deleteReservationConfirm(reservation.customerName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final dao = ref.read(reservationsDaoProvider);
      await dao.deleteReservation(reservation.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.reservationDeleted),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

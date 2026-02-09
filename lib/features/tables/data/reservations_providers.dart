import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import '../../../providers/database_providers.dart';
import 'reservations_dao.dart';

// ============================================================
// DAO Provider
// ============================================================

/// Reservations DAO Provider
final reservationsDaoProvider = Provider<ReservationsDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.reservationsDao;
});

// ============================================================
// Stream Providers (실시간 데이터)
// ============================================================

/// 오늘 예약 스트림
final todayReservationsStreamProvider =
    StreamProvider<List<Reservation>>((ref) {
  final dao = ref.watch(reservationsDaoProvider);
  return dao.watchTodayReservations();
});

/// 날짜별 예약 스트림
final reservationsByDateStreamProvider =
    StreamProvider.family<List<Reservation>, DateTime>(
  (ref, date) {
    final dao = ref.watch(reservationsDaoProvider);
    return dao.watchReservationsByDate(date);
  },
);

/// 상태별 예약 스트림
final reservationsByStatusStreamProvider =
    StreamProvider.family<List<Reservation>, String>(
  (ref, status) {
    final dao = ref.watch(reservationsDaoProvider);
    return dao.watchReservationsByStatus(status);
  },
);

/// 단일 예약 스트림
final reservationStreamProvider = StreamProvider.family<Reservation?, int>(
  (ref, reservationId) {
    final dao = ref.watch(reservationsDaoProvider);
    return dao.watchReservation(reservationId);
  },
);

// ============================================================
// State Providers
// ============================================================

/// 선택된 날짜 (예약 캘린더)
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// 선택된 예약 상태 필터 (null = 전체)
final selectedReservationStatusProvider = StateProvider<String?>((ref) => null);

/// 필터링된 예약 목록 (날짜 + 상태)
final filteredReservationsProvider = StreamProvider<List<Reservation>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final selectedStatus = ref.watch(selectedReservationStatusProvider);
  final reservationsAsync =
      ref.watch(reservationsByDateStreamProvider(selectedDate));

  return reservationsAsync.when(
    data: (reservations) {
      if (selectedStatus == null) {
        return Stream.value(reservations);
      }
      final filtered =
          reservations.where((r) => r.status == selectedStatus).toList();
      return Stream.value(filtered);
    },
    loading: () => Stream.value(<Reservation>[]),
    error: (err, stack) => Stream.value(<Reservation>[]),
  ).asyncExpand((reservations) => Stream.value(reservations));
});

/// 예약 폼 표시 상태
final showReservationFormProvider = StateProvider<bool>((ref) => false);

/// 선택된 예약 ID
final selectedReservationIdProvider = StateProvider<int?>((ref) => null);

/// 예약 상세 모달 표시 상태
final showReservationDetailProvider = StateProvider<bool>((ref) => false);

// ============================================================
// Statistics Providers
// ============================================================

/// 상태별 예약 개수
final reservationCountByStatusProvider =
    FutureProvider<Map<String, int>>((ref) {
  final dao = ref.watch(reservationsDaoProvider);
  return dao.getReservationCountByStatus();
});

/// 오늘 노쇼 개수
final todayNoShowCountProvider = FutureProvider<int>((ref) {
  final dao = ref.watch(reservationsDaoProvider);
  return dao.getTodayNoShowCount();
});

/// 오늘 확정된 예약 개수
final todayConfirmedCountProvider = FutureProvider<int>((ref) {
  final dao = ref.watch(reservationsDaoProvider);
  return dao.getTodayConfirmedCount();
});

/// 날짜별 예약 개수
final reservationCountByDateProvider =
    FutureProvider.family<int, DateTime>((ref, date) {
  final dao = ref.watch(reservationsDaoProvider);
  return dao.getReservationCountByDate(date);
});

/// 예약 취소율 (%)
final cancellationRateProvider = FutureProvider<double>((ref) {
  final dao = ref.watch(reservationsDaoProvider);
  return dao.getCancellationRate();
});

import 'package:drift/drift.dart';

/// 예약 관리 (Reservations)
/// 고객의 테이블 예약 정보를 저장하는 테이블
@DataClassName('Reservation')
class Reservations extends Table {
  /// 예약 ID (Primary Key)
  IntColumn get id => integer().autoIncrement()();

  /// 테이블 ID (Foreign Key to restaurant_tables.id)
  /// 예약이 배정된 테이블 (배정 전에는 null)
  IntColumn get tableId => integer().nullable()();

  /// 고객 이름 (필수)
  TextColumn get customerName => text().withLength(min: 1, max: 100)();

  /// 고객 전화번호 (필수, 10-20자리)
  TextColumn get customerPhone => text().withLength(min: 10, max: 20)();

  /// 예약 인원 수 (필수)
  IntColumn get partySize => integer()();

  /// 예약 날짜 (필수)
  DateTimeColumn get reservationDate => dateTime()();

  /// 예약 시간 (HH:mm 형식, 예: "18:30")
  /// DateTime이 아닌 String으로 저장 (시간만 필요)
  TextColumn get reservationTime => text()();

  /// 예약 상태 (PENDING, CONFIRMED, SEATED, CANCELLED, NO_SHOW)
  /// 기본값: PENDING (예약 대기)
  TextColumn get status => text().withDefault(const Constant('PENDING'))();

  /// 특별 요청 사항 (선택 사항)
  /// 예: "창가 자리", "생일 케이크", "휠체어 접근 필요" 등
  TextColumn get specialRequests => text().nullable()();

  /// 생성 시간
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// 수정 시간
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

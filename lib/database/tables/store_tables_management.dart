import 'package:drift/drift.dart';

/// 테이블 관리 (Table Management)
/// 식당의 물리적 테이블 정보를 저장하는 테이블
@DataClassName('RestaurantTable')
class RestaurantTables extends Table {
  /// 테이블 ID (Primary Key)
  IntColumn get id => integer().autoIncrement()();

  /// 테이블 번호 (예: "1", "2", "A1", "B2")
  /// UNIQUE 제약 조건 - 중복된 테이블 번호 불가
  TextColumn get tableNumber => text().withLength(min: 1, max: 10).unique()();

  /// 좌석 수 (기본값: 4인석)
  IntColumn get seats => integer().withDefault(const Constant(4))();

  /// X 좌표 (드래그앤드롭 레이아웃용, 기본값: 0)
  RealColumn get positionX => real().withDefault(const Constant(0))();

  /// Y 좌표 (드래그앤드롭 레이아웃용, 기본값: 0)
  RealColumn get positionY => real().withDefault(const Constant(0))();

  /// 테이블 상태 (AVAILABLE, RESERVED, OCCUPIED, CHECKOUT, CLEANING)
  /// 기본값: AVAILABLE (빈 테이블)
  TextColumn get status => text().withDefault(const Constant('AVAILABLE'))();

  /// 현재 판매 ID (Foreign Key to sales.id)
  /// 테이블이 OCCUPIED 상태일 때 현재 진행 중인 판매 정보
  IntColumn get currentSaleId => integer().nullable()();

  /// 착석 시간 (테이블이 OCCUPIED 상태가 된 시간)
  DateTimeColumn get occupiedAt => dateTime().nullable()();

  /// 예약 ID (Foreign Key to reservations.id)
  /// 테이블에 예약이 배정된 경우
  IntColumn get reservationId => integer().nullable()();

  /// 활성 상태 (소프트 삭제용)
  /// true = 활성, false = 삭제됨
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// 생성 시간
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// 수정 시간
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {tableNumber}
      ];
}

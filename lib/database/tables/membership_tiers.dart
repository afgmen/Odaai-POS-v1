import 'package:drift/drift.dart';

/// 멤버십 등급 테이블
/// 고객 로열티 프로그램의 등급 정보를 정의합니다.
class MembershipTiers extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 등급 정보
  TextColumn get tierCode => text().unique().named('tier_code')(); // 'bronze', 'silver', 'gold', 'platinum'
  TextColumn get tierNameKey => text().named('tier_name_key')(); // 다국어 키: 'tier_bronze'
  IntColumn get minSpent => integer().named('min_spent')(); // 최소 누적 구매액 (원 단위)

  // 혜택
  RealColumn get pointRate => real().named('point_rate')(); // 적립률 (0.01 = 1%)
  IntColumn get birthdayDiscountPercent => integer().named('birthday_discount_percent').withDefault(const Constant(0))();
  TextColumn get benefits => text().nullable()(); // JSON: 추가 혜택

  // 표시
  IntColumn get displayOrder => integer().named('display_order')(); // 정렬 순서 (1=Bronze, 2=Silver...)
  TextColumn get colorHex => text().named('color_hex')(); // UI 색상: '#CD7F32'
  TextColumn get iconName => text().named('icon_name')(); // 아이콘 이름

  BoolColumn get isActive => boolean().named('is_active').withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
}

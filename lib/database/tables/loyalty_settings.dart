import 'package:drift/drift.dart';

/// 로열티 설정 테이블
/// 포인트 적립/사용 규칙 및 시스템 설정을 저장합니다.
class LoyaltySettings extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get settingKey => text().unique().named('setting_key')();
  TextColumn get settingValue => text().named('setting_value')();
  TextColumn get settingType => text().named('setting_type')(); // 'int', 'double', 'bool', 'string', 'json'
  TextColumn get description => text().nullable()();
  TextColumn get category => text()(); // 'points', 'membership', 'general'

  BoolColumn get isEditable => boolean().named('is_editable').withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(currentDateAndTime)();
}

import 'package:drift/drift.dart';

/// 백업 설정 테이블
/// 자동 백업 스케줄, 보관 정책 등의 설정을 저장합니다.
class BackupSettings extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get settingKey => text().unique().named('setting_key')();
  TextColumn get settingValue => text().named('setting_value')();
  TextColumn get settingType => text().named('setting_type')(); // 'bool', 'int', 'string', 'time'
  TextColumn get description => text().nullable()();
  TextColumn get category => text()(); // 'schedule', 'storage', 'cloud', 'security'

  BoolColumn get isEditable => boolean().named('is_editable').withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(currentDateAndTime)();
}

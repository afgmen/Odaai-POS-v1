import 'package:drift/drift.dart';

/// 권한 감사 로그 테이블
@DataClassName('PermissionLog')
class PermissionLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 작업 수행자
  IntColumn get employeeId => integer()();

  // 작업 타입: 'LOGIN' | 'LOGOUT' | 'REFUND' | 'DISCOUNT' | 'OVERRIDE_REQUEST' | 'OVERRIDE_GRANTED'
  TextColumn get actionType => text()();

  // 작업 대상 (예: sale_id, product_id)
  TextColumn get actionTarget => text().nullable()();

  // 권한 허용 여부
  BoolColumn get permissionGranted => boolean()();

  // 승인자 ID (Manager Override 시)
  IntColumn get approvedByEmployeeId => integer().nullable()();

  // 추가 메타데이터 (JSON 형태)
  TextColumn get metadata => text().nullable()();

  // 생성 시간
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

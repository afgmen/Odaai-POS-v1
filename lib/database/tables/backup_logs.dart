import 'package:drift/drift.dart';

/// 백업 이력 테이블
/// 로컬 및 클라우드 백업의 메타데이터와 상태를 추적합니다.
class BackupLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  // 백업 정보
  TextColumn get backupId => text().unique().named('backup_id')(); // 'backup_20240207_143022'
  TextColumn get backupType => text().named('backup_type')(); // 'auto' | 'manual'
  TextColumn get status => text()(); // 'in_progress' | 'completed' | 'failed'

  // 파일 정보
  TextColumn get fileName => text().named('file_name')();
  IntColumn get fileSize => integer().named('file_size')(); // bytes
  TextColumn get localPath => text().nullable().named('local_path')(); // 로컬 파일 경로
  TextColumn get cloudPath => text().nullable().named('cloud_path')(); // Firebase Storage path
  TextColumn get checksum => text().nullable()(); // SHA-256 for integrity

  // 메타데이터
  IntColumn get recordCount => integer().nullable().named('record_count')(); // 총 레코드 수
  IntColumn get databaseVersion => integer().named('database_version')(); // schema version
  TextColumn get metadata => text().nullable()(); // JSON: tables, sizes, etc

  // 타임스탬프
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();
  DateTimeColumn get uploadedAt => dateTime().nullable().named('uploaded_at')();
  DateTimeColumn get completedAt => dateTime().nullable().named('completed_at')();

  // 복구 정보
  DateTimeColumn get lastRestored => dateTime().nullable().named('last_restored')();
  IntColumn get employeeId => integer().nullable().named('employee_id')();

  // 에러 정보
  TextColumn get errorMessage => text().nullable().named('error_message')();
}

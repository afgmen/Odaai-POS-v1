import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../../../../database/app_database.dart';
import '../../../../providers/database_providers.dart';
import '../../data/backup_dao.dart';

/// BackupDao Provider
final backupDaoProvider = Provider<BackupDao>((ref) {
  return ref.watch(databaseProvider).backupDao;
});

/// BackupService Provider
final backupServiceProvider = Provider<BackupService>((ref) {
  final dao = ref.watch(backupDaoProvider);
  final db = ref.watch(databaseProvider);
  return BackupService(dao, db);
});

/// 백업 타입
enum BackupType {
  auto('auto'),
  manual('manual');

  final String value;
  const BackupType(this.value);
}

/// 백업 상태
enum BackupStatus {
  inProgress('in_progress'),
  completed('completed'),
  failed('failed');

  final String value;
  const BackupStatus(this.value);
}

/// 백업 결과
class BackupResult {
  final bool success;
  final String? backupId;
  final File? backupFile;
  final int? fileSize;
  final String? errorMessage;

  BackupResult({
    required this.success,
    this.backupId,
    this.backupFile,
    this.fileSize,
    this.errorMessage,
  });
}

/// 백업 서비스
class BackupService {
  final BackupDao _dao;
  final AppDatabase _db;

  BackupService(this._dao, this._db);

  // ═══════════════════════════════════════════════════════
  // 로컬 백업
  // ═══════════════════════════════════════════════════════

  /// 백업 생성 (로컬)
  Future<BackupResult> createBackup({
    BackupType type = BackupType.manual,
    int? employeeId,
  }) async {
    final backupId = _generateBackupId();
    int? logId;

    try {
      // 1. 백업 로그 생성
      logId = await _dao.createBackupLog(
        BackupLogsCompanion.insert(
          backupId: backupId,
          backupType: type.value,
          status: BackupStatus.inProgress.value,
          fileName: '$backupId.db',
          fileSize: 0,
          databaseVersion: _db.schemaVersion,
          employeeId: Value(employeeId),
        ),
      );

      // 2. 백업 디렉토리 확인
      final backupDir = await _getBackupDirectory();
      final backupFilePath = path.join(backupDir.path, '$backupId.db');

      // 3. WAL 체크포인트 (데이터 일관성 보장)
      await _performWALCheckpoint();

      // 4. 데이터베이스 파일 복사
      final dbFile = await _getDatabaseFile();
      await dbFile.copy(backupFilePath);

      final backupFile = File(backupFilePath);
      final fileSize = await backupFile.length();

      // 5. 체크섬 생성
      final checksum = await _calculateChecksum(backupFile);

      // 6. 메타데이터 수집
      final metadata = await _collectMetadata();

      // 7. 백업 로그 업데이트
      await _dao.updateBackupLog(
        logId,
        BackupLogsCompanion(
          status: Value(BackupStatus.completed.value),
          fileSize: Value(fileSize),
          localPath: Value(backupFilePath),
          checksum: Value(checksum),
          metadata: Value(jsonEncode(metadata)),
          completedAt: Value(DateTime.now()),
        ),
      );

      // 8. 오래된 백업 정리
      await _cleanupOldBackups();

      return BackupResult(
        success: true,
        backupId: backupId,
        backupFile: backupFile,
        fileSize: fileSize,
      );
    } catch (e) {
      // 실패 시 로그 업데이트
      if (logId != null) {
        await _dao.updateBackupLog(
          logId,
          BackupLogsCompanion(
            status: Value(BackupStatus.failed.value),
            errorMessage: Value(e.toString()),
          ),
        );
      }

      return BackupResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// WAL 체크포인트 실행
  Future<void> _performWALCheckpoint() async {
    try {
      await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (e) {
      // WAL 모드가 아니면 무시
    }
  }

  /// 데이터베이스 파일 경로 가져오기
  Future<File> _getDatabaseFile() async {
    // Drift의 데이터베이스 파일 경로를 찾습니다
    // 플랫폼별로 경로가 다를 수 있음
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(appDocDir.path, 'oda_pos.db');
    return File(dbPath);
  }

  /// 백업 디렉토리 가져오기/생성
  Future<Directory> _getBackupDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(appDocDir.path, 'backups'));

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir;
  }

  /// 백업 ID 생성
  String _generateBackupId() {
    final now = DateTime.now();
    return 'backup_${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '_${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }

  /// 체크섬 계산 (SHA-256)
  Future<String> _calculateChecksum(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return 'sha256:$digest';
  }

  /// 메타데이터 수집
  Future<Map<String, dynamic>> _collectMetadata() async {
    // 테이블별 레코드 수 조회
    final salesCount = await _db.customSelect('SELECT COUNT(*) as count FROM sales').getSingle();
    final productsCount = await _db.customSelect('SELECT COUNT(*) as count FROM products').getSingle();
    final customersCount = await _db.customSelect('SELECT COUNT(*) as count FROM customers').getSingle();

    return {
      'databaseVersion': _db.schemaVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'recordCounts': {
        'sales': salesCount.read<int>('count'),
        'products': productsCount.read<int>('count'),
        'customers': customersCount.read<int>('count'),
      },
    };
  }

  /// 오래된 백업 정리
  Future<void> _cleanupOldBackups() async {
    final settings = await _dao.getAllSettings();
    final maxBackups = int.parse(settings['max_backups_to_keep'] ?? '30');

    // 로그에서 오래된 항목 삭제
    await _dao.deleteOldBackups(maxBackups);

    // 실제 파일도 삭제
    final backupDir = await _getBackupDirectory();
    final allFiles = await backupDir.list().toList();
    final backupFiles = allFiles.whereType<File>().where((f) => f.path.endsWith('.db')).toList();

    if (backupFiles.length > maxBackups) {
      // 날짜순 정렬
      backupFiles.sort((a, b) => b.path.compareTo(a.path));

      // 오래된 파일 삭제
      for (var i = maxBackups; i < backupFiles.length; i++) {
        try {
          await backupFiles[i].delete();
        } catch (_) {
          // 삭제 실패는 무시
        }
      }
    }
  }

  // ═══════════════════════════════════════════════════════
  // 백업 조회 및 관리
  // ═══════════════════════════════════════════════════════

  /// 최근 백업 목록 조회
  Future<List<BackupLog>> getRecentBackups({int limit = 30}) {
    return _dao.getRecentBackups(limit: limit);
  }

  /// 마지막 성공 백업
  Future<BackupLog?> getLastSuccessfulBackup() {
    return _dao.getLastSuccessfulBackup();
  }

  /// 백업 로그 스트림
  Stream<List<BackupLog>> watchBackupLogs({int limit = 30}) {
    return _dao.watchBackupLogs(limit: limit);
  }


  /// 백업에서 복원
  Future<BackupResult> restoreFromBackup(String backupFilePath) async {
    try {
      // 1. 백업 파일 존재 확인
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        return BackupResult(
          success: false,
          errorMessage: 'Backup file not found: $backupFilePath',
        );
      }

      // 2. 파일 복사 (원본 보존)
      final backupDir = await _getBackupDirectory();
      final tempCopy = File(path.join(backupDir.path, 'temp_restore.db'));
      await backupFile.copy(tempCopy.path);

      // 3. 파일 무결성 검증
      if (!await _validateBackupFile(tempCopy.path)) {
        await tempCopy.delete();
        return BackupResult(
          success: false,
          errorMessage: 'Invalid backup file (corrupted or wrong format)',
        );
      }

      // 4. 기존 데이터 백업 (복원 실패 시 롤백용)
      final rollbackBackup = await createBackup(
        type: BackupType.auto,
      );

      if (!rollbackBackup.success) {
        await tempCopy.delete();
        return BackupResult(
          success: false,
          errorMessage: 'Failed to create rollback backup',
        );
      }

      // 5. 데이터 복원 실행
      try {
        await _performRestore(tempCopy.path);
        
        // 6. 임시 파일 삭제
        await tempCopy.delete();

        return BackupResult(
          success: true,
          backupFile: backupFile,
        );
      } catch (restoreError) {
        // 복원 실패 시 롤백
        if (rollbackBackup.backupFile != null) {
          await _performRestore(rollbackBackup.backupFile!.path);
        }
        
        await tempCopy.delete();
        
        return BackupResult(
          success: false,
          errorMessage: 'Restore failed: ${restoreError.toString()}',
        );
      }
    } catch (e) {
      return BackupResult(
        success: false,
        errorMessage: 'Restore error: ${e.toString()}',
      );
    }
  }

  /// 백업 파일 검증
  Future<bool> _validateBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      final stats = await file.stat();
      
      // 파일 크기 확인 (최소 1KB)
      if (stats.size < 1024) {
        return false;
      }

      // SQLite 파일 헤더 확인
      final bytes = await file.openRead(0, 16).first;
      final header = String.fromCharCodes(bytes.take(15));
      
      return header.startsWith('SQLite format 3');
    } catch (e) {
      return false;
    }
  }

  /// 실제 복원 수행
  Future<void> _performRestore(String backupFilePath) async {
    // 1. WAL 체크포인트
    await _performWALCheckpoint();

    // 2. 연결 닫기
    await _db.close();

    // 3. 현재 DB 파일 경로
    final currentDbPath = await _getDatabasePath();

    // 4. 백업으로 덮어쓰기
    final backupFile = File(backupFilePath);
    await backupFile.copy(currentDbPath);

    // 5. WAL 및 SHM 파일 삭제 (재생성 필요)
    final walFile = File('$currentDbPath-wal');
    final shmFile = File('$currentDbPath-shm');
    
    if (await walFile.exists()) {
      await walFile.delete();
    }
    if (await shmFile.exists()) {
      await shmFile.delete();
    }

    // 6. DB 재연결 (AppDatabase가 자동으로 처리)
    // Note: 앱 재시작 권장
  }

  /// 데이터베이스 경로 가져오기
  Future<String> _getDatabasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'oda_pos.db');
  }


  /// 백업 삭제 (파일 + 로그)
  Future<bool> deleteBackup(BackupLog backup) async {
    try {
      // 1. 로컬 파일 삭제
      if (backup.localPath != null) {
        final file = File(backup.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // 2. 로그 삭제
      await _dao.deleteBackup(backup.id);

      return true;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════
  // 설정
  // ═══════════════════════════════════════════════════════

  /// 모든 설정 조회
  Future<Map<String, String>> getAllSettings() {
    return _dao.getAllSettings();
  }

  /// 설정 업데이트
  Future<bool> updateSetting(String key, String value) {
    return _dao.updateSetting(key, value);
  }

  /// 설정 스트림
  Stream<Map<String, String>> watchSettings() {
    return _dao.watchSettings();
  }

  // ═══════════════════════════════════════════════════════
  // 통계
  // ═══════════════════════════════════════════════════════

  /// 백업 통계
  Future<BackupStats> getBackupStats() async {
    final totalSize = await _dao.getTotalBackupSize();
    final totalCount = await _dao.getCompletedBackupCount();
    final recentCount = await _dao.getBackupsInLast24Hours();
    final typeStats = await _dao.getBackupStatsByType();

    return BackupStats(
      totalBackups: totalCount,
      totalSize: totalSize,
      recentBackups: recentCount,
      autoBackups: typeStats['auto'] ?? 0,
      manualBackups: typeStats['manual'] ?? 0,
    );
  }
}

/// 백업 통계
class BackupStats {
  final int totalBackups;
  final int totalSize;
  final int recentBackups;
  final int autoBackups;
  final int manualBackups;

  BackupStats({
    required this.totalBackups,
    required this.totalSize,
    required this.recentBackups,
    required this.autoBackups,
    required this.manualBackups,
  });

  String get formattedSize {
    if (totalSize < 1024) return '${totalSize}B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

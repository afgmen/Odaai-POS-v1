# QC Report: 테스트 커버리지 강화 + CI 개선

**날짜**: 2026-03-01
**Reviewer**: Mama (QC Subagent)

## Summary
- Result: ❌ **FAIL** (Backup 테스트에 컴파일 에러 존재)
- 이전 테스트 수: 463
- 현재 테스트 수: 487 (컴파일 에러로 실제 실행된 것은 487개)
- 새 테스트 추가: 37개 (Floor Plan: 24개, Backup: 13개)

## CI 워크플로우
- flutter test 단계: ✅ **PASS**
- `.github/workflows/*.yml`에 `flutter test --reporter compact` 단계 추가 확인됨
- `Run tests` 단계가 `build_runner` 이후, APK 빌드 전에 실행되도록 올바르게 배치됨

## Floor Plan 테스트
- 파일 수: 1개 (`floor_plan_designer_provider_test.dart`)
- 테스트 케이스 수: **24개** (목표: 15+ → ✅ 초과 달성)
- 테스트 범위:
  - FloorZone CRUD: create, read, update, delete, duplicate name 처리
  - FloorElement CRUD: create, update, delete, 위치 변경, zone 이동
  - Bulk operations: 여러 요소 동시 삭제, zone 삭제 시 cascade
  - Edge cases: 빈 이름 zone, 범위 밖 좌표
- 테스트 품질: ✅ **양호**
  - 실제 DAO와 in-memory DB를 사용하여 통합 테스트 수준
  - 각 CRUD 작업마다 결과 검증 포함
  - Edge case와 error handling도 커버
- 전부 통과: ✅ **PASS**
- Analyze 경고:
  - ⚠️ Unused imports 2개 (`floor_zones.dart`, `floor_elements.dart`)
  - ⚠️ Unused local variables 2개 (`id` 변수)
  - ℹ️ `matcher` 패키지가 dev_dependencies에 없음

## Backup/Restore 테스트
- 파일 수: 1개 (`backup_restore_test.dart`)
- 테스트 케이스 수: **13개** (목표: 8+ → ✅ 초과 달성)
- 테스트 범위:
  - Backup creation (manual, automatic)
  - Restore operations
  - Backup validation
  - Retention policy (old backup deletion)
  - Backup deletion
- 테스트 품질: ⚠️ **컴파일 에러로 인한 미완성**
- 전부 통과: ❌ **FAIL**

### 🔴 Critical Issues - Backup Tests
다음 메서드들이 실제 구현체에 존재하지 않아 컴파일 에러 발생:

1. **`BackupDao.getAllBackupLogs()`** - 2회 호출
   - 라인 249, 256
   - 실제 DAO에 이 메서드가 정의되지 않음

2. **`BackupService.deleteOldBackups(daysToKeep)`**
   - 라인 253
   - BackupService에 retention policy 메서드 미구현

3. **`BackupDao.getBackupLogById()`**
   - 라인 267
   - 특정 backup log 조회 메서드 미구현

4. **`BackupService.deleteBackup()` 파라미터 타입 불일치**
   - 라인 264
   - 현재: `String` 전달
   - 필요: `BackupLog` 객체 전달

5. **`isNull` 이름 충돌**
   - 라인 268
   - `drift`와 `flutter_test` 양쪽에서 `isNull` import됨
   - 명시적으로 `matcher.isNull` 또는 `drift.isNull` 사용 필요

### 테스트 에러 상세
```
test/features/backup/backup_restore_test.dart:249:36: Error: undefined_method 'getAllBackupLogs'
test/features/backup/backup_restore_test.dart:253:27: Error: undefined_method 'deleteOldBackups'
test/features/backup/backup_restore_test.dart:256:45: Error: undefined_method 'getAllBackupLogs'
test/features/backup/backup_restore_test.dart:264:62: Error: argument_type_not_assignable (String → BackupLog)
test/features/backup/backup_restore_test.dart:267:36: Error: undefined_method 'getBackupLogById'
test/features/backup/backup_restore_test.dart:268:20: Error: ambiguous_import 'isNull'
```

## flutter analyze
- 결과: ⚠️ **83 issues found**
- Floor Plan 관련: 5개 (3 warnings, 2 info) - 경미한 수준
- Backup 관련: 6개 (5 errors, 1 warning) - 치명적
- 기타 프로젝트 전체: 72개 (기존 이슈)

## Issues / Recommendations

### 🔥 Immediate Actions Required (P0)
1. **Backup 테스트 컴파일 에러 수정 필요**
   - `BackupDao`에 다음 메서드 추가:
     - `getAllBackupLogs()`
     - `getBackupLogById(int id)`
   - `BackupService`에 다음 메서드 추가:
     - `deleteOldBackups({required int daysToKeep})`
   - `deleteBackup()` 메서드 시그니처 확인 및 호출부 수정
   - `isNull` import 충돌 해결 (명시적 import prefix 사용)

2. **테스트 재실행 필요**
   - 위 수정 후 `flutter test` 재실행하여 487개 → 500개 모두 통과 확인

### ⚠️ Code Quality Improvements (P1)
3. **Floor Plan 테스트 정리**
   - Unused imports 제거 (`floor_zones.dart`, `floor_elements.dart`)
   - Unused variables 제거 또는 실제 사용
   - `matcher` 패키지를 `dev_dependencies`에 추가

4. **Analyze 경고 전체 점검**
   - 현재 83개 이슈 중 대부분이 기존 프로젝트 코드
   - 신규 테스트 관련 이슈만 먼저 수정하고, 나머지는 별도 태스크로 분리 권장

## Positive Highlights ✨
- ✅ CI 워크플로우 성공적 통합
- ✅ Floor Plan 테스트 목표 초과 달성 (24 vs 15)
- ✅ Backup 테스트 케이스 수 목표 초과 (13 vs 8)
- ✅ 테스트 품질 양호 (Floor Plan은 모두 통과, edge case 포함)
- ✅ 전체 테스트 수 463 → 487로 증가 (5.2% 상승)

## Next Steps
1. Dede에게 Backup 테스트 컴파일 에러 수정 요청
2. 수정 후 CI에서 자동 테스트 실행 확인
3. Analyze 경고 정리 태스크 별도 생성 고려

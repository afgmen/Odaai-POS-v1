# 직원 권한 관리 시스템 (Staff Permission Management System) - Design Document

> **Summary**: PIN 기반 인증과 역할별 권한 제어(RBAC)를 통해 POS 시스템의 보안을 강화하고 직원별 접근 제어를 구현
>
> **Project**: Oda POS
> **Version**: 1.0.0
> **Author**: Claude (AI Agent)
> **Date**: 2026-02-09
> **Status**: Draft
> **Planning Doc**: [staff-permission-system.plan.md](../../01-plan/features/staff-permission-system.plan.md)

### Pipeline References

| Phase | Document | Status |
|-------|----------|--------|
| Phase 1 | Schema Definition | ✅ (existing database) |
| Phase 2 | Coding Conventions | ✅ (Flutter/Dart conventions) |
| Phase 3 | Mockup | N/A (internal feature) |
| Phase 4 | API Spec | N/A (local-first architecture) |

---

## 1. Overview

### 1.1 Design Goals

1. **보안 강화**: PIN 기반 인증으로 무단 접근 방지 및 중요 기능 보호
2. **역할 기반 제어**: 3가지 역할(Manager, Cashier, Kitchen)에 따른 자동 권한 관리
3. **유연한 운영**: 관리자 승인(Manager Override)으로 긴급 상황 대응
4. **추적 가능성**: 모든 권한 관련 작업을 감사 로그로 기록
5. **빠른 인증**: 3초 이내 로그인으로 업무 효율성 유지
6. **확장 가능성**: 새로운 역할 및 권한 추가 용이

### 1.2 Design Principles

- **Single Responsibility Principle**: 각 Provider는 단일 책임(Auth, Permission, Logging)만 담당
- **Separation of Concerns**: 인증(Authentication)과 권한(Authorization)의 명확한 분리
- **Fail-Safe**: 권한 체크 실패 시 안전하게 차단 (기본값: 접근 거부)
- **Performance First**: 권한 체크를 메모리 캐시로 최적화 (10ms 이내 응답)
- **User-Centric**: 직원 역할에 맞는 맞춤형 UI 자동 제공
- **Audit-Ready**: 모든 보안 관련 작업 추적 가능

---

## 2. Architecture

### 2.1 Component Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                      Presentation Layer (Flutter UI)                 │
│  ┌──────────────┐  ┌─────────────────┐  ┌──────────────────────┐   │
│  │  PIN Login   │  │  Permission     │  │  Manager Override    │   │
│  │  Screen      │  │  Gate Widget    │  │  Dialog              │   │
│  └──────────────┘  └─────────────────┘  └──────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
                                  ↓
┌──────────────────────────────────────────────────────────────────────┐
│                    Application Layer (Riverpod Providers)            │
│  ┌──────────────┐  ┌─────────────────┐  ┌──────────────────────┐   │
│  │  Auth        │  │  Permission     │  │  Audit Logging       │   │
│  │  Provider    │  │  Provider       │  │  Provider            │   │
│  └──────────────┘  └─────────────────┘  └──────────────────────┘   │
│       ↓                    ↓                       ↓                 │
│  - login()            - checkPerm()            - logAction()         │
│  - logout()           - hasRole()              - logAttempt()        │
│  - validatePIN()      - requestOverride()      - logOverride()       │
└──────────────────────────────────────────────────────────────────────┘
                                  ↓
┌──────────────────────────────────────────────────────────────────────┐
│                    Domain Layer (Business Logic)                     │
│  ┌──────────────┐  ┌─────────────────┐  ┌──────────────────────┐   │
│  │  UserRole    │  │  Permission     │  │  Session             │   │
│  │  Enum        │  │  Enum           │  │  Model               │   │
│  └──────────────┘  └─────────────────┘  └──────────────────────┘   │
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  RolePermissionMap (Static Configuration)                   │   │
│  │  - MANAGER → All Permissions                                │   │
│  │  - CASHIER → Limited Permissions                            │   │
│  │  - KITCHEN → KDS Only                                       │   │
│  └──────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
                                  ↓
┌──────────────────────────────────────────────────────────────────────┐
│                    Data Layer (Drift + SQLite)                       │
│  ┌──────────────┐  ┌─────────────────┐  ┌──────────────────────┐   │
│  │  Employees   │  │  Permission     │  │  Utility             │   │
│  │  DAO         │  │  Logs DAO       │  │  (PIN Hasher)        │   │
│  └──────────────┘  └─────────────────┘  └──────────────────────┘   │
│       ↓                    ↓                       ↓                 │
│  ┌──────────────┐  ┌─────────────────┐                              │
│  │  employees   │  │  permission_logs│                              │
│  │  (table)     │  │  (table)        │                              │
│  └──────────────┘  └─────────────────┘                              │
└──────────────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow

#### 로그인 플로우
```
User Input (PIN)
  → PinLoginScreen.onSubmit()
  → AuthProvider.login(employeeId, pin)
  → EmployeesDao.verifyPIN(employeeId, hashedPin)
  → Match?
    ├─ YES → Create Session Token (UUID)
    │      → Save session to employees table
    │      → PermissionProvider.loadPermissions(employee)
    │      → AuditLoggingProvider.logAction(LOGIN_SUCCESS)
    │      → Navigate to main screen
    └─ NO  → AuditLoggingProvider.logAction(LOGIN_FAILED)
           → Show error message
```

#### 권한 체크 플로우
```
User Action (e.g., Refund Button Tap)
  → PermissionGateWidget.onTap()
  → PermissionProvider.checkPermission(Permission.REFUND_UNLIMITED)
  → Has Permission?
    ├─ YES → Execute Action
    │      → AuditLoggingProvider.logAction(ACTION_GRANTED)
    └─ NO  → Show ManagerOverrideDialog
           → Manager enters PIN
           → AuthProvider.validateManagerPIN(pin)
           → Valid?
             ├─ YES → AuditLoggingProvider.logOverride(action, approver)
             │      → Execute Action
             └─ NO  → AuditLoggingProvider.logAttempt(OVERRIDE_FAILED)
                    → Show error
```

#### 세션 관리 플로우
```
Session Created
  → Set expiry_time = now + 8 hours
  → Start inactivity timer (5 minutes)
  → On user activity → Reset timer
  → On timer expire → AuthProvider.logout()
  → On app close → Session persists (until expiry_time)
  → On app reopen → Check expiry_time
    ├─ Valid → Resume session
    └─ Expired → Redirect to login
```

### 2.3 Dependencies

| Component | Depends On | Purpose |
|-----------|-----------|---------|
| PinLoginScreen | AuthProvider | 인증 처리 |
| PermissionGateWidget | PermissionProvider | 권한 체크 |
| AuthProvider | EmployeesDao, crypto (SHA-256) | PIN 검증 및 세션 관리 |
| PermissionProvider | AuthProvider (current session) | 현재 사용자의 권한 정보 조회 |
| AuditLoggingProvider | PermissionLogsDao | 감사 로그 기록 |
| EmployeesDao | employees table | 직원 데이터 CRUD |
| PermissionLogsDao | permission_logs table | 로그 데이터 CRUD |

---

## 3. Data Model

### 3.1 Entity Definition

#### Employee (기존 확장)
```dart
// lib/database/tables/employees.dart
import 'package:drift/drift.dart';

class Employees extends Table {
  // 기존 필드
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get name => text()();
  TextColumn get passwordHash => text()();  // 기존 (사용 안 함)
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // 신규 필드 (마이그레이션 필요)
  TextColumn get role => text().withDefault(const Constant('CASHIER'))();
  TextColumn get pinHash => text().nullable()();  // SHA-256 해시
  DateTimeColumn get pinChangedAt => dateTime().nullable()();
  DateTimeColumn get lastLoginAt => dateTime().nullable()();
  TextColumn get sessionToken => text().nullable()();  // UUID v4
  DateTimeColumn get sessionExpiresAt => dateTime().nullable()();
}

// Generated class
@DataClassName('Employee')
class Employee {
  final int id;
  final String username;
  final String name;
  final String passwordHash;  // 레거시 (무시)
  final String role;  // 'MANAGER' | 'CASHIER' | 'KITCHEN'
  final String? pinHash;
  final DateTime? pinChangedAt;
  final DateTime? lastLoginAt;
  final String? sessionToken;
  final DateTime? sessionExpiresAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### PermissionLog (신규 테이블)
```dart
// lib/database/tables/permission_logs.dart
import 'package:drift/drift.dart';

@DataClassName('PermissionLog')
class PermissionLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get employeeId => integer()();
  TextColumn get actionType => text()();  // 'LOGIN' | 'LOGOUT' | 'REFUND' | 'DISCOUNT' | 'OVERRIDE_REQUEST' | 'OVERRIDE_GRANTED'
  TextColumn get actionTarget => text().nullable()();  // 대상 (예: sale_id, product_id)
  BoolColumn get permissionGranted => boolean()();
  IntColumn get approvedByEmployeeId => integer().nullable()();  // 승인자 ID (Manager Override 시)
  TextColumn get metadata => text().nullable()();  // JSON 형태의 추가 정보
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### Session Model (Domain)
```dart
// lib/features/auth/domain/session.dart
class Session {
  final int employeeId;
  final String employeeName;
  final UserRole role;
  final String token;
  final DateTime expiresAt;
  final DateTime lastActivityAt;

  Session({
    required this.employeeId,
    required this.employeeName,
    required this.role,
    required this.token,
    required this.expiresAt,
    required this.lastActivityAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isInactive => DateTime.now().difference(lastActivityAt).inMinutes > 5;

  Session copyWithActivity() {
    return Session(
      employeeId: employeeId,
      employeeName: employeeName,
      role: role,
      token: token,
      expiresAt: expiresAt,
      lastActivityAt: DateTime.now(),
    );
  }
}
```

### 3.2 Entity Relationships

```
[Employee] 1 ──── N [PermissionLog] (as employee)
    │
    └── 1 ──── N [PermissionLog] (as approver)

[Employee] 1 ──── 1 [Session] (in-memory, derived from employee.sessionToken)
```

### 3.3 Database Schema

#### Migration Script
```sql
-- Migration v5: Add permission system fields to employees
ALTER TABLE employees ADD COLUMN role TEXT NOT NULL DEFAULT 'CASHIER';
ALTER TABLE employees ADD COLUMN pin_hash TEXT;
ALTER TABLE employees ADD COLUMN pin_changed_at INTEGER;
ALTER TABLE employees ADD COLUMN last_login_at INTEGER;
ALTER TABLE employees ADD COLUMN session_token TEXT;
ALTER TABLE employees ADD COLUMN session_expires_at INTEGER;

-- Migration v6: Create permission_logs table
CREATE TABLE permission_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  employee_id INTEGER NOT NULL,
  action_type TEXT NOT NULL,
  action_target TEXT,
  permission_granted INTEGER NOT NULL,  -- 0 = false, 1 = true
  approved_by_employee_id INTEGER,
  metadata TEXT,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
  FOREIGN KEY (approved_by_employee_id) REFERENCES employees(id) ON DELETE SET NULL
);

CREATE INDEX idx_permission_logs_employee ON permission_logs(employee_id);
CREATE INDEX idx_permission_logs_created ON permission_logs(created_at);
CREATE INDEX idx_permission_logs_action ON permission_logs(action_type);
```

#### Drift Migration Code
```dart
// lib/database/app_database.dart
@override
int get schemaVersion => 6;

@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 5) {
        // Add permission system fields
        await m.addColumn(employees, employees.role);
        await m.addColumn(employees, employees.pinHash);
        await m.addColumn(employees, employees.pinChangedAt);
        await m.addColumn(employees, employees.lastLoginAt);
        await m.addColumn(employees, employees.sessionToken);
        await m.addColumn(employees, employees.sessionExpiresAt);
      }
      if (from < 6) {
        // Create permission_logs table
        await m.createTable(permissionLogs);
      }
    },
  );
}
```

---

## 4. API Specification (DAO Methods)

### 4.1 EmployeesDao Extensions

| Method | Parameters | Returns | Description |
|--------|-----------|---------|-------------|
| `setPIN` | employeeId, plainPin | Future\<bool\> | PIN 설정 (SHA-256 해시 저장) |
| `verifyPIN` | employeeId, plainPin | Future\<bool\> | PIN 검증 |
| `createSession` | employeeId | Future\<String\> | 세션 토큰 생성 및 저장 |
| `getSessionInfo` | employeeId | Future\<Session?\> | 세션 정보 조회 |
| `clearSession` | employeeId | Future\<void\> | 세션 삭제 (로그아웃) |
| `updateLastLogin` | employeeId | Future\<void\> | 최종 로그인 시간 갱신 |

### 4.2 PermissionLogsDao Methods

| Method | Parameters | Returns | Description |
|--------|-----------|---------|-------------|
| `logAction` | log: PermissionLogsCompanion | Future\<int\> | 로그 기록 |
| `getLogsByEmployee` | employeeId, limit | Future\<List\<PermissionLog\>\> | 직원별 로그 조회 |
| `getLogsByDateRange` | startDate, endDate | Future\<List\<PermissionLog\>\> | 기간별 로그 조회 |
| `getOverrideRequests` | - | Future\<List\<PermissionLog\>\> | 관리자 승인 요청 로그 |
| `deleteOldLogs` | daysOld | Future\<int\> | 오래된 로그 삭제 (기본 90일) |

### 4.3 Detailed Specification

#### `setPIN(employeeId, plainPin)`

**Parameters:**
```dart
int employeeId;      // 직원 ID
String plainPin;     // 평문 PIN (4-6자리 숫자)
```

**Process:**
1. plainPin 유효성 검증 (4-6자리 숫자)
2. SHA-256 해시 생성
3. employees 테이블 업데이트 (pin_hash, pin_changed_at)

**Returns:**
```dart
Future<bool>  // true: 성공, false: 실패
```

**Example:**
```dart
final success = await employeesDao.setPIN(1, '1234');
if (success) {
  print('PIN 설정 성공');
}
```

#### `verifyPIN(employeeId, plainPin)`

**Parameters:**
```dart
int employeeId;
String plainPin;
```

**Process:**
1. Employee 조회 (employeeId)
2. plainPin을 SHA-256 해시로 변환
3. DB의 pin_hash와 비교

**Returns:**
```dart
Future<bool>  // true: 일치, false: 불일치
```

**Error Cases:**
- Employee not found → false
- PIN not set → false
- Invalid PIN format → false

#### `createSession(employeeId)`

**Parameters:**
```dart
int employeeId;
```

**Process:**
1. UUID v4 토큰 생성
2. 만료 시간 계산 (현재 + 8시간)
3. employees 테이블 업데이트 (session_token, session_expires_at)

**Returns:**
```dart
Future<String>  // 생성된 세션 토큰
```

---

## 5. UI/UX Design

### 5.1 Screen Layout

#### 로그인 화면 (PinLoginScreen)
```
┌─────────────────────────────────────────┐
│                                         │
│         🏪 Oda POS                      │
│         직원 로그인                      │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  직원 선택                         │  │
│  │  ▼ 김철수 (직원)                  │  │
│  └───────────────────────────────────┘  │
│                                         │
│  PIN 코드 입력                          │
│  ┌───┬───┬───┐                         │
│  │ 1 │ 2 │ 3 │                         │
│  ├───┼───┼───┤                         │
│  │ 4 │ 5 │ 6 │                         │
│  ├───┼───┼───┤                         │
│  │ 7 │ 8 │ 9 │                         │
│  ├───┼───┼───┤                         │
│  │ ← │ 0 │ ✓ │                         │
│  └───┴───┴───┘                         │
│                                         │
│  [ ● ● ● ● ]  (PIN 입력 표시)          │
│                                         │
│  [        로그인        ]               │
│                                         │
│  PIN을 잊으셨나요? 관리자에게 문의하세요 │
│                                         │
└─────────────────────────────────────────┘
```

#### 권한 거부 다이얼로그 (ManagerOverrideDialog)
```
┌─────────────────────────────────────────┐
│  ⚠️ 관리자 권한 필요                     │
├─────────────────────────────────────────┤
│                                         │
│  환불 처리는 관리자 권한이 필요합니다.    │
│                                         │
│  요청자: 김철수 (직원)                   │
│  작업: 환불 처리 (₩50,000)              │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  관리자 PIN을 입력하세요           │  │
│  │  [ ● ● ● ● ]                      │  │
│  └───────────────────────────────────┘  │
│                                         │
│  [  취소  ]        [  승인  ]           │
│                                         │
└─────────────────────────────────────────┘
```

#### 권한 게이트 위젯 (PermissionGateWidget)
```dart
// 사용 예시
PermissionGateWidget(
  permission: Permission.REFUND_UNLIMITED,
  child: ElevatedButton(
    onPressed: () => _processRefund(),
    child: Text('환불 처리'),
  ),
  onPermissionDenied: () {
    // 관리자 승인 다이얼로그 표시
    _showManagerOverrideDialog();
  },
)
```

### 5.2 User Flow

#### 로그인 플로우
```
앱 시작
  → 로그인 화면
  → 직원 선택
  → PIN 입력 (터치패드)
  → 검증 중...
  → 성공?
    ├─ YES → 역할별 메인 화면
    │      - MANAGER: 전체 POS 화면
    │      - CASHIER: 단순화된 POS 화면
    │      - KITCHEN: KDS 화면으로 자동 이동
    └─ NO  → 에러 메시지
           → 재시도 (5회까지)
           → 5회 초과 시 1분 대기
```

#### 권한 체크 플로우
```
기능 실행 시도 (예: 환불 버튼 클릭)
  → PermissionGateWidget.checkPermission()
  → 권한 있음?
    ├─ YES → 기능 실행
    └─ NO  → 관리자 승인 다이얼로그 표시
           → 관리자 PIN 입력
           → 검증 성공?
             ├─ YES → 로그 기록 + 기능 실행
             └─ NO  → 에러 메시지
```

### 5.3 Component List

| Component | Location | Responsibility |
|-----------|----------|----------------|
| PinLoginScreen | `lib/features/auth/presentation/screens/` | 로그인 화면 |
| PinPadWidget | `lib/features/auth/presentation/widgets/` | 숫자 패드 입력 위젯 |
| PermissionGateWidget | `lib/features/auth/presentation/widgets/` | 권한 체크 래퍼 위젯 |
| ManagerOverrideDialog | `lib/features/auth/presentation/dialogs/` | 관리자 승인 다이얼로그 |
| SessionBadge | `lib/features/auth/presentation/widgets/` | 현재 로그인 직원 표시 배지 |
| AuditLogScreen | `lib/features/auth/presentation/screens/` | 감사 로그 조회 화면 (관리자 전용) |

---

## 6. Error Handling

### 6.1 Error Code Definition

| Code | Message | Cause | Handling |
|------|---------|-------|----------|
| `AUTH_001` | Invalid PIN | PIN 불일치 | 재시도 안내 (남은 횟수 표시) |
| `AUTH_002` | Account locked | 5회 실패 후 잠김 | 1분 대기 안내 |
| `AUTH_003` | Session expired | 세션 만료 (8시간) | 재로그인 안내 |
| `AUTH_004` | Session inactive | 5분 무작동 | 재로그인 안내 |
| `PERM_001` | Permission denied | 권한 없음 | 관리자 승인 옵션 제공 |
| `PERM_002` | Manager override failed | 승인 PIN 불일치 | 재시도 안내 |
| `PERM_003` | No manager available | 관리자 계정 없음 | 시스템 오류 안내 |

### 6.2 Error Response Format

```dart
// lib/features/auth/domain/auth_error.dart
class AuthError implements Exception {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  AuthError({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => '[$code] $message';
}

// 사용 예시
throw AuthError(
  code: 'AUTH_001',
  message: '잘못된 PIN입니다.',
  details: {'attemptsLeft': 4},
);
```

### 6.3 Error Handling Strategy

```dart
// Provider에서 에러 처리
try {
  await authProvider.login(employeeId, pin);
} on AuthError catch (e) {
  if (e.code == 'AUTH_001') {
    // 잘못된 PIN
    showSnackBar('PIN이 일치하지 않습니다. (${e.details['attemptsLeft']}회 남음)');
  } else if (e.code == 'AUTH_002') {
    // 계정 잠김
    showDialog('계정이 잠겼습니다. 1분 후 다시 시도해주세요.');
  }
} catch (e) {
  // 예상치 못한 오류
  showDialog('시스템 오류가 발생했습니다. 관리자에게 문의하세요.');
  logError(e);
}
```

---

## 7. Security Considerations

### 7.1 Security Checklist

- [x] **PIN 암호화**: SHA-256 해시로 저장 (평문 저장 금지)
- [x] **세션 토큰**: UUID v4 사용 (충분한 엔트로피)
- [x] **세션 만료**: 8시간 자동 만료
- [x] **자동 로그아웃**: 5분 무작동 시 자동 로그아웃
- [x] **브루트포스 방지**: 5회 실패 시 1분 대기
- [x] **로그 보안**: PIN 평문을 로그에 기록하지 않음
- [x] **권한 기본값**: Fail-Safe (권한 없으면 차단)
- [x] **감사 추적**: 모든 권한 관련 작업 로그 기록

### 7.2 PIN Security Implementation

```dart
// lib/features/auth/utils/pin_hasher.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PinHasher {
  /// PIN을 SHA-256 해시로 변환
  static String hashPin(String plainPin) {
    // 솔트 추가 (앱 고유 값)
    const salt = 'ODA_POS_PIN_SALT_v1';
    final bytes = utf8.encode(plainPin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// PIN 검증
  static bool verifyPin(String plainPin, String storedHash) {
    final inputHash = hashPin(plainPin);
    return inputHash == storedHash;
  }

  /// PIN 형식 검증 (4-6자리 숫자)
  static bool isValidPinFormat(String pin) {
    if (pin.length < 4 || pin.length > 6) return false;
    return int.tryParse(pin) != null;
  }
}
```

### 7.3 Session Security

```dart
// lib/features/auth/utils/session_manager.dart
import 'package:uuid/uuid.dart';

class SessionManager {
  static const sessionDuration = Duration(hours: 8);
  static const inactivityTimeout = Duration(minutes: 5);

  /// 세션 토큰 생성
  static String generateToken() {
    return const Uuid().v4();
  }

  /// 세션 만료 시간 계산
  static DateTime calculateExpiry() {
    return DateTime.now().add(sessionDuration);
  }

  /// 세션 유효성 검사
  static bool isSessionValid(DateTime? expiresAt, DateTime? lastActivity) {
    if (expiresAt == null) return false;

    // 세션 만료 확인
    if (DateTime.now().isAfter(expiresAt)) return false;

    // 비활성 타임아웃 확인
    if (lastActivity != null) {
      final inactiveTime = DateTime.now().difference(lastActivity);
      if (inactiveTime > inactivityTimeout) return false;
    }

    return true;
  }
}
```

### 7.4 Brute Force Protection

```dart
// lib/features/auth/providers/auth_provider.dart
class AuthProvider {
  final Map<int, int> _failedAttempts = {};
  final Map<int, DateTime> _lockoutUntil = {};

  Future<void> login(int employeeId, String pin) async {
    // 잠금 확인
    if (_isLocked(employeeId)) {
      throw AuthError(
        code: 'AUTH_002',
        message: '계정이 잠겼습니다. 나중에 다시 시도해주세요.',
      );
    }

    // PIN 검증
    final isValid = await _employeesDao.verifyPIN(employeeId, pin);

    if (isValid) {
      // 성공 시 실패 카운트 초기화
      _failedAttempts.remove(employeeId);
      _lockoutUntil.remove(employeeId);
      // ... 세션 생성
    } else {
      // 실패 시 카운트 증가
      final attempts = (_failedAttempts[employeeId] ?? 0) + 1;
      _failedAttempts[employeeId] = attempts;

      if (attempts >= 5) {
        // 5회 실패 시 1분 잠금
        _lockoutUntil[employeeId] = DateTime.now().add(Duration(minutes: 1));
        throw AuthError(
          code: 'AUTH_002',
          message: '5회 실패하여 계정이 잠겼습니다. 1분 후 다시 시도해주세요.',
        );
      }

      throw AuthError(
        code: 'AUTH_001',
        message: '잘못된 PIN입니다.',
        details: {'attemptsLeft': 5 - attempts},
      );
    }
  }

  bool _isLocked(int employeeId) {
    final lockoutTime = _lockoutUntil[employeeId];
    if (lockoutTime == null) return false;
    return DateTime.now().isBefore(lockoutTime);
  }
}
```

---

## 8. Test Plan

### 8.1 Test Scope

| Type | Target | Tool | Coverage |
|------|--------|------|----------|
| Unit Test | DAO methods | Dart test | PIN 검증, 세션 생성 로직 |
| Unit Test | Utility functions | Dart test | PIN 해시, 세션 관리 |
| Widget Test | UI components | Flutter test | PIN 입력, 권한 게이트 |
| Integration Test | 권한 플로우 | Flutter test | 로그인 → 권한 체크 → 승인 |
| Manual Test | 전체 시나리오 | 실제 기기 | 역할별 사용자 경험 |

### 8.2 Test Cases (Key)

#### Authentication Tests
- [ ] **Login Success**: 올바른 PIN으로 로그인 성공
- [ ] **Login Failure**: 잘못된 PIN으로 로그인 실패
- [ ] **Brute Force**: 5회 실패 후 1분 잠금 확인
- [ ] **Session Expiry**: 8시간 후 자동 만료
- [ ] **Auto Logout**: 5분 무작동 시 자동 로그아웃
- [ ] **PIN Change**: 직원이 PIN 변경 성공

#### Authorization Tests
- [ ] **Manager Access**: 관리자가 모든 기능 접근 가능
- [ ] **Cashier Limits**: 직원이 환불 50,000원 이하만 가능
- [ ] **Cashier Override**: 직원이 할인 시도 시 승인 다이얼로그 표시
- [ ] **Kitchen Restriction**: 주방이 POS 메뉴 접근 불가, KDS만 표시
- [ ] **Override Success**: 관리자 PIN으로 승인 성공
- [ ] **Override Failure**: 잘못된 관리자 PIN으로 승인 실패

#### Audit Logging Tests
- [ ] **Login Log**: 로그인 성공/실패 기록
- [ ] **Action Log**: 환불/할인 작업 기록
- [ ] **Override Log**: 관리자 승인 기록 (요청자, 승인자, 작업)
- [ ] **Log Query**: 관리자가 로그 조회 가능
- [ ] **Log Retention**: 90일 이상 로그 자동 삭제

#### Edge Cases
- [ ] **No PIN Set**: PIN 미설정 직원 로그인 불가
- [ ] **Invalid PIN Format**: 3자리 또는 문자 입력 시 에러
- [ ] **Expired Session Resume**: 만료된 세션으로 재접속 시 로그인 유도
- [ ] **Concurrent Sessions**: 동일 직원 중복 로그인 처리

### 8.3 Test Code Examples

```dart
// test/features/auth/utils/pin_hasher_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:oda_pos/features/auth/utils/pin_hasher.dart';

void main() {
  group('PinHasher', () {
    test('should hash PIN consistently', () {
      final hash1 = PinHasher.hashPin('1234');
      final hash2 = PinHasher.hashPin('1234');
      expect(hash1, equals(hash2));
    });

    test('should produce different hashes for different PINs', () {
      final hash1 = PinHasher.hashPin('1234');
      final hash2 = PinHasher.hashPin('4321');
      expect(hash1, isNot(equals(hash2)));
    });

    test('should verify correct PIN', () {
      final hash = PinHasher.hashPin('1234');
      final isValid = PinHasher.verifyPin('1234', hash);
      expect(isValid, isTrue);
    });

    test('should reject incorrect PIN', () {
      final hash = PinHasher.hashPin('1234');
      final isValid = PinHasher.verifyPin('4321', hash);
      expect(isValid, isFalse);
    });

    test('should validate correct PIN format', () {
      expect(PinHasher.isValidPinFormat('1234'), isTrue);
      expect(PinHasher.isValidPinFormat('123456'), isTrue);
      expect(PinHasher.isValidPinFormat('123'), isFalse);
      expect(PinHasher.isValidPinFormat('abcd'), isFalse);
    });
  });
}
```

---

## 9. Clean Architecture

### 9.1 Layer Structure

| Layer | Responsibility | Location |
|-------|---------------|----------|
| **Presentation** | UI components, screens, widgets, dialogs | `lib/features/auth/presentation/` |
| **Application** | Providers, use cases, business logic orchestration | `lib/features/auth/providers/` |
| **Domain** | Entities, enums, models, business rules | `lib/features/auth/domain/` |
| **Infrastructure** | DAO, database, utilities (PIN hasher, session manager) | `lib/features/auth/data/`, `lib/features/auth/utils/` |

### 9.2 Dependency Rules

```
┌─────────────────────────────────────────────────────────────┐
│                    Dependency Direction                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   Presentation ──→ Application ──→ Domain ←── Infrastructure│
│   (Screens)         (Providers)     (Models)   (DAO, Utils) │
│                          │                          ↑        │
│                          └──────────────────────────┘        │
│                                                             │
│   Rule: Inner layers MUST NOT depend on outer layers        │
│         Domain is independent (pure Dart types)             │
│         Infrastructure implements domain interfaces          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 9.3 File Import Rules

| From | Can Import | Cannot Import |
|------|-----------|---------------|
| Presentation | Application (Providers), Domain (Models) | Infrastructure directly |
| Application | Domain (Models, Enums), Infrastructure (DAO) | Presentation |
| Domain | Nothing external (pure Dart) | All external layers |
| Infrastructure | Domain (Models, Interfaces) | Application, Presentation |

### 9.4 This Feature's Layer Assignment

| Component | Layer | Location |
|-----------|-------|----------|
| PinLoginScreen | Presentation | `lib/features/auth/presentation/screens/pin_login_screen.dart` |
| PinPadWidget | Presentation | `lib/features/auth/presentation/widgets/pin_pad_widget.dart` |
| PermissionGateWidget | Presentation | `lib/features/auth/presentation/widgets/permission_gate_widget.dart` |
| ManagerOverrideDialog | Presentation | `lib/features/auth/presentation/dialogs/manager_override_dialog.dart` |
| AuthProvider | Application | `lib/features/auth/providers/auth_provider.dart` |
| PermissionProvider | Application | `lib/features/auth/providers/permission_provider.dart` |
| AuditLoggingProvider | Application | `lib/features/auth/providers/audit_logging_provider.dart` |
| UserRole | Domain | `lib/features/auth/domain/user_role.dart` |
| Permission | Domain | `lib/features/auth/domain/permission.dart` |
| Session | Domain | `lib/features/auth/domain/session.dart` |
| AuthError | Domain | `lib/features/auth/domain/auth_error.dart` |
| EmployeesDao (extended) | Infrastructure | `lib/database/daos/employees_dao.dart` |
| PermissionLogsDao | Infrastructure | `lib/features/auth/data/permission_logs_dao.dart` |
| PinHasher | Infrastructure | `lib/features/auth/utils/pin_hasher.dart` |
| SessionManager | Infrastructure | `lib/features/auth/utils/session_manager.dart` |

---

## 10. Coding Convention Reference

### 10.1 Naming Conventions (Flutter/Dart)

| Target | Rule | Example |
|--------|------|---------|
| Classes | PascalCase | `PinLoginScreen`, `AuthProvider` |
| Functions/Methods | camelCase | `verifyPIN()`, `createSession()` |
| Variables | camelCase | `sessionToken`, `employeeId` |
| Constants | lowerCamelCase | `sessionDuration`, `maxAttempts` |
| Enums | PascalCase | `UserRole`, `Permission` |
| Enum Values | UPPER_SNAKE_CASE | `MANAGER`, `CASHIER`, `REFUND_UNLIMITED` |
| Private members | _camelCase | `_failedAttempts`, `_isLocked()` |
| Files (widget) | snake_case.dart | `pin_login_screen.dart` |
| Files (utility) | snake_case.dart | `pin_hasher.dart` |
| Folders | snake_case | `auth/`, `presentation/`, `providers/` |

### 10.2 Import Order (Dart)

```dart
// 1. Dart SDK imports
import 'dart:convert';
import 'dart:async';

// 2. Flutter framework imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Package imports
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:crypto/crypto.dart';

// 4. Project imports
import '../../../database/app_database.dart';
import '../domain/user_role.dart';
import '../domain/permission.dart';

// 5. Relative imports
import 'widgets/pin_pad_widget.dart';
```

### 10.3 Provider Naming Convention

```dart
// Provider 명명 규칙
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);
final permissionProvider = Provider<PermissionChecker>(...);
final currentSessionProvider = StreamProvider<Session?>(...);
final auditLoggingProvider = Provider<AuditLogger>(...);

// DAO Provider
final employeesDaoProvider = Provider<EmployeesDao>(...);
final permissionLogsDaoProvider = Provider<PermissionLogsDao>(...);
```

### 10.4 This Feature's Conventions

| Item | Convention Applied |
|------|-------------------|
| Widget naming | `{Feature}{Type}Widget` (예: `PinPadWidget`) |
| Screen naming | `{Feature}Screen` (예: `PinLoginScreen`) |
| Provider naming | `{feature}Provider` (예: `authProvider`) |
| DAO naming | `{Entity}Dao` (예: `EmployeesDao`) |
| Error handling | Custom exception classes (예: `AuthError`) |
| State management | Riverpod StateNotifier pattern |
| Async operations | Future/Stream with proper error handling |

---

## 11. Implementation Guide

### 11.1 File Structure

```
lib/
├── features/
│   └── auth/
│       ├── presentation/
│       │   ├── screens/
│       │   │   ├── pin_login_screen.dart
│       │   │   └── audit_log_screen.dart
│       │   ├── widgets/
│       │   │   ├── pin_pad_widget.dart
│       │   │   ├── permission_gate_widget.dart
│       │   │   └── session_badge.dart
│       │   └── dialogs/
│       │       └── manager_override_dialog.dart
│       ├── providers/
│       │   ├── auth_provider.dart
│       │   ├── permission_provider.dart
│       │   └── audit_logging_provider.dart
│       ├── domain/
│       │   ├── user_role.dart
│       │   ├── permission.dart
│       │   ├── session.dart
│       │   ├── auth_error.dart
│       │   └── role_permission_map.dart
│       ├── data/
│       │   └── permission_logs_dao.dart
│       └── utils/
│           ├── pin_hasher.dart
│           └── session_manager.dart
├── database/
│   ├── tables/
│   │   ├── employees.dart (기존 확장)
│   │   └── permission_logs.dart (신규)
│   ├── daos/
│   │   └── employees_dao.dart (기존 확장)
│   └── app_database.dart (마이그레이션 추가)
```

### 11.2 Implementation Order

#### Phase 1: 데이터베이스 및 Domain (1시간)
1. [ ] `domain/user_role.dart` - UserRole enum 정의
2. [ ] `domain/permission.dart` - Permission enum 정의
3. [ ] `domain/session.dart` - Session model 정의
4. [ ] `domain/auth_error.dart` - AuthError exception 정의
5. [ ] `domain/role_permission_map.dart` - 역할-권한 매핑 정의
6. [ ] `database/tables/employees.dart` - 필드 추가
7. [ ] `database/tables/permission_logs.dart` - 신규 테이블
8. [ ] `database/app_database.dart` - 마이그레이션 v5, v6
9. [ ] `utils/pin_hasher.dart` - PIN 암호화 유틸리티
10. [ ] `utils/session_manager.dart` - 세션 관리 유틸리티
11. [ ] `database/daos/employees_dao.dart` - 인증 메서드 추가
12. [ ] `data/permission_logs_dao.dart` - 로그 DAO 생성

#### Phase 2: Application Layer (30분)
1. [ ] `providers/auth_provider.dart` - 인증 Provider 구현
2. [ ] `providers/permission_provider.dart` - 권한 Provider 구현
3. [ ] `providers/audit_logging_provider.dart` - 로깅 Provider 구현

#### Phase 3: Presentation Layer - Widgets (30분)
1. [ ] `widgets/pin_pad_widget.dart` - 숫자 패드 위젯
2. [ ] `widgets/permission_gate_widget.dart` - 권한 게이트 위젯
3. [ ] `widgets/session_badge.dart` - 세션 배지 위젯
4. [ ] `dialogs/manager_override_dialog.dart` - 승인 다이얼로그

#### Phase 4: Presentation Layer - Screens (30분)
1. [ ] `screens/pin_login_screen.dart` - 로그인 화면
2. [ ] `screens/audit_log_screen.dart` - 로그 조회 화면

#### Phase 5: Integration & Testing (30분)
1. [ ] 환불 화면에 PermissionGateWidget 적용
2. [ ] 할인 기능에 PermissionGateWidget 적용
3. [ ] 매출 조회에 권한 체크 추가
4. [ ] 메인 화면에 역할별 메뉴 필터링 적용
5. [ ] 전체 시나리오 테스트 (역할별)
6. [ ] 로그 기록 확인

**총 예상 시간: 2.5-3시간**

### 11.3 Critical Implementation Notes

#### Database Migration 주의사항
```dart
// ⚠️ IMPORTANT: 기존 데이터 보존
// employees 테이블에 새 컬럼 추가 시 기본값 설정 필수
await m.addColumn(employees, employees.role); // DEFAULT 'CASHIER'
await m.addColumn(employees, employees.pinHash); // NULLABLE

// 기존 직원들에게 기본 역할 할당 (마이그레이션 후 수동 처리 필요)
// 첫 번째 직원을 MANAGER로 설정하는 스크립트 실행
```

#### Provider 초기화 순서
```dart
// main.dart에서 Provider 초기화
ProviderScope(
  overrides: [
    // 1. Database Provider (가장 먼저)
    databaseProvider.overrideWithValue(database),
    // 2. DAO Providers
    employeesDaoProvider,
    permissionLogsDaoProvider,
    // 3. Auth Provider (DAO 의존)
    authProvider,
    // 4. Permission Provider (Auth 의존)
    permissionProvider,
  ],
  child: MyApp(),
)
```

#### 기존 화면 통합 가이드
```dart
// 기존 환불 버튼을 PermissionGateWidget으로 감싸기
// BEFORE:
ElevatedButton(
  onPressed: _processRefund,
  child: Text('환불 처리'),
)

// AFTER:
PermissionGateWidget(
  permission: Permission.REFUND_UNLIMITED,
  child: ElevatedButton(
    onPressed: _processRefund,
    child: Text('환불 처리'),
  ),
)
```

---

## 12. Performance Considerations

### 12.1 Optimization Strategies

| Component | Strategy | Expected Impact |
|-----------|----------|-----------------|
| Permission Check | 메모리 캐시 (역할-권한 매핑) | 10ms 이내 응답 |
| PIN Verification | SHA-256 해시 (1회 계산) | 100ms 이내 |
| Session Validation | 인메모리 Session 객체 | 1ms 이내 |
| Audit Logging | 비동기 처리 (isolate) | UI 블로킹 없음 |
| Login Screen | PIN 입력 디바운싱 (300ms) | 불필요한 검증 방지 |

### 12.2 Performance Benchmarks

```dart
// lib/features/auth/providers/permission_provider.dart
class PermissionProvider {
  // 역할-권한 매핑 캐시 (빠른 조회)
  static final Map<UserRole, Set<Permission>> _rolePermissionsCache = {
    UserRole.MANAGER: {...Permission.values},
    UserRole.CASHIER: {
      Permission.SALES_CREATE,
      Permission.SALES_VIEW_OWN,
      Permission.REFUND_SMALL,
      Permission.INVENTORY_VIEW,
      Permission.TABLE_MANAGE,
    },
    UserRole.KITCHEN: {},
  };

  /// 권한 체크 (O(1) 조회)
  bool checkPermission(UserRole role, Permission permission) {
    final permissions = _rolePermissionsCache[role];
    return permissions?.contains(permission) ?? false;
  }
}
```

### 12.3 Database Query Optimization

```dart
// lib/features/auth/data/permission_logs_dao.dart
@DriftAccessor(tables: [PermissionLogs])
class PermissionLogsDao extends DatabaseAccessor<AppDatabase> {
  // 인덱스 활용한 빠른 조회
  Future<List<PermissionLog>> getLogsByEmployee(int employeeId, int limit) {
    return (select(permissionLogs)
          ..where((log) => log.employeeId.equals(employeeId))
          ..orderBy([(log) => OrderingTerm.desc(log.createdAt)])
          ..limit(limit))
        .get();
  }

  // 비동기 로그 기록 (UI 블로킹 없음)
  Future<void> logActionAsync(PermissionLogsCompanion log) async {
    // compute()로 별도 isolate에서 실행 (필요시)
    await into(permissionLogs).insert(log);
  }
}
```

---

## 13. Deployment & Migration

### 13.1 Deployment Checklist

- [ ] 데이터베이스 백업 (마이그레이션 전)
- [ ] 마이그레이션 v5, v6 실행 확인
- [ ] 기존 직원 데이터 확인 (role, pinHash null 여부)
- [ ] 첫 번째 관리자 계정 설정 (수동)
- [ ] 직원들에게 PIN 설정 안내
- [ ] 권한 시스템 활성화 전 전체 테스트
- [ ] 롤백 플랜 준비 (마이그레이션 실패 시)

### 13.2 Migration Script

```dart
// tools/migration/setup_initial_admin.dart
import 'package:oda_pos/database/app_database.dart';
import 'package:oda_pos/features/auth/utils/pin_hasher.dart';

Future<void> setupInitialAdmin(AppDatabase db) async {
  final employees = await db.employeesDao.getAllEmployees();

  if (employees.isEmpty) {
    print('No employees found. Please create an admin user first.');
    return;
  }

  // 첫 번째 직원을 관리자로 설정
  final firstEmployee = employees.first;
  final adminPin = '0000'; // 기본 관리자 PIN
  final hashedPin = PinHasher.hashPin(adminPin);

  await db.employeesDao.updateEmployee(
    firstEmployee.id,
    EmployeesCompanion(
      role: Value('MANAGER'),
      pinHash: Value(hashedPin),
      pinChangedAt: Value(DateTime.now()),
    ),
  );

  print('Admin setup complete!');
  print('Username: ${firstEmployee.username}');
  print('Default PIN: $adminPin');
  print('⚠️ Please change the PIN immediately!');
}
```

### 13.3 Rollback Plan

```dart
// 마이그레이션 실패 시 롤백
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    // ... onCreate, onUpgrade

    // 롤백 전략
    beforeOpen: (details) async {
      // 데이터 무결성 검증
      final employees = await select(employees).get();
      final invalidRoles = employees.where((e) =>
        !['MANAGER', 'CASHIER', 'KITCHEN'].contains(e.role)
      ).toList();

      if (invalidRoles.isNotEmpty) {
        throw Exception('Invalid roles detected: ${invalidRoles.map((e) => e.role)}');
      }
    },
  );
}
```

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-02-09 | Initial draft | Claude (AI Agent) |
| 1.0 | 2026-02-09 | Complete design document | Claude (AI Agent) |

---

## Next Steps

1. ✅ Plan 문서 작성 완료
2. ✅ Design 문서 작성 완료
3. ⏳ 구현 시작 (`/pdca do staff-permission-system`)
4. ⏳ Gap 분석 (`/pdca analyze staff-permission-system`)
5. ⏳ 완료 보고서 (`/pdca report staff-permission-system`)

---

**Design Version**: 1.0
**Feature Status**: Design Complete
**Ready for Implementation**: ✅ Yes
**Estimated Effort**: 2.5-3 hours

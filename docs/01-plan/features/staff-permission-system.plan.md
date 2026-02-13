# 직원 권한 관리 시스템 - Plan Document

## 📌 Feature Overview

### Feature Name
**직원 권한 관리 시스템 (Staff Permission Management System)**

### Feature ID
`FEAT-STAFF-PERM-001`

### Priority
**High** - 보안 및 운영 효율성의 핵심 기능

### Target Users
- 관리자 (Owner/Manager): 전체 권한 관리 및 직원 관리
- 직원 (Cashier): 제한된 권한으로 POS 운영
- 주방 (Kitchen): 주문 확인 및 상태 변경만 가능

---

## 🎯 Goals & Objectives

### Business Goals
1. **보안 강화**: 중요 기능(환불, 할인, 매출 조회)에 대한 접근 제어
2. **책임 추적**: 각 작업의 수행자 기록으로 책임 소재 명확화
3. **운영 효율**: 역할별 맞춤 UI로 직원 교육 시간 단축
4. **분쟁 방지**: 권한 위반 시 관리자 승인으로 유연한 운영

### Technical Goals
1. **역할 기반 접근 제어 (RBAC)**: 3가지 기본 역할 구현
2. **PIN 기반 빠른 인증**: 4-6자리 숫자로 1초 이내 로그인
3. **세션 관리**: 자동 로그아웃 및 세션 타임아웃
4. **감사 로그**: 모든 권한 관련 작업 기록

### Success Metrics
- 로그인 속도: 평균 3초 이내
- 권한 위반 방지율: 95% 이상
- 직원 만족도: 4.0/5.0 이상 (사용 편의성)
- 관리자 승인 응답 시간: 평균 10초 이내

---

## 🔍 Problem Statement

### Current Issues
1. **보안 취약**: 모든 직원이 환불, 할인 등 중요 기능 무제한 사용 가능
2. **책임 불명확**: 누가 어떤 작업을 했는지 추적 불가능
3. **운영 혼란**: 주방 직원이 POS 화면에 접근하여 실수 발생
4. **교육 부담**: 모든 기능을 설명해야 하므로 신입 교육 시간 증가

### Pain Points
- 관리자: "환불이 너무 쉽게 되어서 불안해요"
- 직원: "실수로 환불 버튼을 눌러서 큰일 날 뻔했어요"
- 주방: "POS 화면이 복잡해서 주문만 보고 싶어요"

### Impact
- 매출 누수 위험: 무단 할인/환불로 인한 손실
- 분쟁 발생: 책임 소재 불명확으로 인한 직원 간 갈등
- 효율성 저하: 불필요한 기능 노출로 인한 실수 증가

---

## 💡 Proposed Solution

### Solution Overview
**역할 기반 권한 관리 + PIN 인증 + 관리자 승인 시스템**

PIN 코드로 빠르게 로그인하고, 역할에 따라 메뉴와 기능이 자동으로 제한되며,
권한이 없는 작업 시도 시 관리자 PIN으로 일회성 승인 가능.

### Core Features

#### 1. 역할 관리 (Role Management)
**3가지 기본 역할**
- **관리자 (MANAGER)**: 모든 기능 접근 가능
  - 권한: 전체 메뉴, 환불, 할인, 매출 조회, 재고 수정, 직원 관리
  - 화면: 전체 POS 화면 + 관리자 메뉴

- **직원 (CASHIER)**: 일반 판매 및 제한적 기능
  - 권한: 판매, 고객 등록, 테이블 관리, 제한적 환불(금액 제한)
  - 제한: 매출 조회, 재고 수정, 할인(관리자 승인 필요)
  - 화면: 단순화된 POS 화면

- **주방 (KITCHEN)**: 주문 확인 전용
  - 권한: 주방 디스플레이(KDS)만 접근
  - 제한: POS 메뉴 전체 차단
  - 화면: KDS 전용 화면

#### 2. PIN 인증 (PIN Authentication)
- **4-6자리 숫자 PIN**: 빠른 터치 패드 입력
- **자동 로그아웃**: 5분 무작동 시 자동 로그아웃
- **세션 타임아웃**: 8시간 후 자동 만료
- **PIN 변경**: 직원이 직접 변경 가능 (첫 로그인 후 강제 변경)

#### 3. 관리자 승인 (Manager Override)
- **일회성 승인**: 권한 없는 작업 시도 시 관리자 PIN 입력 팝업
- **승인 기록**: 누가, 언제, 무엇을, 누구의 승인으로 했는지 기록
- **즉시 처리**: 승인 후 작업 즉시 진행 (워크플로우 중단 없음)

#### 4. 권한 제어 (Permission Control)
**메뉴 레벨 제어**
- 역할별로 보이는 메뉴 자동 필터링
- 접근 불가 메뉴는 UI에서 완전히 숨김

**기능 레벨 제어**
- 환불: 직원은 일정 금액(예: 50,000원) 이하만 가능
- 할인: 관리자 승인 필요
- 매출 조회: 관리자만 가능
- 재고 수정: 관리자만 가능

#### 5. 감사 로그 (Audit Log)
- **기록 대상**: 로그인/로그아웃, 권한 위반 시도, 관리자 승인, 환불/할인
- **로그 내용**: 타임스탬프, 직원ID, 작업 타입, 결과, 승인자(있을 경우)
- **조회**: 관리자만 로그 조회 가능
- **보관 기간**: 3개월 (설정 가능)

---

## 🏗️ Architecture Overview

### System Components

```
┌─────────────────────────────────────────┐
│         UI Layer (Flutter)              │
│  ┌────────────┐  ┌──────────────────┐   │
│  │ PIN Pad    │  │ Permission Gate  │   │
│  │ Widget     │  │ Widget           │   │
│  └────────────┘  └──────────────────┘   │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│     Business Logic (Riverpod)           │
│  ┌────────────┐  ┌──────────────────┐   │
│  │ Auth       │  │ Permission       │   │
│  │ Provider   │  │ Provider         │   │
│  └────────────┘  └──────────────────┘   │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│     Data Layer (Drift + SQLite)         │
│  ┌────────────┐  ┌──────────────────┐   │
│  │ employees  │  │ permission_logs  │   │
│  │ (enhanced) │  │ (new table)      │   │
│  └────────────┘  └──────────────────┘   │
└─────────────────────────────────────────┘
```

### Data Flow

```
로그인 플로우:
User Input (PIN)
  → AuthProvider.login()
  → EmployeesDao.verifyPIN()
  → Session 생성
  → PermissionProvider.loadPermissions()
  → UI 업데이트

권한 체크 플로우:
Action Attempt
  → PermissionProvider.checkPermission()
  → Has Permission?
    ├─ YES → Execute Action
    └─ NO → Show Manager Override Dialog
              → Manager PIN Input
              → Log Approval
              → Execute Action
```

---

## 📊 Data Model

### Database Schema Changes

#### 1. employees 테이블 확장
```sql
ALTER TABLE employees ADD COLUMN role TEXT NOT NULL DEFAULT 'CASHIER';
ALTER TABLE employees ADD COLUMN pin_code TEXT;
ALTER TABLE employees ADD COLUMN pin_changed_at DATETIME;
ALTER TABLE employees ADD COLUMN last_login_at DATETIME;
ALTER TABLE employees ADD COLUMN session_token TEXT;
ALTER TABLE employees ADD COLUMN session_expires_at DATETIME;
```

#### 2. permission_logs 테이블 (신규)
```sql
CREATE TABLE permission_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  employee_id INTEGER NOT NULL,
  action_type TEXT NOT NULL,
  action_target TEXT,
  permission_granted BOOLEAN NOT NULL,
  approved_by_employee_id INTEGER,
  metadata TEXT,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (employee_id) REFERENCES employees(id),
  FOREIGN KEY (approved_by_employee_id) REFERENCES employees(id)
);

CREATE INDEX idx_permission_logs_employee ON permission_logs(employee_id);
CREATE INDEX idx_permission_logs_created ON permission_logs(created_at);
```

### Role Definition
```dart
enum UserRole {
  MANAGER,  // 관리자
  CASHIER,  // 직원
  KITCHEN,  // 주방
}

enum Permission {
  // 판매
  SALES_CREATE,
  SALES_VIEW_OWN,
  SALES_VIEW_ALL,

  // 환불
  REFUND_SMALL,     // 50,000원 이하
  REFUND_UNLIMITED,

  // 할인
  DISCOUNT_APPLY,

  // 재고
  INVENTORY_VIEW,
  INVENTORY_MODIFY,

  // 직원 관리
  EMPLOYEE_VIEW,
  EMPLOYEE_MANAGE,

  // 매출 리포트
  REPORT_VIEW,

  // 테이블 관리
  TABLE_MANAGE,
}
```

### Role-Permission Mapping
```dart
const rolePermissions = {
  UserRole.MANAGER: [
    // 전체 권한
    Permission.SALES_CREATE,
    Permission.SALES_VIEW_ALL,
    Permission.REFUND_UNLIMITED,
    Permission.DISCOUNT_APPLY,
    Permission.INVENTORY_MODIFY,
    Permission.EMPLOYEE_MANAGE,
    Permission.REPORT_VIEW,
    Permission.TABLE_MANAGE,
  ],

  UserRole.CASHIER: [
    Permission.SALES_CREATE,
    Permission.SALES_VIEW_OWN,
    Permission.REFUND_SMALL,
    // DISCOUNT_APPLY는 없음 (관리자 승인 필요)
    Permission.INVENTORY_VIEW,
    Permission.TABLE_MANAGE,
  ],

  UserRole.KITCHEN: [
    // KDS만 접근
  ],
};
```

---

## 🎨 User Interface

### Screen Flows

#### 1. 로그인 화면
```
┌─────────────────────────────┐
│     Oda POS - 직원 로그인     │
│                             │
│   [직원 선택 드롭다운]         │
│   ▼ 김철수 (직원)             │
│                             │
│   PIN 코드 입력              │
│   ┌───┬───┬───┐             │
│   │ 1 │ 2 │ 3 │             │
│   ├───┼───┼───┤             │
│   │ 4 │ 5 │ 6 │             │
│   ├───┼───┼───┤             │
│   │ 7 │ 8 │ 9 │             │
│   ├───┼───┼───┤             │
│   │ ← │ 0 │ ✓ │             │
│   └───┴───┴───┘             │
│                             │
│   [    로그인    ]           │
└─────────────────────────────┘
```

#### 2. 권한 거부 다이얼로그
```
┌─────────────────────────────┐
│   ⚠️ 권한이 필요합니다        │
│                             │
│  환불 처리는 관리자 권한이    │
│  필요합니다.                 │
│                             │
│  관리자 PIN을 입력하거나     │
│  관리자에게 요청하세요.       │
│                             │
│  관리자 PIN: [________]      │
│                             │
│  [취소]  [승인 요청]         │
└─────────────────────────────┘
```

#### 3. 역할별 메인 화면

**관리자 화면**
- 전체 메뉴 표시
- 우측 상단: "👤 관리자 김철수" + 로그아웃 버튼

**직원 화면**
- 판매, 고객, 테이블 메뉴만 표시
- 리포트/재고 메뉴 숨김
- 우측 상단: "👤 직원 이영희" + 로그아웃 버튼

**주방 화면**
- KDS(주방 디스플레이) 전용 화면 자동 전환
- 다른 메뉴 접근 불가

---

## 🔧 Technical Requirements

### Development Stack
- **Frontend**: Flutter (기존 스택 유지)
- **State Management**: Riverpod (기존)
- **Database**: Drift + SQLite (기존)
- **Authentication**: 자체 구현 (PIN 기반)

### Dependencies (신규 추가)
```yaml
dependencies:
  # 암호화 (PIN 저장용)
  crypto: ^3.0.3  # 이미 있음

  # 세션 관리
  uuid: ^4.4.0  # 이미 있음
```

### Security Requirements
1. **PIN 암호화**: SHA-256 해시 저장 (평문 저장 금지)
2. **세션 토큰**: UUID v4 사용, 8시간 만료
3. **브루트포스 방지**: 5회 실패 시 1분 대기
4. **로그 보안**: 민감 정보(PIN) 로그에 기록 금지

### Performance Requirements
- 로그인 응답 시간: 500ms 이내
- 권한 체크: 10ms 이내 (로컬 캐시 활용)
- 감사 로그 기록: 비동기 처리 (UI 블로킹 없음)

---

## 📅 Implementation Plan

### Phase 1: 데이터베이스 및 백엔드 (1시간)
- [ ] employees 테이블 마이그레이션 (role, pin_code 추가)
- [ ] permission_logs 테이블 생성
- [ ] EmployeesDao에 PIN 인증 메서드 추가
- [ ] PermissionLogsDao 생성

### Phase 2: 인증 시스템 (30분)
- [ ] AuthProvider 구현 (로그인, 로그아웃, 세션 관리)
- [ ] PermissionProvider 구현 (권한 체크, 역할 매핑)
- [ ] PIN 암호화 유틸리티

### Phase 3: UI 컴포넌트 (30분)
- [ ] PIN 입력 위젯
- [ ] 로그인 화면
- [ ] 관리자 승인 다이얼로그
- [ ] 권한 게이트 위젯 (Permission Gate)

### Phase 4: 기능 통합 (30분)
- [ ] 환불 화면에 권한 체크 추가
- [ ] 할인 기능에 권한 체크 추가
- [ ] 매출 조회에 권한 체크 추가
- [ ] 메뉴 필터링 (역할별)

### Phase 5: 테스트 및 검증 (30분)
- [ ] 역할별 로그인 테스트
- [ ] 권한 체크 동작 확인
- [ ] 관리자 승인 플로우 테스트
- [ ] 로그 기록 확인

**총 예상 시간: 2.5-3시간**

---

## 🧪 Testing Strategy

### Test Scenarios

#### 1. 인증 테스트
- [ ] 올바른 PIN으로 로그인 성공
- [ ] 잘못된 PIN으로 로그인 실패
- [ ] 5회 실패 후 대기 시간 확인
- [ ] 자동 로그아웃 (5분 무작동)
- [ ] 세션 만료 (8시간)

#### 2. 권한 테스트
- [ ] 관리자: 모든 기능 접근 가능
- [ ] 직원: 환불 50,000원 이하만 가능
- [ ] 직원: 할인 시도 시 관리자 승인 팝업
- [ ] 주방: POS 메뉴 접근 불가, KDS만 표시

#### 3. 승인 플로우 테스트
- [ ] 권한 없는 작업 시도 → 승인 다이얼로그 표시
- [ ] 관리자 PIN 입력 → 작업 실행
- [ ] 잘못된 PIN 입력 → 에러 메시지
- [ ] 승인 기록이 로그에 저장됨

#### 4. 로그 테스트
- [ ] 로그인/로그아웃 기록
- [ ] 권한 위반 시도 기록
- [ ] 관리자 승인 기록
- [ ] 로그 조회 (관리자만)

---

## 📝 Documentation

### User Documentation (필요 문서)
1. **관리자 가이드**
   - 직원 등록 방법
   - PIN 설정 방법
   - 역할 변경 방법
   - 로그 조회 방법

2. **직원 가이드**
   - 로그인 방법
   - PIN 변경 방법
   - 관리자 승인 요청 방법

### Developer Documentation
1. **권한 시스템 아키텍처**: Architecture diagram
2. **API 문서**: DAO 메서드 설명
3. **권한 추가 가이드**: 새 권한 추가 시 절차

---

## ⚠️ Risks & Mitigation

### Identified Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| PIN 분실 | High | Medium | 관리자가 PIN 재설정 기능 제공 |
| 관리자 부재 시 승인 불가 | Medium | Low | 부관리자 역할 추가 고려 (v2) |
| 세션 탈취 | High | Low | 세션 토큰 정기 갱신, HTTPS 필수 |
| 성능 저하 (권한 체크) | Low | Low | 권한 정보 메모리 캐싱 |

### Rollback Plan
- 마이그레이션 실패 시: 이전 버전 DB로 롤백
- 로그인 시스템 문제 시: 임시로 권한 체크 비활성화 (관리자 모드)

---

## 🎯 Acceptance Criteria

### Must Have
- [ ] 3가지 역할 (관리자, 직원, 주방) 정의 및 동작
- [ ] PIN 코드 로그인 (4-6자리)
- [ ] 권한 없는 작업 시도 시 관리자 승인 다이얼로그
- [ ] 역할별 메뉴 자동 필터링
- [ ] 환불/할인 권한 제어
- [ ] 감사 로그 기록

### Should Have
- [ ] 자동 로그아웃 (5분)
- [ ] 세션 타임아웃 (8시간)
- [ ] PIN 변경 기능
- [ ] 로그 조회 화면 (관리자)

### Nice to Have
- [ ] 얼굴 인식 로그인 (v2)
- [ ] 지문 인식 (v2)
- [ ] 역할 커스터마이징 (v2)
- [ ] 실시간 알림 (권한 요청 시 관리자에게)

---

## 📚 References

### External Resources
- [RBAC 개념](https://en.wikipedia.org/wiki/Role-based_access_control)
- [Flutter Security Best Practices](https://flutter.dev/docs/development/data-and-backend/security)
- [Drift Database Migration](https://drift.simonbinder.eu/docs/advanced-features/migrations/)

### Internal Resources
- `lib/database/app_database.dart` - 기존 데이터베이스
- `lib/database/daos/employees_dao.dart` - 직원 DAO
- `lib/features/pos/` - POS 화면 구조

---

## ✅ Sign-off

### Stakeholders
- **Product Owner**: (사용자 승인 필요)
- **Developer**: Claude (AI Agent)
- **Created**: 2026-02-09
- **Last Updated**: 2026-02-09

### Next Steps
1. ✅ Plan 문서 검토 및 승인
2. ⏳ Design 문서 작성 (`/pdca design staff-permission-system`)
3. ⏳ 구현 시작 (`/pdca do staff-permission-system`)

---

**Plan Version**: 1.0
**Feature Status**: Planning
**Estimated Effort**: 2.5-3 hours

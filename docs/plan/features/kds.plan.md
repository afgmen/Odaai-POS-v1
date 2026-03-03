# [Plan] Kitchen Display System (KDS)

**Feature**: KDS (Kitchen Display System)
**Created**: 2024-02-08
**Status**: Planning
**Priority**: High
**Estimated Effort**: Medium-High (3-4 days)

---

## 1. Executive Summary

### 1.1 Overview
KDS(Kitchen Display System)는 레스토랑/카페에서 POS로부터 주문을 받아 주방에서 실시간으로 확인하고 조리 상태를 관리할 수 있는 시스템입니다. 웨이터가 POS에서 주문을 완료하면, 주방 화면에 자동으로 주문이 표시되고, 주방 직원은 조리 진행 상황을 업데이트할 수 있습니다.

### 1.2 Business Value
- **주문 누락 방지**: 종이 주문서 분실 위험 제거
- **조리 시간 단축**: 실시간 주문 확인으로 준비 시간 개선
- **주문 추적**: 각 주문의 상태를 실시간으로 파악
- **효율성 향상**: 여러 주문을 우선순위에 따라 관리
- **커뮤니케이션 개선**: 홀-주방 간 의사소통 개선

### 1.3 Success Metrics
- 주문 처리 시간 20% 단축
- 주문 누락률 0%
- 평균 대기 시간 15% 감소
- 주방 직원 만족도 향상

---

## 2. Requirements

### 2.1 Functional Requirements

#### FR-1: 주문 수신 및 표시
- POS에서 결제 완료된 주문을 실시간으로 수신
- 주문 번호, 테이블 번호, 주문 시간, 상품 목록 표시
- 새 주문 도착 시 알림 (소리 + 시각적 표시)
- 주문 상품별로 수량, 옵션, 특별 요청사항 표시

#### FR-2: 주문 상태 관리
주문은 다음 4가지 상태를 거칩니다:
1. **PENDING** (대기): 새로 들어온 주문
2. **PREPARING** (조리중): 조리가 시작된 주문
3. **READY** (완료): 조리가 완료된 주문
4. **SERVED** (서빙완료): 고객에게 전달된 주문

각 상태별 액션:
- PENDING → PREPARING: "조리 시작" 버튼
- PREPARING → READY: "완료" 버튼
- READY → SERVED: "서빙 완료" 버튼
- 모든 상태에서 "취소" 가능 (관리자 권한 필요)

#### FR-3: 주문 우선순위 관리
- 주문 시간 기준 자동 정렬 (오래된 주문이 위로)
- 대기 시간이 임계값(예: 15분) 초과 시 경고 표시
- 긴급 주문 마킹 기능

#### FR-4: 주문 필터링 및 검색
- 상태별 필터링 (전체/대기/조리중/완료)
- 테이블 번호로 검색
- 주문 번호로 검색
- 시간 범위 필터 (오늘/최근 1시간/전체)

#### FR-5: 주문 상세 정보
- 주문 클릭 시 상세 모달 표시
- 고객 요청사항 (예: "맵게 해주세요", "얼음 빼주세요")
- 알레르기 정보 표시 (중요)
- 특별 지시사항 강조 표시

#### FR-6: 음향 알림
- 새 주문 도착 시 알림음
- 긴급 주문 알림음 (다른 소리)
- 대기 시간 초과 경고음
- 알림음 On/Off 설정

### 2.2 Non-Functional Requirements

#### NFR-1: Performance
- 새 주문 수신 지연 시간 < 2초
- UI 반응 속도 < 100ms
- 동시 주문 처리 능력 50개 이상

#### NFR-2: Reliability
- 네트워크 단절 시 로컬 캐시 유지
- 앱 재시작 시 진행 중인 주문 복구
- 주문 데이터 손실 방지

#### NFR-3: Usability
- 터치 친화적 UI (큰 버튼, 간격)
- 직관적인 색상 코드 (대기=노랑, 조리중=파랑, 완료=녹색)
- 주방 환경에 맞는 고대비 디자인
- 한글/영어/베트남어 지원

#### NFR-4: Scalability
- 여러 주방 디스플레이 동시 지원
- 주방 구역별 주문 분리 가능 (예: 음료, 요리, 디저트)

---

## 3. Architecture Overview

### 3.1 Components

```
┌─────────────────────────────────────────────────────┐
│                    POS System                        │
│  (기존 Oda POS - 주문 입력 및 결제)                   │
└──────────────────┬──────────────────────────────────┘
                   │
                   │ Sale Record Insert
                   │ (Database Trigger or Provider)
                   ▼
┌─────────────────────────────────────────────────────┐
│              SQLite Database (Drift)                 │
│  - sales 테이블 (주문)                                │
│  - sale_items 테이블 (주문 상품)                      │
│  - kitchen_orders 테이블 (NEW - KDS 상태)            │
└──────────────────┬──────────────────────────────────┘
                   │
                   │ Stream/Watch
                   │ (Drift Stream)
                   ▼
┌─────────────────────────────────────────────────────┐
│            KDS Screen (Kitchen Display)              │
│  - 주문 목록 표시                                     │
│  - 상태 업데이트 버튼                                 │
│  - 알림 시스템                                        │
└─────────────────────────────────────────────────────┘
```

### 3.2 Data Flow

1. **주문 생성**
   - POS에서 결제 완료 → Sales 테이블에 INSERT
   - SaleItems 테이블에 상품 정보 INSERT
   - KitchenOrders 테이블에 자동 생성 (status: PENDING)

2. **주문 실시간 수신**
   - KDS 화면은 KitchenOrders Stream을 Watch
   - 새 주문 추가 시 자동으로 UI 업데이트
   - 알림음 재생

3. **상태 업데이트**
   - 주방 직원이 상태 변경 버튼 클릭
   - KitchenOrders 테이블 UPDATE
   - Stream을 통해 모든 KDS 화면에 실시간 반영

### 3.3 Database Schema (신규 테이블)

```sql
CREATE TABLE kitchen_orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id INTEGER NOT NULL REFERENCES sales(id),
  status TEXT NOT NULL DEFAULT 'PENDING',
    -- PENDING | PREPARING | READY | SERVED | CANCELLED
  priority TEXT NOT NULL DEFAULT 'NORMAL',
    -- NORMAL | URGENT
  special_instructions TEXT,
  started_at DATETIME,        -- 조리 시작 시간
  ready_at DATETIME,          -- 완료 시간
  served_at DATETIME,         -- 서빙 시간
  cancelled_at DATETIME,      -- 취소 시간
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_kitchen_orders_status ON kitchen_orders(status);
CREATE INDEX idx_kitchen_orders_sale_id ON kitchen_orders(sale_id);
```

---

## 4. User Stories

### US-1: 주방 직원이 새 주문을 확인한다
**As a** 주방 직원
**I want to** POS에서 들어온 새 주문을 즉시 확인
**So that** 빠르게 조리를 시작할 수 있다

**Acceptance Criteria:**
- [ ] POS 결제 완료 후 2초 이내에 KDS 화면에 표시
- [ ] 알림음이 재생됨
- [ ] 주문 번호, 테이블 번호, 상품 목록이 명확히 표시됨

### US-2: 주방 직원이 조리 상태를 업데이트한다
**As a** 주방 직원
**I want to** 조리 진행 상황을 단계별로 업데이트
**So that** 홀 직원이 주문 상태를 알 수 있다

**Acceptance Criteria:**
- [ ] "조리 시작" 버튼 클릭 시 상태가 PREPARING으로 변경
- [ ] "완료" 버튼 클릭 시 상태가 READY로 변경
- [ ] 상태 변경이 실시간으로 모든 화면에 반영

### US-3: 주방 직원이 긴급 주문을 우선 처리한다
**As a** 주방 직원
**I want to** 대기 시간이 긴 주문을 한눈에 파악
**So that** 고객 불만을 줄일 수 있다

**Acceptance Criteria:**
- [ ] 15분 이상 대기 중인 주문은 빨간색으로 강조 표시
- [ ] 오래된 주문이 목록 상단에 표시
- [ ] 긴급 주문 마킹 기능

### US-4: 관리자가 주문을 취소한다
**As a** 매장 관리자
**I want to** 잘못된 주문을 취소
**So that** 불필요한 조리를 방지할 수 있다

**Acceptance Criteria:**
- [ ] 관리자 권한 확인 (PIN 또는 인증)
- [ ] 취소 사유 입력
- [ ] 취소된 주문은 별도 표시되며 히스토리 유지

---

## 5. Technical Decisions

### 5.1 Technology Stack

| Component | Technology | Reason |
|-----------|------------|--------|
| Frontend | Flutter + Material Design 3 | 기존 POS와 동일 기술 스택 유지 |
| State Management | Riverpod | 실시간 데이터 스트림 처리에 최적 |
| Database | Drift (SQLite) | 기존 DB 확장, Stream 지원 |
| Audio | audioplayers package | 알림음 재생 |
| Real-time Sync | Drift Stream | DB 변경 사항 실시간 반영 |

### 5.2 Design Patterns

- **Provider Pattern**: Riverpod으로 상태 관리
- **Repository Pattern**: DB 접근 로직 분리
- **Stream Pattern**: 실시간 주문 업데이트
- **Observer Pattern**: 주문 상태 변경 감지

### 5.3 UI/UX Design Principles

1. **Large Touch Targets**: 주방 환경에서 장갑 착용 가능성 고려
2. **High Contrast**: 밝은 주방에서도 잘 보이도록
3. **Color Coding**: 상태별 직관적인 색상
   - PENDING: Orange (#FF9800)
   - PREPARING: Blue (#2196F3)
   - READY: Green (#4CAF50)
   - CANCELLED: Red (#F44336)
4. **Minimal Text**: 아이콘과 색상으로 정보 전달
5. **Quick Actions**: 한 번의 탭으로 상태 변경

---

## 6. Implementation Plan

### Phase 1: Database & Models (Day 1 - Morning)
- [ ] KitchenOrders 테이블 추가 (Drift schema)
- [ ] KitchenOrder 모델 생성
- [ ] KitchenOrdersDao 생성
- [ ] Migration 스크립트 작성

### Phase 2: Data Layer (Day 1 - Afternoon)
- [ ] KitchenOrdersRepository 구현
- [ ] KitchenOrdersProvider (Riverpod)
- [ ] Stream provider 설정
- [ ] POS 결제 완료 시 KitchenOrder 자동 생성 로직

### Phase 3: KDS Screen UI (Day 2)
- [ ] KDS 화면 레이아웃 설계
- [ ] 주문 카드 컴포넌트
- [ ] 상태별 필터 탭
- [ ] 주문 상세 모달
- [ ] 액션 버튼 (조리시작, 완료, 서빙완료)

### Phase 4: Real-time Updates (Day 3 - Morning)
- [ ] Drift Stream 연동
- [ ] 실시간 주문 목록 업데이트
- [ ] 상태 변경 애니메이션
- [ ] 알림음 통합

### Phase 5: Additional Features (Day 3 - Afternoon)
- [ ] 주문 검색 기능
- [ ] 필터링 기능
- [ ] 대기 시간 경고
- [ ] 관리자 주문 취소 기능

### Phase 6: Testing & Polish (Day 4)
- [ ] 단위 테스트
- [ ] 통합 테스트
- [ ] UI/UX 개선
- [ ] 성능 최적화
- [ ] 다국어 지원 (l10n)

---

## 7. Risks & Mitigation

### Risk 1: 실시간 동기화 지연
**Impact**: High
**Probability**: Medium
**Mitigation**:
- Drift Stream의 성능 모니터링
- 필요 시 WebSocket 고려
- 로컬 캐시 활용

### Risk 2: 대량 주문 시 성능 저하
**Impact**: Medium
**Probability**: Low
**Mitigation**:
- 페이지네이션 도입
- 오래된 주문 자동 아카이빙
- 인덱스 최적화

### Risk 3: 네트워크 단절
**Impact**: High
**Probability**: Low
**Mitigation**:
- 로컬 DB 기반 동작
- 동일 네트워크에서만 사용
- 재연결 시 자동 동기화

---

## 8. Dependencies

### 8.1 External Dependencies
```yaml
dependencies:
  # 기존 dependencies
  flutter_riverpod: ^2.5.1
  drift: ^2.16.0

  # 신규 추가 필요
  audioplayers: ^6.0.0  # 알림음 재생
  intl: ^0.20.2         # 시간 포맷팅 (기존)
```

### 8.2 Internal Dependencies
- Sales 모듈 (POS)
- Database 모듈 (Drift)
- Auth 모듈 (관리자 권한)
- Localization 모듈

---

## 9. Acceptance Criteria

### Must Have (MVP)
- [x] 새 주문 실시간 수신 및 표시
- [x] 주문 상태 변경 (PENDING → PREPARING → READY → SERVED)
- [x] 상태별 색상 구분
- [x] 알림음 재생
- [x] 주문 시간 표시 및 경과 시간

### Should Have
- [ ] 테이블 번호/주문 번호 검색
- [ ] 상태별 필터링
- [ ] 긴급 주문 마킹
- [ ] 주문 취소 기능 (관리자)

### Could Have
- [ ] 주방 구역별 주문 분리
- [ ] 조리 예상 시간 표시
- [ ] 통계 대시보드 (일일 처리 주문 수)
- [ ] 프린터 연동 (주문서 출력)

### Won't Have (이번 버전에서 제외)
- 다중 매장 지원
- 클라우드 동기화
- 모바일 앱 (태블릿만 지원)

---

## 10. Success Criteria

### 10.1 Functional Success
- 모든 Must Have 기능 구현 완료
- POS에서 주문 후 2초 이내 KDS 표시
- 상태 변경 시 즉시 UI 반영
- 주문 누락 0건

### 10.2 Technical Success
- 테스트 커버리지 80% 이상
- 메모리 사용량 < 500MB
- CPU 사용률 < 10% (idle 시)
- 빌드 에러 0건

### 10.3 UX Success
- 주방 직원 3명 이상 테스트 통과
- 평균 작업 완료 시간 < 3초
- 사용성 점수 8/10 이상

---

## 11. Out of Scope (Phase 2 고려사항)

다음 기능들은 Phase 1에서 제외하고 향후 버전에서 고려:

1. **주방 프린터 연동**: 주문서 자동 출력
2. **음성 알림**: TTS로 주문 내용 읽어주기
3. **조리 시간 예측**: AI 기반 예상 시간 계산
4. **재료 재고 연동**: 주문 시 자동 재고 차감
5. **배달 앱 연동**: 외부 배달 주문 통합
6. **다중 디스플레이**: 여러 주방 구역별 화면
7. **웹 버전 KDS**: 태블릿 외 PC 지원

---

## 12. Appendix

### 12.1 Glossary
- **KDS**: Kitchen Display System
- **POS**: Point of Sale
- **DAO**: Data Access Object (Drift)
- **TTL**: Time To Live (주문 대기 시간)

### 12.2 References
- Flutter Riverpod 공식 문서: https://riverpod.dev
- Drift 공식 문서: https://drift.simonbinder.eu
- Material Design 3: https://m3.material.io

### 12.3 Related Documents
- `docs/02-design/features/kds.design.md` (다음 단계)
- `docs/plan_customer_management.md` (참고용)

---

**Last Updated**: 2024-02-08
**Next Step**: `/pdca design kds` - Design document 작성

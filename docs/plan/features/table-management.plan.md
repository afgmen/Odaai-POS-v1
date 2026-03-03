# 테이블 관리 (Table Management) - Plan Document

**Feature**: Table Management
**Version**: 1.0.0
**Created**: 2026-02-08
**Author**: AI Development Team
**Status**: Planning

---

## 1. Executive Summary

### 1.1 Feature Overview
테이블 관리 시스템은 식당의 테이블 배치, 상태 관리, 예약 시스템을 제공하는 핵심 기능입니다. 기존 POS 시스템 및 KDS와 완벽하게 통합되어 테이블 기반 주문 관리를 가능하게 합니다.

### 1.2 Business Value
- **운영 효율 개선**: 테이블 회전율 실시간 모니터링 → **20% 회전율 향상** 예상
- **고객 경험 향상**: 대기 시간 단축, 정확한 테이블 배정 → **고객 만족도 15% 증가**
- **매출 증대**: 효율적인 테이블 관리 → **테이블 가동률 25% 향상**
- **직원 업무 감소**: 수기 테이블 관리 제거 → **직원 업무 시간 30% 절감**

### 1.3 Success Metrics
| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| 테이블 회전율 | 수동 관리 | 실시간 추적 | 시간당 회전 횟수 |
| 평균 대기 시간 | 15분 | 10분 | 고객 대기 시간 |
| 테이블 가동률 | 70% | 85% | 사용 중 테이블 비율 |
| 예약 정확도 | 80% | 95% | 예약 충돌 감소 |

---

## 2. Problem Statement

### 2.1 Current Pain Points
1. **수동 테이블 관리**
   - 종이 도면이나 수기로 테이블 상태 관리
   - 테이블 번호와 주문 연결 누락 발생
   - 실시간 테이블 상태 파악 불가능

2. **KDS 연동 부재**
   - 현재 KDS에서 테이블 번호는 단순 텍스트 입력
   - 테이블 상태와 주문 상태 불일치
   - 서빙 완료 후 테이블 정리 타이밍 놓침

3. **예약 관리 어려움**
   - 예약 정보를 별도 시스템에서 관리
   - 예약 시간과 실제 착석 시간 불일치
   - 노쇼(No-show) 관리 미흡

4. **데이터 부족**
   - 테이블별 매출 통계 없음
   - 시간대별 테이블 사용 패턴 분석 불가
   - 인기 테이블/비인기 테이블 파악 어려움

### 2.2 User Stories
```gherkin
As a 서버(직원)
I want to 테이블 상태를 실시간으로 확인하고
So that 빈 테이블에 고객을 즉시 안내할 수 있다

As a 매니저
I want to 테이블 배치를 자유롭게 변경하고
So that 매장 레이아웃 변경에 빠르게 대응할 수 있다

As a 고객
I want to 대기 없이 빠른 착석을 원하고
So that 식사 경험이 향상된다

As a 주방 직원
I want to KDS에서 테이블 정보를 명확히 보고
So that 주문을 정확한 테이블로 서빙할 수 있다
```

---

## 3. Proposed Solution

### 3.1 Feature Scope

#### In-Scope (v1.0.0)
1. **테이블 레이아웃 관리**
   - ✅ 드래그앤드롭으로 테이블 배치
   - ✅ 테이블 추가/삭제/이동
   - ✅ 테이블 번호, 좌석 수 설정
   - ✅ 레이아웃 템플릿 저장/불러오기

2. **테이블 상태 관리**
   - ✅ 5가지 상태: 빈 테이블, 예약됨, 착석 중, 계산 완료, 정리 중
   - ✅ 실시간 상태 업데이트 (Stream)
   - ✅ 테이블 점유 시간 표시
   - ✅ 색상 코딩으로 상태 시각화

3. **예약 시스템 (기본)**
   - ✅ 예약 등록 (날짜, 시간, 인원, 고객명, 전화번호)
   - ✅ 예약 목록 조회 (오늘, 이번 주)
   - ✅ 예약 확정/취소
   - ✅ 예약 알림 (30분 전)

4. **POS/KDS 연동**
   - ✅ POS 결제 시 테이블 선택
   - ✅ KDS에 테이블 정보 자동 전달
   - ✅ 주문 완료 시 테이블 상태 자동 변경
   - ✅ 테이블별 주문 히스토리

5. **기본 통계**
   - ✅ 테이블 회전율
   - ✅ 평균 체류 시간
   - ✅ 테이블별 매출

#### Out-of-Scope (Future)
- ❌ 고급 예약 기능 (웨이팅 리스트, 포인트 적립)
- ❌ 테이블 합치기/나누기 (v1.1.0)
- ❌ QR 코드 주문 (v2.0.0)
- ❌ 고객용 예약 앱 (v2.0.0)

### 3.2 Technical Approach

#### Architecture
```
┌─────────────────────────────────────────────┐
│           Presentation Layer                │
│  ┌──────────────┐      ┌─────────────────┐ │
│  │ Table Layout │      │ Reservation UI  │ │
│  │   Screen     │◄────►│     Modal       │ │
│  └──────────────┘      └─────────────────┘ │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│            Domain Layer                     │
│  ┌──────────────┐      ┌─────────────────┐ │
│  │Table Service │      │Reservation      │ │
│  │              │◄────►│  Service        │ │
│  └──────────────┘      └─────────────────┘ │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│            Data Layer                       │
│  ┌──────────────┐      ┌─────────────────┐ │
│  │  Tables DAO  │      │ Reservations    │ │
│  │              │◄────►│     DAO         │ │
│  └──────────────┘      └─────────────────┘ │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│         Database (Drift SQLite)             │
│  ┌──────────────┐      ┌─────────────────┐ │
│  │   tables     │      │  reservations   │ │
│  └──────────────┘      └─────────────────┘ │
└─────────────────────────────────────────────┘
```

#### Tech Stack
- **Frontend**: Flutter 3.10.8+ with Material Design 3
- **State Management**: Riverpod 2.5.1 (StreamProvider for real-time updates)
- **Database**: Drift 2.16.0 (SQLite ORM)
- **Architecture**: Clean Architecture (Data → Domain → Presentation)

### 3.3 Database Schema (Preliminary)

#### tables 테이블
```sql
CREATE TABLE tables (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_number TEXT NOT NULL UNIQUE,
  seats INTEGER NOT NULL DEFAULT 4,
  position_x REAL NOT NULL DEFAULT 0,
  position_y REAL NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'AVAILABLE', -- AVAILABLE, RESERVED, OCCUPIED, CHECKOUT, CLEANING
  current_sale_id INTEGER,
  occupied_at DATETIME,
  reservation_id INTEGER,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (current_sale_id) REFERENCES sales(id) ON DELETE SET NULL,
  FOREIGN KEY (reservation_id) REFERENCES reservations(id) ON DELETE SET NULL
);

CREATE INDEX idx_tables_status ON tables(status);
CREATE INDEX idx_tables_table_number ON tables(table_number);
```

#### reservations 테이블
```sql
CREATE TABLE reservations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_id INTEGER,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  party_size INTEGER NOT NULL,
  reservation_date DATE NOT NULL,
  reservation_time TIME NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING', -- PENDING, CONFIRMED, SEATED, CANCELLED, NO_SHOW
  special_requests TEXT,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (table_id) REFERENCES tables(id) ON DELETE SET NULL
);

CREATE INDEX idx_reservations_date ON reservations(reservation_date, reservation_time);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_reservations_customer_phone ON reservations(customer_phone);
```

---

## 4. Implementation Timeline

### 4.1 Sprint Breakdown (10 Days)

#### Phase 1: Database & Models (Days 1-2)
- **Day 1**: Database migration (schema v8 → v9)
  - Create `tables` table
  - Create `reservations` table
  - Add indexes
  - Migration script
- **Day 2**: Data models & DAO
  - Table, Reservation entities
  - TablesDao, ReservationsDao
  - Stream watchers

#### Phase 2: Domain Layer (Days 3-4)
- **Day 3**: Enums & Services
  - TableStatus enum (5 states)
  - ReservationStatus enum (5 states)
  - TableService, ReservationService
- **Day 4**: Providers & Business Logic
  - Riverpod providers
  - Auto state transitions
  - POS/KDS integration logic

#### Phase 3: UI - Layout Editor (Days 5-6)
- **Day 5**: Table Layout Screen
  - Drag & drop canvas
  - Table widgets (visual representation)
  - Add/Delete/Edit table UI
- **Day 6**: Layout persistence
  - Save/Load layout
  - Template system
  - Grid snapping

#### Phase 4: UI - Status & Reservation (Days 7-8)
- **Day 7**: Table Status Management
  - Status filter tabs
  - Real-time status updates
  - Table detail modal
- **Day 8**: Reservation UI
  - Reservation form
  - Reservation list
  - Calendar view

#### Phase 5: Integration & Testing (Days 9-10)
- **Day 9**: POS/KDS Integration
  - POS: Table selection in payment flow
  - KDS: Display table info
  - Auto status sync
- **Day 10**: Testing & Polish
  - End-to-end testing
  - Bug fixes
  - Performance optimization

### 4.2 Milestone Checkpoints
| Milestone | Deliverable | Success Criteria |
|-----------|-------------|------------------|
| M1 (Day 2) | Database ready | Migration success, DAO tests pass |
| M2 (Day 4) | Business logic | Services work, Stream updates |
| M3 (Day 6) | Layout editor | Can add/move/save tables |
| M4 (Day 8) | Full UI | All screens functional |
| M5 (Day 10) | Production ready | Integration tests pass, Match Rate ≥ 90% |

---

## 5. Risks & Mitigation

### 5.1 Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Drag & drop 성능 이슈 | High | Medium | Canvas 최적화, 디바운싱 |
| 실시간 동기화 충돌 | High | Low | Optimistic locking, Stream debounce |
| Database migration 실패 | Critical | Low | 백업 스크립트, 롤백 플랜 |
| 복잡한 예약 로직 | Medium | Medium | 단순화, v2.0으로 연기 |

### 5.2 Business Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| 사용자 학습 곡선 | Medium | Medium | 직관적 UI, 튜토리얼 |
| 기존 운영 방식 변경 거부 | High | Medium | 점진적 도입, 교육 |
| 하드웨어 요구사항 증가 | Low | Low | 성능 최적화 |

---

## 6. Dependencies

### 6.1 Technical Dependencies
- ✅ Flutter 3.10.8+
- ✅ Drift 2.16.0 (already installed)
- ✅ Riverpod 2.5.1 (already installed)
- 🆕 `flutter_colorpicker: ^1.1.0` (테이블 색상 선택)
- 🆕 `table_calendar: ^3.1.0` (예약 캘린더)

### 6.2 Feature Dependencies
- ✅ **POS System** (already implemented)
- ✅ **KDS** (already implemented)
- ✅ **Sales Management** (already implemented)
- ⚠️ **Customer Management** (optional, for linking reservations)

### 6.3 Prerequisite Features
- ✅ Database schema v7/v8
- ✅ Sales DAO
- ✅ KDS integration

---

## 7. Constraints & Assumptions

### 7.1 Constraints
1. **Platform**: macOS/Windows/Linux desktop only (no mobile yet)
2. **Offline**: Must work without internet (local SQLite)
3. **Performance**: Support up to 100 tables without lag
4. **Compatibility**: Must not break existing POS/KDS features

### 7.2 Assumptions
1. 매장당 최대 50개 테이블
2. 하루 최대 200개 예약
3. 테이블 레이아웃은 자주 변경되지 않음 (월 1회 이하)
4. 동시 사용자 최대 5명 (직원)

---

## 8. Acceptance Criteria

### 8.1 Functional Requirements
1. **테이블 관리**
   - [ ] 테이블 추가/삭제/이동 가능
   - [ ] 드래그앤드롭으로 위치 변경
   - [ ] 테이블 번호, 좌석 수 설정 가능
   - [ ] 5가지 상태 시각화

2. **예약 관리**
   - [ ] 예약 등록 (필수 정보: 이름, 전화번호, 날짜, 시간, 인원)
   - [ ] 예약 목록 조회 (오늘, 이번 주)
   - [ ] 예약 확정/취소 가능
   - [ ] 노쇼 처리 가능

3. **POS 연동**
   - [ ] 결제 시 테이블 선택 가능
   - [ ] 테이블 정보가 Sale에 저장됨
   - [ ] 결제 완료 시 테이블 상태 자동 변경

4. **KDS 연동**
   - [ ] KDS 화면에 테이블 정보 표시
   - [ ] 서빙 완료 시 테이블 상태 업데이트

5. **실시간 업데이트**
   - [ ] 테이블 상태 변경 즉시 반영
   - [ ] 여러 POS 단말기에서 동시 업데이트

### 8.2 Non-Functional Requirements
1. **Performance**
   - 테이블 상태 업데이트 < 500ms
   - 레이아웃 로딩 < 1s
   - 50개 테이블 렌더링 < 2s

2. **Usability**
   - 직원 교육 시간 < 30분
   - 테이블 배치 변경 < 5분

3. **Reliability**
   - 데이터 손실 0%
   - 동기화 충돌 < 0.1%

---

## 9. Open Questions

1. **Q1**: 테이블 합치기 기능이 필요한가?
   - **A**: v1.1.0으로 연기 (Nice-to-have)

2. **Q2**: QR 코드 메뉴판과 연동할 계획인가?
   - **A**: v2.0.0 고려 (현재 스코프 아님)

3. **Q3**: 테이블별 서비스 시간 목표 설정이 필요한가?
   - **A**: v1.0.0 통계에 평균 시간만 표시, 목표 설정은 v1.1.0

4. **Q4**: 예약 시 자동 테이블 배정 알고리즘 필요한가?
   - **A**: v1.0.0은 수동 배정, v1.1.0에 자동 추천 기능 고려

---

## 10. Approval

### 10.1 Stakeholders
- **Product Owner**: User (Jin Lee)
- **Developer**: AI Development Team
- **Reviewer**: Claude Agent (Gap Detector)

### 10.2 Sign-off
- [ ] **Plan Approved**: _______________ (Date)
- [ ] **Ready for Design Phase**: Yes / No

---

## 11. Appendix

### 11.1 Glossary
- **Table Layout**: 테이블 배치도
- **Table Status**: 테이블 상태 (빈 테이블, 예약됨, 착석 중 등)
- **Reservation**: 예약
- **No-show**: 예약 후 방문하지 않은 고객
- **Table Turnover**: 테이블 회전율 (시간당 사용 횟수)

### 11.2 References
- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Riverpod Documentation](https://riverpod.dev/)
- [Drift SQLite ORM](https://drift.simonbinder.eu/)
- [Material Design 3 Guidelines](https://m3.material.io/)

### 11.3 Related Documents
- `docs/02-design/features/kds.design.md` - KDS Design Document
- `docs/01-plan/features/kds.plan.md` - KDS Plan Document
- `lib/database/app_database.dart` - Current Database Schema

---

**Document Version**: 1.0.0
**Last Updated**: 2026-02-08
**Next Review**: Before Design Phase

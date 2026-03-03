# 일일 마감 리포트 - Plan Document

## 📌 Feature Overview

### Feature Name
**일일 마감 리포트 (Daily Closing Report)**

### Feature ID
`FEAT-DAILY-CLOSING-001`

### Priority
**High** - 매일 영업 종료 시 필수적인 매출 집계 및 확인 기능

### Target Users
- 관리자 (Owner/Manager): 일일 매출 확인 및 승인
- 직원 (Cashier): 마감 리포트 생성 및 제출
- 회계 담당자: 매출 데이터 분석

---

## 🎯 Goals & Objectives

### Business Goals
1. **정확한 매출 집계**: 하루 동안의 모든 거래를 자동으로 집계
2. **시재 관리**: 현금/카드 결제 내역과 실제 시재 비교
3. **빠른 마감**: 수동 계산 없이 버튼 클릭으로 즉시 리포트 생성
4. **감사 추적**: 일일 마감 기록 보관 및 조회

### Technical Goals
1. **자동 집계**: 판매 데이터를 자동으로 계산하여 리포트 생성
2. **PDF 출력**: 인쇄 가능한 PDF 형식 지원
3. **데이터 보관**: 마감 기록을 데이터베이스에 저장
4. **실시간 조회**: 과거 마감 기록 조회 및 비교

### Success Metrics
- 마감 시간: 평균 3분 이내
- 계산 정확도: 100% (자동 계산)
- 리포트 생성 속도: 5초 이내
- 사용자 만족도: 4.5/5.0 이상

---

## 🔍 Problem Statement

### Current Issues
1. **수동 계산**: 영업 종료 후 직원이 수기로 매출을 집계해야 함
2. **시간 소요**: 마감 작업에 평균 15-30분 소요
3. **계산 오류**: 수동 계산으로 인한 실수 발생
4. **기록 부재**: 일일 매출 기록이 체계적으로 관리되지 않음
5. **비교 어려움**: 전일/전주/전월 매출 비교 불가

### Pain Points
- 관리자: "매일 마감 시간이 너무 오래 걸려요"
- 직원: "계산기로 하나씩 더하다 보면 실수가 나요"
- 회계: "과거 데이터를 찾기가 어려워요"

### Impact
- 인건비 증가: 마감 작업에 추가 인력 필요
- 정확도 저하: 수동 계산 오류로 매출 차이 발생
- 의사결정 지연: 실시간 매출 현황 파악 불가

---

## 💡 Proposed Solution

### Solution Overview
**자동 매출 집계 + 리포트 생성 + 데이터 보관**

하루 동안의 모든 판매 데이터를 자동으로 집계하여 일일 마감 리포트를 생성하고,
PDF로 출력하거나 데이터베이스에 저장하여 언제든 조회 가능.

### Core Features

#### 1. 자동 매출 집계
- **기간별 매출**: 당일 00:00 ~ 23:59 판매 데이터 집계
- **결제 수단별**: 현금, 카드, QR, 계좌이체 별도 집계
- **판매 통계**: 총 거래 건수, 평균 객단가, 총 매출액
- **세금 계산**: 부가세 별도 계산 및 표시
- **할인 내역**: 총 할인 금액 및 건수

#### 2. 시재 관리
- **현금 시재**: 현금 판매액 + 영업 준비금 - 출금
- **카드 매출**: 카드 결제 내역 (승인번호 포함)
- **차액 확인**: 예상 시재 vs 실제 시재 비교
- **출납 기록**: 현금 입출금 내역

#### 3. 리포트 생성
- **요약 리포트**: 핵심 지표 한눈에 확인
- **상세 리포트**: 거래별 상세 내역
- **비교 리포트**: 전일/전주/전월 대비 증감
- **PDF 출력**: 인쇄 및 보관용

#### 4. 데이터 보관
- **자동 저장**: 마감 승인 시 자동으로 DB에 저장
- **조회 기능**: 날짜별 과거 마감 기록 조회
- **수정 불가**: 승인된 마감은 수정 불가 (감사 추적)
- **내보내기**: CSV/Excel 형식으로 내보내기

---

## 🏗️ Architecture Overview

### System Components

```
┌─────────────────────────────────────────────────┐
│           UI Layer (Flutter)                    │
│  ┌──────────────┐  ┌───────────────────────┐   │
│  │ Closing      │  │ Report Viewer         │   │
│  │ Screen       │  │ Screen                │   │
│  └──────────────┘  └───────────────────────┘   │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│      Business Logic (Riverpod)                  │
│  ┌──────────────┐  ┌───────────────────────┐   │
│  │ Closing      │  │ Report Generator      │   │
│  │ Provider     │  │ Provider              │   │
│  └──────────────┘  └───────────────────────┘   │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│      Data Layer (Drift + SQLite)                │
│  ┌──────────────┐  ┌───────────────────────┐   │
│  │ Sales DAO    │  │ Daily Closings DAO    │   │
│  └──────────────┘  └───────────────────────┘   │
│       ↓                     ↓                    │
│  ┌──────────────┐  ┌───────────────────────┐   │
│  │  sales       │  │  daily_closings       │   │
│  │  (existing)  │  │  (new table)          │   │
│  └──────────────┘  └───────────────────────┘   │
└─────────────────────────────────────────────────┘
```

### Data Flow

```
마감 시작:
User → Closing Screen
     → Select Date
     → ClosingProvider.generateReport()
     → SalesDao.getSalesByDate()
     → Calculate Totals
     → Display Report Preview

마감 승인:
User → Confirm Button
     → ClosingProvider.saveClosing()
     → DailyClosingsDao.insert()
     → Generate PDF
     → Mark as Closed
```

---

## 📊 Data Model

### Database Schema Changes

#### 1. daily_closings 테이블 (신규)
```sql
CREATE TABLE daily_closings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  closing_date DATE NOT NULL UNIQUE,
  total_sales REAL NOT NULL,
  total_transactions INTEGER NOT NULL,
  cash_sales REAL NOT NULL,
  card_sales REAL NOT NULL,
  qr_sales REAL NOT NULL,
  transfer_sales REAL NOT NULL,
  total_tax REAL NOT NULL,
  total_discount REAL NOT NULL,
  average_transaction REAL NOT NULL,
  expected_cash REAL NOT NULL,
  actual_cash REAL,
  cash_difference REAL,
  notes TEXT,
  closed_by_employee_id INTEGER,
  closed_at DATETIME NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (closed_by_employee_id) REFERENCES employees(id)
);

CREATE INDEX idx_daily_closings_date ON daily_closings(closing_date DESC);
CREATE INDEX idx_daily_closings_employee ON daily_closings(closed_by_employee_id);
```

#### 2. 집계 데이터 구조
```dart
class DailyClosingSummary {
  final DateTime closingDate;
  final double totalSales;
  final int totalTransactions;

  // 결제 수단별
  final double cashSales;
  final double cardSales;
  final double qrSales;
  final double transferSales;

  // 세금/할인
  final double totalTax;
  final double totalDiscount;

  // 통계
  final double averageTransaction;

  // 시재 관리
  final double expectedCash;
  final double? actualCash;
  final double? cashDifference;

  // 메타데이터
  final String? notes;
  final int? closedByEmployeeId;
  final DateTime closedAt;
}
```

---

## 🎨 User Interface

### Screen Flows

#### 1. 마감 리포트 생성 화면
```
┌─────────────────────────────────────┐
│  일일 마감 리포트                    │
│  ─────────────────────────────────  │
│  마감 날짜: 2026-02-09              │
│                                     │
│  📊 매출 요약                        │
│  ┌─────────────────────────────┐   │
│  │ 총 매출액    ₩ 1,250,000     │   │
│  │ 거래 건수    85건            │   │
│  │ 평균 객단가  ₩ 14,706        │   │
│  └─────────────────────────────┘   │
│                                     │
│  💳 결제 수단별                      │
│  ┌─────────────────────────────┐   │
│  │ 현금        ₩ 450,000 (36%) │   │
│  │ 카드        ₩ 650,000 (52%) │   │
│  │ QR결제      ₩ 100,000 (8%)  │   │
│  │ 계좌이체    ₩  50,000 (4%)  │   │
│  └─────────────────────────────┘   │
│                                     │
│  💰 시재 확인                        │
│  ┌─────────────────────────────┐   │
│  │ 예상 현금   ₩ 450,000        │   │
│  │ 실제 현금   [입력: ______]   │   │
│  │ 차액        ₩ 0              │   │
│  └─────────────────────────────┘   │
│                                     │
│  [ PDF 다운로드 ]  [ 마감 승인 ]    │
└─────────────────────────────────────┘
```

#### 2. 마감 기록 조회 화면
```
┌─────────────────────────────────────┐
│  마감 기록 조회                      │
│  ─────────────────────────────────  │
│  기간: [2026-02-01] ~ [2026-02-09] │
│                                     │
│  📅 2026-02-09                       │
│  매출: ₩1,250,000 | 85건 | ✅ 완료  │
│                                     │
│  📅 2026-02-08                       │
│  매출: ₩1,180,000 | 78건 | ✅ 완료  │
│                                     │
│  📅 2026-02-07                       │
│  매출: ₩1,420,000 | 92건 | ✅ 완료  │
│                                     │
│  [ 엑셀 내보내기 ]                   │
└─────────────────────────────────────┘
```

---

## 🔧 Technical Requirements

### Development Stack
- **Frontend**: Flutter (기존 스택 유지)
- **State Management**: Riverpod (기존)
- **Database**: Drift + SQLite (기존)
- **PDF Generation**: pdf 패키지 사용

### Dependencies (신규 추가)
```yaml
dependencies:
  # PDF 생성
  pdf: ^3.10.7

  # 날짜 처리
  intl: ^0.18.1  # 이미 있음

  # CSV 내보내기
  csv: ^5.1.1
```

### Performance Requirements
- 리포트 생성 시간: 5초 이내 (100건 기준)
- PDF 생성 시간: 3초 이내
- 데이터 조회: 1초 이내 (30일 기준)
- 메모리 사용: 100MB 이하

---

## 📅 Implementation Plan

### Phase 1: 데이터베이스 및 모델 (30분)
- [ ] daily_closings 테이블 생성
- [ ] DailyClosingsDao 생성
- [ ] DailyClosingSummary 모델 정의
- [ ] 마이그레이션 v11 추가

### Phase 2: 비즈니스 로직 (30분)
- [ ] ClosingProvider 구현 (매출 집계 로직)
- [ ] generateReport() 메서드 구현
- [ ] saveClosing() 메서드 구현
- [ ] 결제 수단별 집계 로직

### Phase 3: UI 구현 (30분)
- [ ] DailyClosingScreen 생성
- [ ] 리포트 요약 위젯
- [ ] 시재 입력 폼
- [ ] 마감 기록 조회 화면

### Phase 4: PDF 생성 (20분)
- [ ] PDF 템플릿 작성
- [ ] generatePDF() 메서드 구현
- [ ] 다운로드/공유 기능

### Phase 5: 테스트 및 검증 (10분)
- [ ] 집계 계산 정확도 테스트
- [ ] PDF 생성 테스트
- [ ] 과거 데이터 조회 테스트

**총 예상 시간: 2시간**

---

## 🧪 Testing Strategy

### Test Scenarios

#### 1. 매출 집계 테스트
- [ ] 당일 판매 데이터 정확히 집계
- [ ] 결제 수단별 분류 정확성
- [ ] 세금/할인 계산 정확성
- [ ] 평균 객단가 계산

#### 2. 시재 관리 테스트
- [ ] 예상 현금 계산 (현금 판매액)
- [ ] 실제 현금 입력 및 차액 계산
- [ ] 차액 발생 시 경고 표시

#### 3. 데이터 저장 테스트
- [ ] 마감 데이터 DB 저장
- [ ] 중복 마감 방지 (UNIQUE 제약)
- [ ] 수정 불가 검증

#### 4. 조회 기능 테스트
- [ ] 날짜별 조회
- [ ] 기간별 조회
- [ ] 정렬 (최신순)

---

## 📝 Documentation

### User Documentation (필요 문서)
1. **관리자 가이드**
   - 일일 마감 방법
   - 시재 확인 방법
   - 과거 기록 조회 방법

2. **직원 가이드**
   - 마감 리포트 생성
   - PDF 다운로드

### Developer Documentation
1. **집계 로직**: 매출 계산 알고리즘
2. **PDF 템플릿**: 리포트 레이아웃
3. **API 문서**: DAO 메서드 설명

---

## ⚠️ Risks & Mitigation

### Identified Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| 집계 오류 | High | Low | 단위 테스트로 검증, 수동 확인 기능 제공 |
| 중복 마감 | Medium | Medium | DB UNIQUE 제약, UI 경고 메시지 |
| 데이터 손실 | High | Low | 트랜잭션 처리, 백업 기능 |
| PDF 생성 실패 | Low | Low | 에러 핸들링, 재시도 메커니즘 |

### Rollback Plan
- 마이그레이션 실패 시: 이전 버전 DB로 롤백
- 집계 오류 발생 시: 수동 수정 기능 제공 (관리자만)

---

## 🎯 Acceptance Criteria

### Must Have
- [ ] 당일 매출 자동 집계 (총액, 건수, 평균)
- [ ] 결제 수단별 분류 (현금, 카드, QR, 이체)
- [ ] 시재 확인 기능 (예상 vs 실제)
- [ ] 마감 데이터 저장 및 조회
- [ ] 관리자 권한 확인 (MANAGER만 마감 가능)

### Should Have
- [ ] PDF 리포트 생성 및 다운로드
- [ ] 전일/전주/전월 대비 비교
- [ ] CSV/Excel 내보내기
- [ ] 마감 메모 추가 기능

### Nice to Have
- [ ] 자동 마감 알림 (영업 종료 시간)
- [ ] 그래프 시각화
- [ ] 이메일 자동 전송
- [ ] 주간/월간 리포트

---

## 📚 References

### External Resources
- [PDF 패키지 문서](https://pub.dev/packages/pdf)
- [Drift 집계 쿼리](https://drift.simonbinder.eu/docs/advanced-features/joins/)
- [Flutter Intl 날짜 포맷](https://pub.dev/packages/intl)

### Internal Resources
- `lib/database/tables/sales.dart` - 판매 데이터
- `lib/database/daos/sales_dao.dart` - 판매 DAO
- `lib/features/auth/domain/permission.dart` - 권한 관리

---

## ✅ Sign-off

### Stakeholders
- **Product Owner**: (사용자 승인 필요)
- **Developer**: Claude (AI Agent)
- **Created**: 2026-02-09
- **Last Updated**: 2026-02-09

### Next Steps
1. ✅ Plan 문서 검토 및 승인
2. ⏳ Design 문서 작성 (`/pdca design daily-closing-report`)
3. ⏳ 구현 시작 (`/pdca do daily-closing-report`)

---

**Plan Version**: 1.0
**Feature Status**: Planning
**Estimated Effort**: 2 hours

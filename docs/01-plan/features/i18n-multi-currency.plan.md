# Plan: i18n-multi-currency

## 1. Feature Overview

### 1.1 Feature Name
다국어 및 다중 통화 지원 (Internationalization and Multi-Currency Support)

### 1.2 Feature Description
Oda POS 시스템에 3개 언어(한국어, 영어, 베트남어) 및 3개 통화(KRW, USD, VND) 지원을 추가하여 국제 시장 진출을 가능하게 합니다.

### 1.3 Background & Motivation
- **글로벌 시장 확장**: 베트남, 미국 등 해외 시장 진출 준비
- **사용자 편의성**: 각 지역 사용자가 모국어로 시스템 사용 가능
- **통화 현지화**: 각 지역 통화로 가격 표시 및 결제 처리
- **확장 가능성**: 향후 추가 언어/통화 지원을 위한 구조 마련

## 2. Goals & Success Criteria

### 2.1 Primary Goals
1. 3개 언어 지원 (한국어, English, Tiếng Việt)
2. 3개 통화 지원 (KRW ₩, USD $, VND ₫)
3. 실시간 언어/통화 전환
4. 모든 UI 텍스트 번역
5. 통화별 가격 표시 형식 적용

### 2.2 Success Metrics
- [ ] 모든 화면에서 언어 전환 가능
- [ ] 모든 UI 텍스트가 3개 언어로 번역됨
- [ ] 통화 전환 시 가격이 정확하게 표시됨
- [ ] 영수증/보고서가 선택된 언어로 출력됨
- [ ] 데이터베이스에 다국어 상품명 저장 가능
- [ ] 환율 설정 및 적용 가능

### 2.3 Non-Goals (Out of Scope)
- 자동 번역 기능
- 실시간 환율 API 연동 (수동 환율 설정만)
- 4개 이상의 언어 지원
- RTL(Right-to-Left) 언어 지원

## 3. User Stories

### US-1: 언어 전환
**As a** POS 사용자
**I want to** 시스템 언어를 한국어/영어/베트남어로 전환할 수 있다
**So that** 내 모국어로 편하게 사용할 수 있다

**Acceptance Criteria:**
- 설정 메뉴에서 언어 선택 가능
- 언어 변경 시 모든 UI 텍스트가 즉시 변경됨
- 선택한 언어가 저장되어 재시작 후에도 유지됨

### US-2: 통화 전환
**As a** 매장 관리자
**I want to** 가격을 KRW/USD/VND로 표시할 수 있다
**So that** 각 지역 고객에게 익숙한 통화로 판매할 수 있다

**Acceptance Criteria:**
- 설정 메뉴에서 통화 선택 가능
- 모든 가격이 선택된 통화 기호와 형식으로 표시됨
- 환율 설정 기능 제공
- 통화 변경 후 기존 데이터가 정확하게 변환됨

### US-3: 다국어 상품 정보
**As a** 매장 관리자
**I want to** 상품명을 여러 언어로 등록할 수 있다
**So that** 각 언어 사용자에게 적절한 상품명을 보여줄 수 있다

**Acceptance Criteria:**
- 상품 등록/수정 시 3개 언어로 상품명 입력 가능
- 언어 전환 시 해당 언어의 상품명 표시
- 번역이 없는 경우 기본 언어(한국어) 표시

### US-4: 다국어 영수증
**As a** 고객
**I want to** 영수증을 내가 선택한 언어로 받을 수 있다
**So that** 영수증 내용을 정확히 이해할 수 있다

**Acceptance Criteria:**
- 영수증이 현재 선택된 언어로 출력됨
- 통화 기호와 형식이 올바르게 표시됨
- 모든 라벨과 항목이 번역됨

## 4. Technical Approach

### 4.1 Technology Stack
- **i18n 라이브러리**: flutter_localizations + intl
- **상태 관리**: Riverpod (언어/통화 Provider)
- **데이터 저장**:
  - SharedPreferences (사용자 언어/통화 설정)
  - SQLite/Drift (다국어 상품명, 환율 설정)

### 4.2 Key Components

#### 4.2.1 언어 지원
```dart
// 지원 언어
enum AppLanguage {
  ko('ko', '한국어', 'KO'),
  en('en', 'English', 'EN'),
  vi('vi', 'Tiếng Việt', 'VI');
}

// 번역 파일 구조
lib/l10n/
  ├── app_en.arb     // 영어
  ├── app_ko.arb     // 한국어
  └── app_vi.arb     // 베트남어
```

#### 4.2.2 통화 지원
```dart
// 지원 통화
enum AppCurrency {
  krw('KRW', '₩', 'won', 1),
  usd('USD', '$', 'dollar', 0.00075),  // 기본 환율
  vnd('VND', '₫', 'dong', 19.5);       // 기본 환율
}

// 가격 포맷팅
- KRW: ₩1,000
- USD: $1.00
- VND: ₫20,000
```

#### 4.2.3 데이터베이스 스키마 확장
```sql
-- 다국어 상품명 테이블
CREATE TABLE product_translations (
  id INTEGER PRIMARY KEY,
  product_id INTEGER REFERENCES products(id),
  language TEXT NOT NULL,  -- 'ko', 'en', 'vi'
  name TEXT NOT NULL,
  description TEXT
);

-- 환율 설정 테이블
CREATE TABLE exchange_rates (
  id INTEGER PRIMARY KEY,
  from_currency TEXT NOT NULL,
  to_currency TEXT NOT NULL,
  rate REAL NOT NULL,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 설정 테이블 확장
ALTER TABLE settings ADD COLUMN language TEXT DEFAULT 'ko';
ALTER TABLE settings ADD COLUMN currency TEXT DEFAULT 'KRW';
```

### 4.3 Implementation Strategy

#### Phase 1: 기본 인프라 구축
1. flutter_localizations 패키지 추가
2. ARB 파일 생성 및 기본 번역 추가
3. 언어/통화 Provider 구현
4. 설정 저장/로드 기능 구현

#### Phase 2: UI 다국어화
1. 모든 하드코딩된 텍스트를 l10n 키로 변경
2. 동적 텍스트(상품명 등) 다국어 처리
3. 날짜/시간 포맷 현지화
4. 숫자 포맷 현지화

#### Phase 3: 통화 기능 구현
1. 통화 변환 로직 구현
2. 가격 포맷팅 함수 수정
3. 환율 설정 UI 추가
4. 데이터베이스 통화 데이터 저장

#### Phase 4: 데이터베이스 다국어화
1. product_translations 테이블 추가
2. exchange_rates 테이블 추가
3. 상품 등록/수정 UI 업데이트
4. 마이그레이션 스크립트 작성

#### Phase 5: 설정 UI 추가
1. 언어 선택 화면
2. 통화 선택 화면
3. 환율 설정 화면
4. 설정 탭에 통합

## 5. Dependencies & Prerequisites

### 5.1 Package Dependencies
```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
  shared_preferences: ^2.2.2
```

### 5.2 Dev Dependencies
```yaml
dev_dependencies:
  intl_translation: ^0.18.1  # ARB 파일 생성 도구
```

### 5.3 Prerequisites
- Drift schema version 3로 업그레이드
- 기존 데이터 마이그레이션 계획
- 번역 리소스 준비 (주요 UI 텍스트 목록)

## 6. Risks & Mitigations

### 6.1 Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| 기존 데이터 호환성 문제 | High | Medium | 마이그레이션 스크립트 철저히 테스트 |
| 번역 품질 저하 | Medium | High | 네이티브 스피커 검토 요청 |
| 통화 변환 오류 | High | Low | 단위 테스트 작성, 환율 검증 |
| 성능 저하 | Medium | Low | 번역 캐싱, 지연 로딩 적용 |

### 6.2 Mitigation Strategies
1. **마이그레이션 안전성**: 백업 기능 제공, 롤백 시나리오 준비
2. **번역 품질**: 전문 번역가 검토 또는 커뮤니티 기여
3. **테스트**: 각 언어/통화 조합별 E2E 테스트
4. **성능**: 번역 문자열 사전 로드, 메모이제이션 적용

## 7. Timeline & Milestones

### 7.1 Estimated Timeline
**Total Duration**: 2주 (10 working days)

### 7.2 Milestones

| Milestone | Duration | Description |
|-----------|----------|-------------|
| M1: 기본 인프라 | 2 days | i18n 설정, Provider, 설정 저장 |
| M2: UI 다국어화 | 3 days | 모든 화면 번역 적용 |
| M3: 통화 기능 | 2 days | 통화 변환, 포맷팅 |
| M4: DB 다국어화 | 2 days | 스키마 확장, 마이그레이션 |
| M5: 설정 UI | 1 day | 언어/통화/환율 설정 화면 |

### 7.3 Detailed Schedule

**Week 1: 기본 인프라 + UI 다국어화**
- Day 1-2: i18n 설정, Provider, ARB 파일 생성
- Day 3-5: 모든 화면 번역 키 적용

**Week 2: 통화 + DB + 설정**
- Day 6-7: 통화 변환 로직, 가격 포맷팅
- Day 8-9: 데이터베이스 스키마 확장, 마이그레이션
- Day 10: 설정 UI 완성, 테스트

## 8. Testing Strategy

### 8.1 Test Scope
- 단위 테스트: 통화 변환, 포맷팅 함수
- 위젯 테스트: 언어 전환, 통화 전환
- 통합 테스트: 전체 워크플로우 (각 언어/통화 조합)
- 마이그레이션 테스트: 기존 데이터 변환 검증

### 8.2 Test Cases
1. 언어 전환 시 모든 UI 텍스트 변경 확인
2. 통화 전환 시 가격 정확성 검증
3. 다국어 상품명 저장/조회 테스트
4. 환율 설정 및 적용 테스트
5. 영수증 다국어 출력 테스트
6. 데이터 마이그레이션 무결성 테스트

## 9. Documentation

### 9.1 User Documentation
- 언어 변경 방법 가이드
- 통화 설정 방법 가이드
- 환율 설정 가이드
- 다국어 상품 등록 가이드

### 9.2 Developer Documentation
- i18n 아키텍처 문서
- ARB 파일 작성 가이드
- 새 언어 추가 방법
- 새 통화 추가 방법
- 마이그레이션 가이드

## 10. Future Enhancements

### 10.1 Short-term (Next 3 months)
- 실시간 환율 API 연동 (선택사항)
- 추가 언어 지원 (일본어, 중국어)
- 언어별 키보드 레이아웃 지원

### 10.2 Long-term (6+ months)
- AI 기반 자동 번역
- 지역별 세금 정책 지원
- 다중 매장 통화 관리
- 통화별 재무 보고서

## 11. Approval & Sign-off

### 11.1 Stakeholders
- Product Owner: [Name]
- Tech Lead: Claude AI
- QA Lead: [Name]

### 11.2 Approval Status
- [ ] Product Owner Approved
- [ ] Tech Lead Approved
- [ ] QA Lead Approved

### 11.3 Next Steps
After approval:
1. Create Design document (`/pdca design i18n-multi-currency`)
2. Setup development environment
3. Begin Phase 1 implementation

# KDS (Kitchen Display System) 설계 대비 구현 갭 분석 결과

## 분석 개요

**분석 대상**:
- 설계 문서: `docs/02-design/features/kds.design.md`
- 구현 경로: `lib/features/kds/`
- 분석 일자: 2026-02-08
- 분석 도구: bkit:gap-detector v1.5.0

---

## Overall Match Rate: **73%**

| Category | Score | Status |
|----------|:-----:|:------:|
| Database Schema | 100% | ✅ OK |
| DAO/Repository | 95% | ✅ OK |
| Domain Layer | 90% | ✅ OK |
| Presentation Layer | 85% | ⚠️ WARN |
| POS Integration | 40% | ❌ FAIL |
| Assets/Audio | 0% | ❌ FAIL |
| Localization | 0% | ❌ FAIL |

---

## 1. Database Schema 일치 여부 - 100% ✅

| 설계서 항목 | 구현 상태 | 비고 |
|------------|:--------:|------|
| KitchenOrders 테이블 | ✅ | `lib/database/tables/kitchen_orders.dart` |
| id (autoIncrement) | ✅ | |
| saleId (FK → Sales) | ✅ | cascade delete 포함 |
| status (TEXT, default: PENDING) | ✅ | |
| priority (TEXT, default: NORMAL) | ✅ | |
| specialInstructions (nullable) | ✅ | |
| tableNumber (nullable) | ✅ | |
| startedAt, readyAt, servedAt, cancelledAt | ✅ | |
| createdAt, updatedAt | ✅ | |
| Database Migration (v8) | ✅ | `_migrateKitchenOrdersSystem()` |
| Indexes (status, created_at, sale_id) | ✅ | |

**결론**: Database 스키마는 설계서와 100% 일치합니다.

---

## 2. DAO/Repository 메서드 구현 완성도 - 95% ✅

### 2.1 DAO 메서드

| 설계서 DAO 메서드 | 구현 상태 | 구현 파일 |
|------------------|:--------:|----------|
| createFromSale() | ✅ | kitchen_orders_dao.dart:25 |
| watchActiveOrders() | ✅ | kitchen_orders_dao.dart:125 |
| watchOrdersByStatus() | ✅ | kitchen_orders_dao.dart:115 |
| getOrderById() | ✅ | kitchen_orders_dao.dart:46 |
| updateStatus() | ✅ | kitchen_orders_dao.dart:139 |
| startPreparing() | ✅ | kitchen_orders_dao.dart:171 |
| markAsReady() | ✅ | kitchen_orders_dao.dart:176 |
| markAsServed() | ✅ | kitchen_orders_dao.dart:181 |
| cancelOrder() | ✅ | kitchen_orders_dao.dart:186 |
| markAsUrgent() | ✅ | kitchen_orders_dao.dart:195 |
| deleteOldOrders() | ✅ | kitchen_orders_dao.dart:224 |

### 2.2 추가 구현됨 (설계서에 없음, 보너스 기능)

- `getAllOrders()`: 모든 주문 조회
- `getOrdersByStatus()`: 상태별 주문 조회
- `getUrgentOrders()`: 긴급 주문만 조회
- `countOrdersByStatus()`: 통계 기능
- `countTodayServedOrders()`: 오늘 처리량
- `calculateAveragePrepTime()`: 평균 조리 시간

**Repository 구현**: 100% 완료 (`kitchen_orders_repository.dart`)

---

## 3. Domain Layer 구현 - 90% ✅

### 3.1 Enums

| 설계서 항목 | 구현 상태 | 구현 파일 | 비고 |
|------------|:--------:|----------|------|
| OrderStatus enum | ✅ | `domain/enums/order_status.dart` | |
| OrderPriority enum | ✅ | `domain/enums/order_priority.dart` | |

**OrderStatus enum 비교**:
| 설계서 | 구현 | 상태 |
|--------|------|:----:|
| code, label properties | value, displayName properties | ⚠️ 이름만 다름 |
| fromCode() | fromString() | ⚠️ 이름만 다름 |
| - | isActive, isCompleted getters | ➕ 추가됨 |
| - | colorHex getter | ➕ 추가됨 |
| - | canTransitionTo() | ➕ 추가됨 |

### 3.2 Services

| 설계서 항목 | 구현 상태 | 구현 파일 | 비고 |
|------------|:--------:|----------|------|
| AudioService | ⚠️ DIFF | `domain/services/kitchen_service.dart` | KitchenService에 통합됨 |
| OrderTimerService | ❌ MISSING | - | OrderCard 위젯에 인라인 구현 |

**AudioService 분석**:
- 설계서: 별도 AudioService 클래스로 분리
- 구현: KitchenService 내부에 AudioPlayer 통합
- 기능은 동일 (newOrderSound, urgentSound, readySound)

---

## 4. Presentation Layer 구현 - 85% ⚠️

### 4.1 Providers

| 설계서 Provider | 구현 상태 | 비고 |
|----------------|:--------:|------|
| kitchenOrdersDaoProvider | ✅ | |
| kitchenOrdersRepositoryProvider | ✅ | |
| activeOrdersProvider (StreamProvider) | ✅ | `activeOrdersStreamProvider` |
| ordersByStatusProvider | ✅ | status별 개별 provider로 구현 |
| orderFilterProvider | ⚠️ | `selectedFilterProvider`로 구현 |
| searchQueryProvider | ❌ | 미구현 |
| audioEnabledProvider | ❌ | 오디오 On/Off 설정 미구현 |

### 4.2 Screen

| 설계서 항목 | 구현 상태 | 비고 |
|------------|:--------:|------|
| KdsScreen | ✅ | `presentation/screens/kds_screen.dart` |
| AppBar with title | ✅ | 한글 하드코딩 |
| FilterTabs | ✅ | |
| GridView.builder | ✅ | 3열 고정 (설계: maxCrossAxisExtent 400) |
| Search functionality | ❌ | 검색 기능 미구현 |
| Empty state | ✅ | |
| Loading/Error states | ✅ | |

### 4.3 Widgets

| 설계서 Widget | 구현 상태 | 비고 |
|--------------|:--------:|------|
| OrderCard | ✅ | |
| OrderDetailModal | ✅ | |
| FilterTabs | ✅ | |
| EmptyState | ⚠️ | 인라인 구현 (별도 위젯 아님) |
| PerformanceHeader | ➕ | 설계서에 없음 - 추가 기능 |

---

## 5. POS Integration 완료 여부 - 40% ❌

| 설계서 항목 | 구현 상태 | 비고 |
|------------|:--------:|------|
| KdsScreen import in pos_main_screen | ✅ | line 18 |
| Navigation to KDS | ✅ | AppBar 버튼 구현 |
| Payment 완료 시 KitchenOrder 생성 | ❌ | payment_modal.dart에 통합 안됨 |
| tableNumber 연동 | ❌ | |
| specialInstructions 연동 | ❌ | |

**Critical Issue**: POS 결제 완료 시 KitchenOrder가 자동 생성되지 않습니다.

**확인 사항**:
- `sales_dao.dart`의 `createSale()` 메서드에 KDS 통합 코드가 추가되었으나
- `payment_modal.dart`에서 `tableNumber`와 `specialInstructions` 파라미터를 전달하지 않음
- 실제 결제 플로우 테스트 필요

---

## 6. Assets/Audio 구현 - 0% ❌

| 설계서 항목 | 구현 상태 | 비고 |
|------------|:--------:|------|
| audioplayers dependency | ✅ | pubspec.yaml에 추가됨 |
| assets/sounds/ 폴더 | ✅ | pubspec.yaml에 등록됨 |
| new_order.mp3 | ❌ | README만 있음 |
| urgent_order.mp3 | ❌ | |
| order_ready.mp3 | ❌ | |

**현재 상태**: `assets/sounds/README.md`만 있고 실제 오디오 파일 없음

---

## 7. Localization - 0% ❌

| 설계서 항목 | 구현 상태 | 비고 |
|------------|:--------:|------|
| kitchenDisplay | ❌ | app_en.arb에 없음 |
| orderNumber | ❌ | |
| pending/preparing/ready/served | ❌ | |
| searchByOrderOrTable | ❌ | |
| 모든 KDS 관련 l10n 키 | ❌ | 한글 하드코딩됨 |

**현재 상태**: 모든 텍스트가 한글 하드코딩

---

## 구현 누락 항목 (Design ✓, Implementation ✗)

| 우선순위 | 항목 | 설계 위치 | 영향도 |
|:-------:|------|----------|:------:|
| 🔴 P0 | POS 결제 시 tableNumber/specialInstructions 전달 | Section 6.1 | HIGH |
| 🟠 P1 | Audio 파일 (mp3) | Section 10 | MEDIUM |
| 🟡 P2 | Localization 키 | Section 7 | MEDIUM |
| 🟢 P3 | searchQueryProvider | Section 5.1 | LOW |
| 🟢 P3 | audioEnabledProvider | Section 5.1 | LOW |
| 🟢 P3 | OrderTimerService 별도 분리 | Section 4.3 | LOW |
| 🟢 P3 | EmptyState 별도 위젯 | Section 1.2 | LOW |

---

## 추가 구현 항목 (Design ✗, Implementation ✓)

| 항목 | 구현 위치 | 평가 |
|------|----------|------|
| PerformanceHeader widget | `presentation/widgets/performance_header.dart` | ➕ 좋은 추가 |
| KitchenPerformance 모델 | `domain/services/kitchen_service.dart` | ➕ 좋은 추가 |
| kitchenPerformanceProvider | `domain/services/kitchen_service_provider.dart` | ➕ 좋은 추가 |
| averagePrepTimeProvider | `data/kitchen_orders_providers.dart` | ➕ 좋은 추가 |
| todayServedCountProvider | `data/kitchen_orders_providers.dart` | ➕ 좋은 추가 |
| OrderStatus.canTransitionTo() | `domain/enums/order_status.dart` | ➕ 좋은 추가 |

**평가**: 설계에 없었지만 유용한 기능들이 추가됨

---

## 설계와 다르게 구현된 항목 (Design ≠ Implementation)

| 항목 | 설계 | 구현 | 영향도 |
|------|------|------|:------:|
| AudioService | 별도 클래스 | KitchenService에 통합 | 🟢 LOW |
| OrderTimerService | 별도 서비스 | OrderCard에 인라인 | 🟢 LOW |
| GridView 레이아웃 | maxCrossAxisExtent: 400 | crossAxisCount: 3 | 🟢 LOW |
| Provider 명명 | orderFilterProvider | selectedFilterProvider | 🟢 LOW |
| Enum 프로퍼티 | code/label | value/displayName | 🟢 LOW |

**평가**: 모두 기능상 문제 없는 구현 차이

---

## 권장 조치사항

### 즉시 조치 필요 (Critical - P0)

#### 1. POS 결제 연동 완성

**목표**: 결제 완료 시 주방 주문 자동 생성

**수정 파일**: `lib/features/pos/presentation/widgets/payment_modal.dart`

**필요 작업**:
```dart
// payment_modal.dart에서 결제 완료 후
await salesDao.createSale(
  sale: saleCompanion,
  items: saleItems,
  tableNumber: tableNumber,  // ← 추가 필요
  specialInstructions: specialInstructions,  // ← 추가 필요
  createKitchenOrder: true,  // ← 기본값이지만 명시
);
```

**예상 작업 시간**: 2시간

---

### 단기 조치 (1주일 내 - P1)

#### 2. Audio 파일 추가

**목표**: 주방 알림음 재생 기능 완성

**필요 파일**:
- `assets/sounds/new_order.mp3` (1-2초, 신규 주문)
- `assets/sounds/urgent_order.mp3` (1-3초, 긴급 주문)
- `assets/sounds/order_ready.mp3` (1-2초, 조리 완료)

**참고**: `assets/sounds/README.md`에 안내 문서 있음

**예상 작업 시간**: 1시간 (무료 사운드 다운로드 + 테스트)

---

### 중기 조치 (2주 내 - P2)

#### 3. Localization 추가

**목표**: 다국어 지원 (EN, KO, VI)

**필요 작업**:
- `lib/l10n/app_en.arb`에 KDS 관련 키 추가
- `lib/l10n/app_ko.arb`에 KDS 관련 키 추가
- `lib/l10n/app_vi.arb`에 KDS 관련 키 추가
- 하드코딩된 한글을 l10n 키로 교체

**예상 키 개수**: 약 20개

**예상 작업 시간**: 3시간

---

### 장기 조치 (Backlog - P3)

4. 검색 기능 구현 (`searchQueryProvider`)
5. 오디오 On/Off 설정 구현 (`audioEnabledProvider`)
6. EmptyState 별도 위젯으로 분리
7. OrderTimerService 별도 서비스로 분리

---

## 종합 평가

### 강점 ✅

1. **Database 설계 완벽 구현**: Schema, Migration, Index 모두 일치
2. **DAO/Repository 패턴 우수**: CRUD + Stream + Statistics 완벽 구현
3. **추가 기능 제공**: PerformanceHeader, 통계 Provider 등 설계 이상의 기능
4. **Clean Architecture 준수**: Data → Domain → Presentation 계층 분리

### 약점 ❌

1. **POS 통합 미완료**: 결제→주방 자동 주문 생성 연동 미완성
2. **Audio 파일 누락**: 코드는 준비되었으나 실제 mp3 파일 없음
3. **Localization 미적용**: 한글 하드코딩으로 다국어 미지원

### 권장사항

**Match Rate 73% → 90% 달성 계획**:

1. **P0 작업 완료** (POS 통합) → +10% = 83%
2. **P1 작업 완료** (Audio 파일) → +5% = 88%
3. **P2 작업 완료** (Localization) → +5% = 93%

**총 예상 작업 시간**: 6시간 (1일 작업)

---

## 다음 단계

Match Rate가 73%로 90% 미만이므로 **Act 단계 진행**이 권장됩니다.

**옵션 1**: 수동 수정
- P0 작업만 완료하여 핵심 기능 완성 (2시간)

**옵션 2**: 자동 개선
- `/pdca iterate kds` 실행하여 자동 개선 (AI 기반)

**옵션 3**: 점진적 개선
- P0 → P1 → P2 순차 진행 (1주일)

---

**분석 완료 일시**: 2026-02-08
**분석자**: bkit:gap-detector v1.5.0
**다음 단계**: `/pdca iterate kds` 또는 수동 수정

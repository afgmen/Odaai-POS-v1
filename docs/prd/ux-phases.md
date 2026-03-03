# Odaai POS UX Improvement — Phase별 개발 태스크

**소스:** `Odaai_POS_UX_Improvement_Plan_v2.pdf` (2026-02-27)
**프로젝트:** `/Users/macmini/.openclaw/workspace/Odaai-POS-v1/`
**실행 순서:** Phase 1 → 0 → 2 → 3 → 4

---

## Phase 1: 데이터 모델 개편 (OrderType + Sales 확장 + TableStatus 추가)
**난이도:** Small | **예상:** 반나절

### 작업 내용:
1. CREATE `lib/features/pos/data/models/order_type.dart`
   - enum OrderType { dineIn, takeaway, phoneDelivery, platformDelivery }
   - displayNameEn/Vi, icon, dbValue, fromDb factory

2. MODIFY `lib/database/tables/sales.dart` — Sales Drift table에 추가:
   - orderType: TextColumn().withDefault(const Constant('dineIn'))()
   - tableId: IntColumn().nullable().references(StoreTables, #id)()
   - customerName: TextColumn().nullable()()
   - deliveryAddress: TextColumn().nullable()()
   - deliveryPhone: TextColumn().nullable()()
   - isOpenTab: BoolColumn().withDefault(const Constant(false))()

3. MODIFY `lib/database/tables/store_tables_management.dart`:
   - 'ORDERING', 'SERVED' status 추가
   - ORDERING → Color(0xFFFFC107) yellow
   - SERVED → Color(0xFF2196F3) blue

4. MODIFY `lib/database/app_database.dart`:
   - schemaVersion → 17
   - Migration v16→v17: ALTER TABLE sales ADD COLUMN 6개

5. UPDATE SalesDao: 새 필드 포함, watchOpenTabByTableId(int tableId) 추가

6. `flutter pub run build_runner build --delete-conflicting-outputs` + `flutter analyze`

---

## Phase 0: Floor Plan Designer 구축
**난이도:** Medium | **예상:** 1일

### PART A: NEW DATA MODELS
1. CREATE `lib/database/tables/floor_zones.dart` — id, name, colorHex, posX/Y, width/height, createdAt
2. CREATE `lib/database/tables/floor_elements.dart` — id, elementType(entrance|counter|restroom|window|wall|bar_counter), label, posX/Y, width/height, rotation
3. CREATE `lib/database/tables/floor_plan_config.dart` — id, canvasWidth(1000), canvasHeight(700), backgroundColorHex
4. ADD to restaurant_tables: shape (default 'square'), zoneId (nullable)
5. Register in AppDatabase, schemaVersion increment, migration

### PART B: ADMIN DESIGNER SCREEN
6. TableManagementScreen에 bottom toolbar: [존 추가] [요소 추가] [테이블 추가] [미리보기] [저장]
7. Zone rendering: 반투명 색상 사각형, Stack 순서: zones → elements → tables, 드래그/리사이즈
8. FloorElement rendering: 고정 요소(counter, entrance, restroom 등) + 아이콘
9. TableShape rendering: round(원), square(정사각), rectangle(직사각 1.6:1)
10. 미리보기 버튼 → FloorPlanOperationalScreen(previewMode: true)
11. FloorZoneDao, FloorElementDao + Riverpod providers + i18n strings
12. `build_runner build` 실행

---

## Phase 2: 플로어플랜 운영 뷰
**난이도:** Medium | **예상:** 1일

1. CREATE `lib/features/floor_plan/presentation/screens/floor_plan_screen.dart`
   - 테이블 읽기 전용 (드래그 불가), Zone/Element 배경 렌더링
   - 7가지 상태 색상 코딩
   - AppBar: 매장명, 디지털 시계, 로그인 사용자, [KDS][Summary] 버튼
   - Zone 필터 칩, 통계 스트립, 하단 액션 버튼

2. TABLE STATUS 색상 맵 (7 states):
   - AVAILABLE → Green #4CAF50
   - RESERVED → Amber #FF9800
   - ORDERING → Yellow #FFC107
   - PREPARING → Orange #FF5722
   - SERVED → Blue #2196F3
   - CHECKOUT → Purple #9C27B0
   - CLEANING → Cyan #00BCD4

3. TableWidget 개선: 모양, 경과시간, CHECKOUT 펄싱, ROUND N 뱃지

4. REAL-TIME: watchTableStatusComputedProvider — KDS 상태 기반 자동 업데이트

5. NewOrderModal: 빈 테이블 탭 시 주문 유형 선택 (매장/포장/전화배달/플랫폼배달)

6. TableDetailModal: 테이블 상세 + [추가주문][청구서요청][테이블이동][주문취소]

7. FloorPlanScreen을 AppRootScreen 첫 번째 탭으로 설정 + i18n

---

## Phase 3: Open Tab + POS 리팩토링 + 청구서 요청
**난이도:** Medium-High | **예상:** 1일

1. PosMainScreen 파라미터 확장: tableId, tableNumber, orderType, existingSaleId
2. 컨텍스트 배너: 주문 유형별 색상 표시
3. 체크아웃 분리: 매장식사 → "주방전송" (PaymentModal 안 열림) / 포장 → "결제하기"
4. BillRequestScreen: 라운드별 아이템 목록, 할인, 세금, 결제
5. TableDetailModal [청구서 요청] 연결
6. Riverpod providers: watchOpenTabByTableProvider, watchSaleItemsWithRoundsProvider
7. 테이블 이동 기능 + i18n + flutter analyze

---

## Phase 4: 전화 배달 + 추가 라운드 + KDS 개선
**난이도:** Medium | **예상:** 1일

### PART A: PHONE DELIVERY
1. PhoneDeliveryFormScreen: 전화번호 → 고객 자동조회, 주소, 예상시간, 결제방식(선불/COD)
2. PosMainScreen 전화배달 체크아웃: 선불→즉시결제, COD→Open Tab
3. SalesHistoryScreen에 orderType 필터 추가

### PART B: ADD ROUND
4. TableDetailModal [+추가주문] → PosMainScreen(existingSaleId)
5. 추가 라운드 체크아웃: 새 KitchenOrder만 생성, Sale 합산 업데이트

### PART C: KDS BADGE
6. KdsOrderCard: 주문유형 뱃지, 경과시간, Round 구분, 긴급 토글
7. 사운드 분리 (선택사항): 매장주문=기존벨, 배달주문=다른 차임
8. i18n + flutter analyze + flutter test

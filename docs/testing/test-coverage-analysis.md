# Odaai POS 테스트 커버리지 분석

**날짜**: 2026-03-01  
**분석 대상**: Odaai POS Flutter App (Phase 0~4 완료)  
**테스트 실행 환경**: Mac mini (M2), Flutter 3.38.9, Dart SDK

---

## 1. 현재 테스트 현황

### 📊 정량 지표
- **총 테스트 파일 수**: 23개
- **총 테스트 케이스 수**: 463개
- **테스트 통과율**: 100% (All tests passed!)
- **테스트 실행 시간**: ~4초

### 테스트 파일 분포
```
test/
├── features/              (18개 파일, 약 400+ 케이스)
│   ├── attendance/        1개 (출퇴근 규칙)
│   ├── auth/              1개 (권한/RBAC)
│   ├── cash_drawer/       1개 (현금 서랍 계산)
│   ├── daily_closing/     1개 (마감 계산)
│   ├── delivery/          2개 (배달 주문 모델, 상태 전환)
│   ├── kds/               4개 (주방 디스플레이, 메뉴 집계)
│   ├── loyalty/           1개 (로열티 포인트)
│   ├── pos/               3개 (장바구니, 주문 타입, Round 번호)
│   ├── products/          1개 (이미지 관리)
│   ├── promotions/        1개 (프로모션 규칙)
│   ├── tables/            2개 (테이블 상태, 이동 로직)
├── integration/           4개 (POS↔KDS↔마감, Refund, 권한, KDS 집계)
└── widget_test.dart       1개 (앱 스모크 테스트)
```

---

## 2. 테스트가 있는 모듈

| 모듈 | 테스트 파일 | 테스트 수 (추정) | 커버리지 유형 |
|------|------------|-----------------|---------------|
| **Attendance** | `attendance_rules_test.dart` | ~30 | Unit (비즈니스 로직) |
| **Auth / RBAC** | `permission_test.dart`, `permission_system_integration_test.dart` | ~40 | Unit + Integration |
| **Cash Drawer** | `cash_drawer_test.dart` | ~20 | Unit (계산 로직) |
| **Daily Closing** | `closing_calculation_test.dart` | ~30 | Unit (마감 계산) |
| **Delivery** | `delivery_order_model_test.dart`, `delivery_status_test.dart` | ~60 | Unit (모델, 상태 전환) |
| **KDS** | 4개 파일 (widget, aggregation, summary, status transition) | ~80 | Unit + Widget + Integration |
| **Loyalty** | `loyalty_points_test.dart` | ~20 | Unit (포인트 계산) |
| **POS** | `cart_integrity_test.dart`, `order_type_test.dart`, `round_number_test.dart` | ~50 | Unit + Provider |
| **Products** | `image_management_test.dart` | ~10 | Unit (이미지 서비스) |
| **Promotions** | `promotion_rules_test.dart` | ~20 | Unit (할인 계산) |
| **Tables** | `table_status_test.dart`, `table_move_logic_test.dart` | ~30 | Unit (상태, 이동 로직) |
| **Integration** | 4개 통합 테스트 | ~60 | Integration (in-memory DB) |

**총계**: ~450개 케이스 (실제 463개)

---

## 3. 테스트가 없는 모듈 (GAP) 🚨

### 3-1. Phase 0~4 신규 기능 (테스트 누락)

| 모듈/기능 | 중요도 | 권장 테스트 유형 | 상세 |
|-----------|--------|------------------|------|
| **Floor Plan Designer** | P0 | Widget + Integration | Zone/Element CRUD, drag-and-drop, 저장/로드 |
| **Floor Plan Operation View** | P0 | Widget + Integration | 테이블 상태 변경, 주문 생성, 실시간 업데이트 |
| **OdaColors 테마** | P1 | Unit | 색상 상수 검증, 테마 일관성 |
| **User Guide / Tutorial** | P2 | Widget | Tutorial overlay, 단계별 진행 |

### 3-2. 기존 기능 (테스트 부재)

| 모듈 | 중요도 | 권장 테스트 유형 | 상세 |
|------|--------|------------------|------|
| **Backup/Restore** | P0 | Integration | JSON export/import, 데이터 무결성 |
| **Dashboard** | P1 | Widget + Integration | 실시간 통계, 차트, 저재고 알림 |
| **Employees** | P0 | Unit + Integration | 직원 CRUD, 근무 시간 집계 |
| **Reports** | P0 | Integration | 매출 리포트, 날짜 범위, 필터링 |
| **Settings** | P1 | Widget + Integration | 설정 저장/로드, 검증 |
| **Sync** | P0 | Integration | 멀티 디바이스 동기화, 충돌 해결 |
| **Refunds** (UI) | P1 | Widget | 환불 화면, 사용자 플로우 |
| **Customers** | P1 | Unit + Integration | 고객 CRUD, 검색 |
| **Reservations** | P1 | Unit + Widget | 예약 생성, 시간 검증, 충돌 방지 |

### 3-3. UI/Widget 테스트 전반적 부족

현재 **widget_test**는 단 1개 (앱 스모크 테스트)만 존재.  
모든 Screen/Modal은 **수동 UAT**에 의존하고 있음.

**누락된 주요 UI**:
- `PosMainScreen` (주문 화면)
- `FloorPlanScreen` (Phase 0/2)
- `TableMoveModal` (Phase 0)
- `PaymentModal`
- `KdsScreen` (widget_test 1개 있음, 부족)
- `DailyClosingScreen`
- `AttendanceCheckScreen`
- `ProductManagementScreen`
- 기타 30+ 스크린

---

## 4. Phase 0~4 신규 기능 테스트 상태

| Phase | 기능 | 테스트 존재 | 상태 | 비고 |
|-------|------|-------------|------|------|
| **Phase 0** | Floor Plan Designer | ❌ | GAP | UI CRUD, 드래그 로직 |
| **Phase 0** | FloorElementWidget | ❌ | GAP | Widget 렌더링 |
| **Phase 0** | FloorZoneWidget | ❌ | GAP | Widget 렌더링 |
| **Phase 2** | Floor Plan Operation View | ❌ | GAP | 테이블 상호작용 |
| **Phase 3** | Open Tab / POS Refactoring | ⚠️ | 부분 | `round_number_test.dart` 있음 |
| **Phase 3** | Order Type (dineIn/takeaway/delivery) | ✅ | Pass | `order_type_test.dart` |
| **Phase 4** | Phone Delivery | ✅ | Pass | `delivery_order_model_test.dart` |
| **Phase 4** | Platform Delivery | ✅ | Pass | `delivery_status_test.dart` |
| **Phase 4** | Add Round | ✅ | Pass | `round_number_test.dart` |
| **Phase 4** | KDS Improvements | ✅ | Pass | `menu_item_summary_test.dart` |
| **Phase 0** | Table Move | ✅ | Pass | `table_move_logic_test.dart` (로직만, UI 없음) |
| **Phase ?** | OdaColors / Theme | ❌ | GAP | 색상 상수 검증 |
| **Phase ?** | User Guide / Tutorial | ❌ | GAP | Widget 테스트 |

### ✅ 잘된 점:
- Delivery, KDS, Order Type, Table Move **비즈니스 로직**은 충분히 테스트됨
- Integration 테스트가 실제 DB와 연동하여 신뢰도 높음

### 🚨 문제점:
- **Floor Plan** 전체 (Phase 0/2의 핵심) → 테스트 제로
- **UI/Widget** 테스트가 거의 없어 사용자 경험 버그 탐지 불가

---

## 5. 권장 테스트 추가 목록 (우선순위별)

### P0 (필수) — 비즈니스 크리티컬

1. **Floor Plan Designer 통합 테스트**
   - Zone/Element CRUD (생성, 수정, 삭제)
   - drag-and-drop 위치 계산 로직
   - DB 저장/로드 무결성

2. **Floor Plan Operation View Widget 테스트**
   - 테이블 상태 변경 (탭하여 ORDERING → PREPARING)
   - 주문 생성 플로우 (NewOrderModal)
   - 테이블 이동 (TableMoveModal)

3. **Backup/Restore 통합 테스트**
   - JSON export 완전성
   - JSON import 복원 검증
   - 버전 호환성

4. **Reports 통합 테스트**
   - 일별/주별/월별 매출 집계
   - 날짜 범위 필터링
   - 결제 수단별 분류

5. **Sync 통합 테스트**
   - 멀티 디바이스 충돌 해결
   - `needsSync` 플래그 동작
   - 네트워크 오류 처리

6. **Employees 통합 테스트**
   - 직원 CRUD
   - 근무 시간 집계
   - 급여 계산 (if any)

---

### P1 (권장) — 사용자 경험 보호

7. **Dashboard Widget 테스트**
   - 실시간 통계 위젯 렌더링
   - 저재고 알림 표시
   - 차트 데이터 바인딩

8. **PosMainScreen Widget 테스트**
   - 메뉴 선택 → 장바구니 추가
   - 수량 증감
   - 할인 적용
   - 결제 플로우 진입

9. **PaymentModal Widget 테스트**
   - 결제 수단 선택
   - 금액 계산 (잔돈)
   - 영수증 출력 트리거

10. **Refunds Widget 테스트**
    - 환불 사유 입력
    - 부분 환불 / 전체 환불 선택
    - 재고 복원 확인

11. **Settings 통합 테스트**
    - 설정 저장/로드
    - 검증 규칙 (예: 프린터 주소 포맷)

12. **Customers 통합 테스트**
    - 고객 CRUD
    - 검색 (전화번호, 이름)
    - 주문 이력 조회

13. **Reservations 통합 테스트**
    - 예약 생성 (날짜/시간 검증)
    - 테이블 충돌 방지
    - 예약 취소

14. **OdaColors Unit 테스트**
    - 모든 색상 상수가 non-null
    - 테마 일관성 (primary, accent, error)

---

### P2 (선택) — 부가 기능

15. **User Guide / Tutorial Widget 테스트**
    - Tutorial overlay 렌더링
    - 단계별 진행 (next/skip)
    - 설정 저장 (다시 보지 않기)

16. **AttendanceCheckScreen Widget 테스트**
    - PIN 입력 → 출근/퇴근 버튼
    - 위치 기반 체크인 (if any)

17. **ProductManagementScreen Widget 테스트**
    - 상품 목록 렌더링
    - 검색/필터링
    - 이미지 업로드 UI

18. **Low-priority Screens**
    - AuditLogScreen
    - LeaveRequestScreen
    - SecuritySettingsScreen

---

## 6. CI 현황 및 개선 사항

### 현재 CI 설정
- **파일**: `.github/workflows/*.yml`
- **트리거**: push to `main/master/develop`, PR, manual dispatch
- **작업**:
  1. Flutter pub get
  2. build_runner
  3. Build Debug/Release APK
  4. Upload artifacts

### ⚠️ 문제점: 테스트 실행 없음!
**CI가 `flutter test`를 실행하지 않음**  
→ PR이나 push 시 테스트 결과를 검증하지 않음  
→ 테스트가 깨져도 빌드는 통과함

### 권장 개선 사항

#### 6-1. CI에 테스트 단계 추가

```yaml
- name: Run tests
  run: flutter test --reporter expanded

- name: Check test coverage (optional)
  run: |
    flutter test --coverage
    lcov --summary coverage/lcov.info
```

#### 6-2. Pre-commit Hook 추가

```bash
# .git/hooks/pre-commit
#!/bin/sh
flutter test
if [ $? -ne 0 ]; then
  echo "❌ Tests failed. Commit aborted."
  exit 1
fi
```

#### 6-3. Coverage 보고서 생성

- codecov.io 또는 Coveralls 연동
- 목표: 핵심 비즈니스 로직 80%+ 커버리지

---

## 7. Dede 태스크 초안 (구체적인 테스트 작성 지시)

### 태스크 1: Floor Plan Designer 테스트 작성

**목표**: Floor Plan Designer의 핵심 비즈니스 로직과 UI 상호작용을 검증하는 테스트 작성

**생성할 파일**:
1. `test/features/floor_plan/floor_plan_dao_test.dart` (Unit)
2. `test/features/floor_plan/floor_plan_screen_widget_test.dart` (Widget)

**테스트 시나리오**:

#### 1-1. DAO 단위 테스트 (floor_plan_dao_test.dart)
- Zone 생성/수정/삭제
- Element (테이블/데코) 생성/수정/삭제
- Zone에 Element 할당
- 같은 이름의 Zone 중복 방지
- Element 좌표 범위 검증 (0~1000)

```dart
// 예시 구조
group('FloorZoneDao', () {
  test('create zone with valid name', () async { ... });
  test('delete zone cascades to elements', () async { ... });
  test('duplicate zone name throws error', () async { ... });
});

group('FloorElementDao', () {
  test('create table element with position', () async { ... });
  test('move element updates coordinates', () async { ... });
  test('delete element does not affect zone', () async { ... });
});
```

#### 1-2. Widget 테스트 (floor_plan_screen_widget_test.dart)
- FloorPlanScreen 렌더링 확인
- Zone 추가 버튼 → 다이얼로그 표시
- Element 위젯 표시 확인
- drag 제스처 → 좌표 업데이트 (시뮬레이션)

```dart
testWidgets('Floor plan screen renders zones', (tester) async {
  await tester.pumpWidget(_wrapWithProviders(FloorPlanScreen()));
  expect(find.byType(FloorZoneWidget), findsWidgets);
});

testWidgets('Tap add zone button shows dialog', (tester) async {
  await tester.pumpWidget(_wrapWithProviders(FloorPlanScreen()));
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();
  expect(find.text('Zone 이름 입력'), findsOneWidget);
});
```

---

### 태스크 2: Backup/Restore 통합 테스트

**목표**: JSON export/import의 완전성 및 데이터 무결성 검증

**생성할 파일**:
- `test/features/backup/backup_restore_integration_test.dart`

**테스트 시나리오**:
1. 전체 DB export → JSON 파일 생성
2. JSON 파일 import → 데이터 복원 확인
3. 외래 키 무결성 유지 확인
4. 버전 호환성 (구버전 JSON import)

```dart
test('Export full database to JSON', () async {
  final db = _openDb();
  // Insert mock data
  await _insertMockProducts(db);
  await _insertMockSales(db);
  
  final json = await BackupService(db).exportToJson();
  expect(json, contains('products'));
  expect(json, contains('sales'));
  
  final parsed = jsonDecode(json);
  expect(parsed['products'].length, greaterThan(0));
});

test('Import JSON restores all data', () async {
  final db1 = _openDb();
  await _insertMockProducts(db1);
  final exported = await BackupService(db1).exportToJson();
  
  final db2 = _openDb(); // clean DB
  await BackupService(db2).importFromJson(exported);
  
  final products = await db2.select(db2.products).get();
  expect(products.length, greaterThan(0));
});
```

---

### 태스크 3: CI에 flutter test 단계 추가

**목표**: GitHub Actions CI에서 모든 테스트를 실행하고 결과를 검증

**수정할 파일**:
- `.github/workflows/*.yml` (Build Android APK workflow)

**추가할 단계** (build_runner 이후, APK 빌드 전):

```yaml
    - name: Run unit and integration tests
      run: flutter test --reporter expanded
      
    - name: Generate coverage report
      run: flutter test --coverage
      
    - name: Upload coverage to Codecov (optional)
      uses: codecov/codecov-action@v3
      with:
        files: coverage/lcov.info
```

**성공 조건**:
- 모든 테스트가 통과해야 APK 빌드 진행
- 테스트 실패 시 workflow 실패 처리

---

### 태스크 4: Dashboard Widget 테스트

**목표**: 대시보드 화면의 실시간 통계 위젯 렌더링 검증

**생성할 파일**:
- `test/features/dashboard/dashboard_screen_widget_test.dart`

**테스트 시나리오**:
1. DashboardScreen 렌더링 확인
2. 오늘 매출 카드 표시 확인
3. 저재고 알림 리스트 표시
4. 차트 위젯 렌더링 (find.byType)

```dart
testWidgets('Dashboard shows today sales card', (tester) async {
  await tester.pumpWidget(_wrapWithProviders(DashboardScreen()));
  expect(find.text('오늘 매출'), findsOneWidget);
  expect(find.byIcon(Icons.attach_money), findsWidgets);
});

testWidgets('Dashboard shows low stock alerts', (tester) async {
  // Mock low stock products
  await tester.pumpWidget(_wrapWithProviders(DashboardScreen()));
  await tester.pumpAndSettle();
  expect(find.text('재고 부족'), findsOneWidget);
});
```

---

### 태스크 5: PosMainScreen Widget 테스트

**목표**: POS 주문 화면의 핵심 사용자 플로우 검증

**생성할 파일**:
- `test/features/pos/pos_main_screen_widget_test.dart`

**테스트 시나리오**:
1. 메뉴 목록 렌더링
2. 메뉴 아이템 탭 → 장바구니 추가
3. 장바구니 수량 증감 버튼
4. 결제 버튼 탭 → PaymentModal 표시

```dart
testWidgets('Tap menu item adds to cart', (tester) async {
  await tester.pumpWidget(_wrapWithProviders(PosMainScreen()));
  await tester.tap(find.text('Pho Bo'));
  await tester.pumpAndSettle();
  
  expect(find.text('1'), findsOneWidget); // cart badge
});

testWidgets('Tap payment button shows PaymentModal', (tester) async {
  // Add items to cart first
  await tester.pumpWidget(_wrapWithProviders(PosMainScreen()));
  await tester.tap(find.byIcon(Icons.payment));
  await tester.pumpAndSettle();
  
  expect(find.byType(PaymentModal), findsOneWidget);
});
```

---

### 태스크 6: OdaColors Unit 테스트

**목표**: 테마 색상 상수의 유효성 검증

**생성할 파일**:
- `test/core/theme/oda_colors_test.dart`

**테스트 시나리오**:
- 모든 색상 상수가 null이 아님
- 색상 값이 유효한 범위 (0x00000000 ~ 0xFFFFFFFF)
- primary와 accent의 대비 검증 (가독성)

```dart
test('All OdaColors constants are non-null', () {
  expect(OdaColors.primary, isNotNull);
  expect(OdaColors.accent, isNotNull);
  expect(OdaColors.error, isNotNull);
  // ... 모든 색상 검증
});

test('Primary and accent colors have sufficient contrast', () {
  final primaryLuminance = OdaColors.primary.computeLuminance();
  final accentLuminance = OdaColors.accent.computeLuminance();
  final contrast = _calculateContrast(primaryLuminance, accentLuminance);
  expect(contrast, greaterThan(3.0)); // WCAG AA 기준
});
```

---

## 8. 요약 및 액션 플랜

### 현재 상태:
- ✅ **비즈니스 로직** 테스트는 양호 (463개 통과)
- ✅ **Integration** 테스트가 in-memory DB로 실전 시나리오 커버
- 🚨 **UI/Widget** 테스트가 거의 전무 (1개만 존재)
- 🚨 **Floor Plan** (Phase 0/2 핵심) 테스트 제로
- 🚨 CI에서 **테스트를 실행하지 않음** → 품질 게이트 부재

### 액션 플랜 (우선순위):

#### Week 1 (긴급)
1. ✅ **CI에 `flutter test` 단계 추가** (태스크 3)
2. 🏗️ **Floor Plan Designer 테스트 작성** (태스크 1) → P0
3. 🏗️ **Backup/Restore 통합 테스트** (태스크 2) → P0

#### Week 2-3 (중요)
4. 🖼️ **PosMainScreen Widget 테스트** (태스크 5) → P1
5. 🖼️ **Dashboard Widget 테스트** (태스크 4) → P1
6. 🏗️ **Reports 통합 테스트** → P0
7. 🏗️ **Employees 통합 테스트** → P0

#### Week 4+ (개선)
8. 🖼️ **Refunds/Settings/Customers Widget 테스트** → P1
9. 🎨 **OdaColors Unit 테스트** (태스크 6) → P1
10. 📚 **User Guide Widget 테스트** → P2

### 최종 목표:
- **코어 비즈니스 로직**: 80%+ 커버리지 유지
- **UI/Widget**: 주요 스크린 30개 중 최소 15개 커버
- **CI**: 모든 PR에서 테스트 통과 필수
- **품질 게이트**: 테스트 실패 시 머지 불가

---

**끝.**

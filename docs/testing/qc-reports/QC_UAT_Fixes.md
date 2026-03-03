# QC Report: UAT 미완성 항목 수정

**날짜**: 2026-03-01
**QC 담당**: Mama (서브에이전트)
**코드 위치**: `/Users/macmini/.openclaw/workspace/Odaai-POS-v1`

---

## Summary
- **Result**: ❌ **FAIL**
- **P0 항목**: 0/1 완료 (❌ 미완료)
- **P1 항목**: 1/3 완료 (⚠️ 부분 완료)
- **P2 항목**: 0/1 완료 (❌ 미완료)

**총평**: UAT 픽스 중 가장 중요한 P0 항목(Delivery Order UI)이 완료되지 않았으며, P1 항목 3개 중 2개도 미완료 상태입니다.

---

## P0: Delivery Order 고객 정보 입력 UI
- **Status**: ❌ **미완료**

### 발견 사항:
1. **Sales 테이블 필드는 존재함** (`lib/database/tables/sales.dart`):
   - `customerName` ✅
   - `deliveryAddress` ✅
   - `deliveryPhone` ✅
   - `orderType` ✅

2. **PaymentModal에 UI 필드가 없음** (`lib/features/pos/presentation/widgets/payment_modal.dart`):
   - ❌ customerName 입력 필드 없음
   - ❌ deliveryPhone 입력 필드 없음
   - ❌ deliveryAddress 입력 필드 없음
   - ❌ orderType 조건부 표시 로직 없음
   - ✅ tableNumber 필드만 존재 (KDS용)
   - ✅ specialInstructions 필드 존재

3. **SalesCompanion에 delivery 필드 미포함**:
   ```dart
   // 라인 447: SalesCompanion.insert()에 다음 필드 누락
   // - orderType (phoneDelivery/platformDelivery)
   // - customerName
   // - deliveryAddress
   // - deliveryPhone
   ```

4. **DeliveryOrdersDao는 존재하지만 POS와 연동 안 됨**:
   - `lib/features/delivery/data/delivery_orders_dao.dart` ✅
   - `lib/database/tables/delivery_orders.dart` ✅
   - 하지만 PaymentModal에서 DeliveryOrders 테이블에 저장하는 로직 없음

### 필요한 수정:
1. PaymentModal에 orderType selector 추가 (dineIn/takeaway/phoneDelivery/platformDelivery)
2. orderType이 phoneDelivery/platformDelivery일 때만 표시되는 조건부 필드:
   - customerName (required)
   - deliveryPhone (required)
   - deliveryAddress (required for delivery)
3. SalesCompanion.insert()에 위 필드들 추가
4. 입력값 validation 추가

---

## P1: Floor Plan Designer CRUD UI
- **Status**: ❌ **미완료**

### 발견 사항:
1. **DAO는 존재함**:
   - `floor_zone_dao.dart` ✅
   - `floor_element_dao.dart` ✅
   - CRUD 메서드 (insert/update/delete) 모두 있음

2. **Floor Plan Screen은 읽기 전용** (`lib/features/floor_plan/presentation/screens/floor_plan_screen.dart`):
   - 라인 17: "읽기 전용 (드래그 불가), 실시간 상태 업데이트"
   - Zone/Element/Table 추가/수정/삭제 UI 없음

3. **Modal 파일들**:
   - `new_order_modal.dart` - 새 주문 생성용 (디자이너 아님)
   - `table_detail_modal.dart` - 테이블 상세 (편집 기능 없음)
   - `table_move_modal.dart` - 테이블 이동 전용
   - ❌ Add Zone Modal 없음
   - ❌ Add Element Modal 없음
   - ❌ Add Table Modal 없음
   - ❌ Edit/Delete 기능 없음

### 필요한 수정:
1. Floor Plan Designer 전용 화면 생성 (FloorPlanDesignerScreen)
2. Zone 추가/수정/삭제 모달 (name, color)
3. Element 추가/수정/삭제 모달 (type, label)
4. Table 추가/수정/삭제 모달 (number, seats, shape)
5. 각 항목마다 Edit/Delete 버튼

---

## P1: Backup Restore
- **Status**: ✅ **완료** (부분)

### 발견 사항:
1. **BackupService.createBackup()**: ✅ 구현됨
   - `lib/features/backup/domain/services/backup_service.dart`
   - 라인 70~158: 백업 생성 로직 완성

2. **BackupService.restoreBackup()**: ❌ **메서드 없음**
   - createBackup은 있지만 restoreBackup 메서드가 존재하지 않음
   - 복원 기능 전혀 구현 안 됨

3. **Admin UI Backup/Restore 버튼**: ❌ **없음**
   - `lib/features/settings/presentation/screens/settings_screen.dart` 확인
   - Backup/Restore 관련 UI 전혀 없음
   - role_permissions_screen에 "restore" 아이콘 1개 발견되었으나 백업 복원과 무관 (권한 초기화)

### 필요한 수정:
1. **BackupService.restoreBackup()** 메서드 구현:
   - 백업 파일 검증
   - 현재 DB 백업 후 교체
   - WAL 체크포인트
   - 메타데이터 검증
2. **Settings Screen에 Backup 섹션 추가**:
   - "Create Backup" 버튼
   - "Restore Backup" 버튼
   - 백업 목록 표시
3. RBAC 권한 검증 (Admin/Owner만 접근)

---

## P1: KDS Stats Badge
- **Status**: ❌ **미완료** (하드코딩 그대로)

### 발견 사항:
1. **POS Main Screen** (`lib/features/pos/presentation/screens/pos_main_screen.dart`):
   - 라인 788~825: `_KdsStatsBadges` 위젯 존재
   - 라인 801: `value: '0'` ← 하드코딩
   - 라인 808: `value: '0'` ← 하드코딩
   - 라인 815: `value: '0m 0s'` ← 하드코딩

2. **DB 쿼리 없음**:
   - KDS 관련 DAO 쿼리 호출 없음
   - Riverpod provider 없음
   - 실시간 업데이트 스트림 없음

### 필요한 수정:
1. **KitchenOrdersDao에 통계 쿼리 추가**:
   ```dart
   Stream<int> watchCompletedCount();
   Stream<int> watchInProgressCount();
   Future<Duration> getAverageCompletionTime();
   ```
2. **Provider 생성**:
   ```dart
   final kdsCompletedCountProvider = StreamProvider<int>(...);
   final kdsInProgressCountProvider = StreamProvider<int>(...);
   final kdsAverageTimeProvider = FutureProvider<Duration>(...);
   ```
3. **_KdsStatsBadges에서 provider 사용**:
   ```dart
   final completed = ref.watch(kdsCompletedCountProvider);
   final inProgress = ref.watch(kdsInProgressCountProvider);
   final avgTime = ref.watch(kdsAverageTimeProvider);
   ```

---

## P2: Currency DB Integration
- **Status**: ❌ **미완료** (TODO 그대로)

### 발견 사항:
1. **TODO 주석 존재** (`lib/providers/currency_provider.dart`):
   - 라인 43: `// TODO: 데이터베이스에서 환율 조회`
   - 라인 44~45: 주석 처리된 DB 조회 코드
   - 라인 48: 임시 하드코딩 `AppCurrency.fromCode(toCurrency).defaultRate`

2. **SharedPreferences만 사용 중**:
   - 라인 19~26: `_loadSavedCurrency()`는 SharedPreferences만 사용
   - 라인 33: `setCurrency()`도 SharedPreferences만 저장

3. **DB 테이블 미확인**:
   - AppSettings 테이블 존재 여부 미확인
   - ExchangeRates 테이블 존재 여부 미확인

### 필요한 수정:
1. TODO 제거하고 실제 DB 연동:
   ```dart
   final db = ref.watch(databaseProvider);
   final rate = await db.getExchangeRate('VND', toCurrency);
   return rate ?? AppCurrency.fromCode(toCurrency).defaultRate;
   ```
2. `_loadSavedCurrency()`와 `setCurrency()`에도 DB 연동 추가
3. 필요 시 AppSettings 테이블에 currency_code 저장
4. 필요 시 ExchangeRates 테이블 추가 (base_currency, target_currency, rate, updated_at)

---

## flutter test
```
00:05 +530: All tests passed!
```
- ✅ **530개 테스트 모두 통과**
- Backup 테스트 포함 (backup_restore_test.dart)
- 기존 기능 회귀 없음

---

## flutter analyze
```
3 issues found. (ran in 3.1s)

info • The imported package 'matcher' isn't a dependency 
     • test/features/floor_plan/floor_plan_designer_provider_test.dart:7:8

info • Type could be non-nullable 
     • test/features/promotions/promotion_rules_test.dart:246:18

info • Type could be non-nullable 
     • test/features/promotions/promotion_rules_test.dart:254:18
```
- ⚠️ **3개 정보성 경고** (모두 테스트 파일)
- 프로덕션 코드에는 분석 오류 없음
- 경미한 수준 (nullable 최적화 권장)

---

## Issues

### 🔴 Critical (P0)
1. **Delivery Order UI 전체 미구현**
   - PaymentModal에 customerName, deliveryPhone, deliveryAddress 입력 필드 없음
   - orderType 조건부 로직 없음
   - SalesCompanion에 필드 누락
   - 고객이 배달 주문 시 필수 정보 입력 불가

### 🟠 High (P1)
2. **Floor Plan Designer CRUD UI 전체 미구현**
   - Zone/Element/Table 추가/수정/삭제 모달 없음
   - 현재 읽기 전용 화면만 존재
   - 관리자가 매장 레이아웃 수정 불가

3. **Backup Restore 메서드 없음**
   - createBackup만 있고 restoreBackup 없음
   - Admin UI에 버튼 없음
   - 백업 파일 복원 불가능

4. **KDS Stats Badge 하드코딩**
   - 모든 값이 '0'으로 고정
   - 실시간 주방 상태 파악 불가
   - KDS 모니터링 무용지물

### 🟡 Medium (P2)
5. **Currency TODO 주석 그대로**
   - DB 연동 안 됨
   - 환율 업데이트 불가
   - 다중 통화 지원 제한적

---

## Recommendations

### 즉시 수정 필요 (P0, P1 - 위험도 높음)
1. **Delivery Order UI** (예상 소요: 4~6시간)
   - PaymentModal 리팩토링
   - OrderType selector 추가
   - 조건부 필드 + validation
   - SalesCompanion 업데이트

2. **Floor Plan Designer** (예상 소요: 8~12시간)
   - FloorPlanDesignerScreen 신규 생성
   - 3개 엔티티 × CRUD 모달 × 3 = 9개 모달
   - DAO 연동
   - UI/UX 테스트

3. **Backup Restore** (예상 소요: 4~6시간)
   - restoreBackup() 메서드 구현
   - Settings UI 백업 섹션 추가
   - 복원 테스트 (파괴적 작업이므로 주의)

4. **KDS Stats Real-time** (예상 소요: 2~3시간)
   - DAO 통계 쿼리 3개
   - Provider 3개
   - 위젯 연동

### 우선순위 낮음 (P2)
5. **Currency DB** (예상 소요: 2~3시간)
   - TODO 제거
   - DB 스키마 확인/추가
   - Provider 수정

---

## 결론

**총 20개 UAT 픽스 항목 중 1개만 완료 (Backup 생성), 나머지 4개 미완료.**

가장 중요한 P0 항목(배달 주문 고객 정보)이 완전히 누락되어 있으며, P1 항목들도 절반 이상 미완료 상태입니다. 

현재 상태로는 **UAT 통과 불가**하며, 최소 P0와 P1 항목들을 모두 완료한 후 재QC가 필요합니다.

**예상 추가 개발 시간**: 약 20~30시간 (1인 기준, 테스트 포함)

---

**QC 완료 시각**: 2026-03-01 21:35 (GMT+7)
**다음 단계**: Dede에게 미완료 항목 전달 및 우선순위 재조정 필요

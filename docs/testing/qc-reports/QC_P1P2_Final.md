# QC Report: P1-4 ~ P2-7 최종 검증

**날짜**: 2026-03-02  
**검증자**: Mama (QC Subagent)  
**Result**: ❌ **FAIL** (컴파일 에러 존재)

---

## P1-4: Split Bill (균등 분할)

**Status**: ✅ **구현 완료** (로직 정상)

### 파일 존재
- ✅ `lib/features/pos/presentation/widgets/split_bill_modal.dart` 존재

### 구현 내용
- ✅ **균등 분할 로직**: 
  - `_splitCount` 변수로 2~10명 선택 가능
  - `perPersonAmount = (sale.total / _splitCount).ceil()` 올림 처리
  - `_processSplit()`: 분할된 인원 수만큼 새로운 Sale 생성
  - 원본 Sale status를 `'split'`으로 변경
- ✅ **PaymentModal 연결**: 
  - `payment_modal.dart:426` → `_showSplitBillModal()` 메서드 호출
  - Icon: `Icons.splitscreen`, Label: 'Split Bill'

### 검증 결과
- 로직 구현 완료, DB 트랜잭션 정상
- UI: 인원 수 증감 버튼, 1인당 금액 표시 카드 리스트

---

## P1-5: KDS View Toggle

**Status**: ✅ **구현 완료**

### 구현 내용
- ✅ **토글 버튼**: 
  - `kds_screen.dart:32-41` → IconButton으로 구현
  - `showMenuSummaryPanelProvider` (StateProvider) 사용
  - Icon: `showMenuSummary ? Icons.list_alt : Icons.grid_view`
  - Tooltip: `l10n.kdsMenuSummaryToggle`
- ✅ **같은 화면 전환**: 
  - `kds_screen.dart:52` → `showMenuSummary ? KdsMenuSummaryScreen() : KdsOrdersGridView()`
  - 동일 화면 내에서 조건부 렌더링

### 검증 결과
- 토글 상태 관리 완료, 아이콘 변경 정상, 화면 전환 로직 구현됨

---

## P2-6: Table Merge (합석)

**Status**: ❌ **컴파일 에러** (구현은 완료되었으나 빌드 실패)

### 파일 존재
- ✅ `lib/features/floor_plan/presentation/modals/table_merge_modal.dart` 존재

### 구현 내용
- ✅ **TableMergeModal 존재**: 
  - 현재 테이블을 제외한 OCCUPIED 테이블 목록 표시
  - 타겟 테이블 선택 → `_confirmMerge()` 확인 다이얼로그
- ✅ **SaleItems 이동 로직**: 
  - `_performMerge()` 메서드에서 타겟 테이블의 SaleItem 전부를 현재 Sale로 복사
  - `db.into(db.saleItems).insert()` 반복 실행
- ✅ **테이블 상태 변경**: 
  - 타겟 Sale status → `'merged'`
  - 타겟 Table status → `'AVAILABLE'`, currentSaleId 제거

### 컴파일 에러
```
❌ table_merge_modal.dart:11 - Final field 'currentSaleIdId' is not initialized
❌ table_merge_modal.dart:13 - 'currentSaleId' isn't a field in the enclosing class (typo)
❌ table_merge_modal.dart:55 - The getter 'zone' isn't defined for RestaurantTable
❌ table_merge_modal.dart:98 - argument_type_not_assignable (_performMerge 중복 선언)
❌ table_detail_modal.dart:206 - extra_positional_arguments (currentSaleId 인자 전달 오류)
```

### 수정 필요 사항
1. `currentSaleIdId` → `currentSaleId` (오타 수정)
2. `this.currentSaleId` 생성자 파라미터 추가
3. `table.zone` → zone 필드가 없으면 제거하거나 nullable 처리
4. `_performMerge()` 중복 선언 제거
5. `table_detail_modal.dart:245` 호출 시 인자 확인

---

## P2-7: KDS 5-Status Filter

**Status**: ✅ **구현 완료** (컴파일 에러는 있으나 필터 자체는 완성)

### 구현 내용
- ✅ **5개 필터 탭**:
  1. All (null)
  2. Pending
  3. Preparing
  4. Ready
  5. **Served** ← 추가됨
  6. **Cancelled** ← 추가됨

- ✅ `filter_tabs.dart`: 
  - FilterChip 6개 (All + 5 statuses)
  - `selectedFilterProvider` (StateProvider) 사용
  - 각 상태별 색상 적용 (`OrderStatus.*.colorHex`)

### 컴파일 에러
```
❌ filter_tabs.dart:59 - ')' 누락 (Ready 탭 뒤에서 괄호 닫기 없음)
```

### 수정 필요
- `filter_tabs.dart:59` 줄에 `)` 추가 (Ready 필터칩 뒤)

---

## Code Cleanup (Lint/Analyze)

**Status**: ❌ **5 errors 검출**

### Flutter Analyze 결과
```
error • extra_positional_arguments (table_detail_modal.dart:206)
error • final_not_initialized_constructor (table_merge_modal.dart:13)
error • initializing_formal_for_non_existent_field (table_merge_modal.dart:16)
error • undefined_getter: zone (table_merge_modal.dart:55)
error • argument_type_not_assignable (table_merge_modal.dart:98)
```

### 분석
- 대부분 `table_merge_modal.dart`와 `table_detail_modal.dart`의 인자 전달 오류
- `filter_tabs.dart`의 괄호 누락은 analyze에서는 미표시, test 실행 시 발견됨

---

## Tests

**Status**: ❌ **FAIL**

### 실행 결과
```
00:07 +516 -2: Some tests failed.
```

### 실패 원인
- 컴파일 에러로 인해 일부 위젯 로드 실패
- `filter_tabs.dart`, `table_merge_modal.dart` 문법 오류

---

## Git

**Latest commit**:  
```
a9fe9b8 feat: Add Split Bill, KDS improvements, and Table Merge
```

**Status**: Clean (nothing to commit)

---

## 종합 평가

### ✅ 구현 완료 (로직상)
1. **Split Bill**: 균등 분할 로직 정상, DB 트랜잭션 완료
2. **KDS View Toggle**: 토글 버튼 및 화면 전환 정상
3. **Table Merge**: 합석 로직 및 Sale 이동 구현 완료
4. **KDS Filter**: 5개 상태 필터 추가 완료

### ❌ 빌드 차단 문제
1. `table_merge_modal.dart`: 
   - 생성자 파라미터 오타 (`currentSaleIdId` → `currentSaleId`)
   - zone 필드 미존재 처리 필요
   - `_performMerge()` 중복 선언
2. `filter_tabs.dart`: 
   - 괄호 누락 (line 59)
3. `table_detail_modal.dart`: 
   - TableMergeModal 호출 시 인자 오류

### 권장 조치
1. **즉시 수정**: 위 5개 컴파일 에러 수정 후 재빌드
2. **테스트 재실행**: `flutter test` 통과 확인
3. **Lint 클린**: `flutter analyze` 0 issues 달성

---

**다음 단계**: Dede에게 컴파일 에러 수정 요청 (#dev-dede)

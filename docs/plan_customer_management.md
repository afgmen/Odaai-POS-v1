# 고객 관리 기능 구현 계획

## 현재 상태
- DB 테이블: `Customers` (sync_queue.dart에 정의됨) — id, name, phone, email, balance, isActive, createdAt
- Sales 테이블: `customerId` nullable 필드 존재 (이미 고객 연동 준비 완료)
- DAO: 고객용 DAO 없음
- UI: 고객 관련 화면 없음
- Provider: 고객 관련 Provider 없음

## 구현 범위

### 1단계: CustomersDao (데이터 접근 계층)
**파일:** `lib/database/daos/customers_dao.dart`
- CRUD: createCustomer, getAllCustomers, getCustomerById, searchCustomers
- 통계: getCustomerPurchaseHistory (Sales join), getTopCustomers
- Stream: watchAllCustomers (실시간 목록 갱신)
- 소프트 삭제: deactivateCustomer (isActive = false)
- 잔액 관리: updateBalance (포인트/적립금 충전/차감)

### 2단계: Customer Provider (상태 관리)
**파일:** `lib/features/customers/providers/customers_provider.dart`
- customersDaoProvider: DAO 인스턴스
- allCustomersProvider: StreamProvider로 전체 고객 목록
- customerSearchProvider: 검색 필터링
- selectedCustomerProvider: POS에서 선택한 고객 (결제 시 연동)

### 3단계: 고객 관리 화면
**파일:** `lib/features/customers/presentation/screens/customer_management_screen.dart`
- 기존 EmployeeManagementScreen 패턴 따라 구현
- 그리드 형태 고객 카드 리스트
- 검색바 (이름/전화번호)
- 고객 추가 버튼 (AppBar actions)
- 카드에 이름, 전화, 이메일, 잔액 표시
- PopupMenu: 수정 / 비활성화 / 구매이력

### 4단계: 고객 폼 모달
**파일:** `lib/features/customers/presentation/widgets/customer_form_modal.dart`
- EmployeeFormModal 패턴 따라 구현
- 필드: 이름(필수), 전화번호, 이메일, 초기 잔액
- 추가/수정 모드 지원
- 유효성 검사: 이름 필수, 전화번호 형식, 이메일 형식

### 5단계: 고객 구매이력 화면
**파일:** `lib/features/customers/presentation/screens/customer_history_screen.dart`
- 특정 고객의 판매 내역 (Sales where customerId = 해당고객)
- 총 구매 금액, 방문 횟수 표시
- 리스트 형태 (날짜, 금액, 결제방법)

### 6단계: POS 결제 연동
- PaymentModal에 고객 선택 기능 추가
- 고객 검색 드롭다운 (이름/전화번호)
- 선택된 고객 정보 결제 시 Sale.customerId에 저장
- 잔액(포인트) 결제 옵션 (선택)

### 7단계: 네비게이션 탭 추가
**파일:** `lib/features/app_root_screen.dart`
- IndexedStack에 CustomerManagementScreen 추가
- NavigationBar에 '고객관리' 탭 추가 (Icons.person_search)

### 8단계: i18n (다국어)
- ARB 파일 3개에 고객 관련 키 추가:
  - navCustomers, customerManagement, customerName, customerPhone,
    customerEmail, customerBalance, addCustomer, editCustomer,
    customerHistory, purchaseHistory, totalPurchases, visitCount,
    noCustomers, selectCustomer, customerPoint
- `flutter gen-l10n` 실행

### 9단계: database_providers.dart 업데이트
- customersDaoProvider 추가
- allCustomersStreamProvider 추가

## 파일 변경 목록

### 새로 생성 (6개)
1. `lib/database/daos/customers_dao.dart`
2. `lib/features/customers/providers/customers_provider.dart`
3. `lib/features/customers/presentation/screens/customer_management_screen.dart`
4. `lib/features/customers/presentation/widgets/customer_form_modal.dart`
5. `lib/features/customers/presentation/screens/customer_history_screen.dart`
6. `lib/features/customers/presentation/widgets/customer_search_modal.dart` (POS용)

### 수정 (6개)
1. `lib/database/app_database.dart` — daos 목록에 CustomersDao 추가
2. `lib/providers/database_providers.dart` — customersDaoProvider 추가
3. `lib/features/app_root_screen.dart` — 탭 추가
4. `lib/features/pos/presentation/widgets/payment_modal.dart` — 고객 선택 추가
5. `lib/l10n/app_ko.arb` — 고객 관련 한국어 키 추가
6. `lib/l10n/app_en.arb` — 고객 관련 영어 키 추가
7. `lib/l10n/app_vi.arb` — 고객 관련 베트남어 키 추가

### 빌드 단계
- `dart run build_runner build --delete-conflicting-outputs` (Drift 코드 생성)
- `flutter gen-l10n` (i18n 코드 생성)
- `flutter run -d chrome` (테스트)

## UI 디자인 규칙 (기존 패턴 따라감)
- 배경: `AppTheme.background`
- 카드: `AppTheme.cardWhite`, borderRadius 12
- 아바타: 원형, 이름 첫글자
- 색상: primary(#2563EB), success(녹색), error(빨강)
- 모달: Dialog, maxWidth 500, padding 24
- 버튼: ElevatedButton (primary), OutlinedButton (cancel)

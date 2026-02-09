// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => '오다 POS';

  @override
  String get ok => '확인';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get edit => '수정';

  @override
  String get add => '추가';

  @override
  String get search => '검색';

  @override
  String get settings => '설정';

  @override
  String get close => '닫기';

  @override
  String get confirm => '확인';

  @override
  String get back => '뒤로';

  @override
  String get error => '오류';

  @override
  String get loading => '로딩 중...';

  @override
  String get noData => '데이터 없음';

  @override
  String get retry => '재시도';

  @override
  String get yes => '예';

  @override
  String get no => '아니오';

  @override
  String get more => '더보기';

  @override
  String get all => '전체';

  @override
  String get today => '오늘';

  @override
  String get yesterday => '어제';

  @override
  String get none => '없음';

  @override
  String get apply => '적용';

  @override
  String get activate => '활성화';

  @override
  String get deactivate => '비활성화';

  @override
  String get navPos => 'POS';

  @override
  String get navProducts => '상품관리';

  @override
  String get navSales => '주문내역';

  @override
  String get navDashboard => '대시보드';

  @override
  String get navInventory => '재고부족';

  @override
  String get navEmployees => '직원관리';

  @override
  String get navPromotions => '프로모션';

  @override
  String get navReports => '리포트';

  @override
  String get navSettings => '설정';

  @override
  String get navCustomers => '고객';

  @override
  String get navTables => '테이블';

  @override
  String get navRefunds => '환불';

  @override
  String get navCashDrawer => '시재';

  @override
  String get cart => '장바구니';

  @override
  String get subtotal => '소계';

  @override
  String get discount => '할인';

  @override
  String get total => '합계';

  @override
  String get checkout => '결제';

  @override
  String get clearCart => '초기화';

  @override
  String get addDiscount => '할인 추가';

  @override
  String get applyPromotion => '프로모션 적용';

  @override
  String get autoPromotionsApplied => '자동 적용된 프로모션';

  @override
  String get cartEmpty => '장바구니가 비어있습니다';

  @override
  String get addProductsPlease => '상품을 추가해주세요';

  @override
  String payAmount(Object amount) {
    return '결제 $amount';
  }

  @override
  String get discountSettings => '할인 설정';

  @override
  String get promotion => '프로모션';

  @override
  String get paymentAmount => '결제금액';

  @override
  String itemCount(Object count) {
    return '$count개';
  }

  @override
  String get appliedProducts => '적용 상품 선택';

  @override
  String get productName => '상품명';

  @override
  String get productPrice => '가격';

  @override
  String get productStock => '재고';

  @override
  String get productCategory => '카테고리';

  @override
  String get addProduct => '상품 추가';

  @override
  String get editProduct => '상품 수정';

  @override
  String get deleteProduct => '상품 삭제';

  @override
  String get productManagement => '상품 관리';

  @override
  String get noProducts => '상품이 없습니다';

  @override
  String get searchProductHint => '상품명, SKU, 바코드 검색...';

  @override
  String addedToCart(Object name) {
    return '$name을(를) 장바구니에 추가했습니다';
  }

  @override
  String outOfStock(Object name) {
    return '$name은(는) 현재 품절 중입니다';
  }

  @override
  String productNotFound(Object input) {
    return '[$input] 상품을 찾을 수 없습니다';
  }

  @override
  String get paymentMethod => '결제 방법';

  @override
  String get cash => '현금';

  @override
  String get card => '카드';

  @override
  String get qr => 'QR';

  @override
  String get transfer => '이체';

  @override
  String get cashReceived => '받은 금액';

  @override
  String get change => '거스름돈';

  @override
  String get paymentComplete => '결제 완료';

  @override
  String get selectPaymentMethod => '결제 방법 선택';

  @override
  String get cashInputAmount => '현금 투입 금액';

  @override
  String get enterAmount => '금액 입력';

  @override
  String get noEmployeeLoggedIn => '로그인한 직원이 없습니다';

  @override
  String get paymentFailed => '결제 실패';

  @override
  String get receiptNumber => '영수증 번호';

  @override
  String get receiptDate => '일시';

  @override
  String get receiptItems => '항목';

  @override
  String get receiptThankYou => '감사합니다!';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsCurrency => '통화';

  @override
  String get settingsExchangeRate => '환율';

  @override
  String get settingsSelectLanguage => '언어 선택';

  @override
  String get settingsSelectCurrency => '통화 선택';

  @override
  String get localeSettings => '언어 및 통화';

  @override
  String get storeInfo => '매장 정보';

  @override
  String get storeName => '매장명';

  @override
  String get storePhone => '전화번호';

  @override
  String get storeAddress => '주소';

  @override
  String get receiptSettings => '영수증 설정';

  @override
  String get footerMessage => '하단 문구';

  @override
  String get footerDefault => '감사합니다!';

  @override
  String get showQrCode => 'QR 코드 표시';

  @override
  String get appInfo => '앱 정보';

  @override
  String get version => '버전';

  @override
  String get database => '데이터베이스';

  @override
  String get syncMode => '동기화 모드';

  @override
  String get offlineFirst => '오프라인 우선';

  @override
  String get logout => '로그아웃';

  @override
  String get logoutConfirm => '로그아웃 하시겠습니까?';

  @override
  String get langKorean => '한국어';

  @override
  String get langEnglish => 'English';

  @override
  String get langVietnamese => 'Tiếng Việt';

  @override
  String get currencyKRW => '원 (₩)';

  @override
  String get currencyUSD => '달러 (\$)';

  @override
  String get currencyVND => '동 (₫)';

  @override
  String get employeeManagement => '직원 관리';

  @override
  String get employeeName => '이름';

  @override
  String get employeeRole => '역할';

  @override
  String get employeeUsername => '사용자명';

  @override
  String get employeePin => 'PIN';

  @override
  String get addEmployee => '직원 추가';

  @override
  String get editEmployee => '직원 수정';

  @override
  String get noEmployees => '등록된 직원이 없습니다';

  @override
  String get employeeLoadError => '직원 목록을 불러올 수 없습니다';

  @override
  String get employeeAdded => '새 직원이 추가되었습니다';

  @override
  String get employeeUpdated => '직원 정보가 수정되었습니다';

  @override
  String get usernameLabel => '사용자명 (로그인 ID)';

  @override
  String get usernameHint => '예: john_doe';

  @override
  String get usernameRequired => '사용자명을 입력하세요';

  @override
  String get usernameMinLength => '사용자명은 3자 이상이어야 합니다';

  @override
  String get nameLabel => '이름';

  @override
  String get nameHint => '예: 홍길동';

  @override
  String get nameRequired => '이름을 입력하세요';

  @override
  String get roleLabel => '역할';

  @override
  String get roleCashier => '캐셔 (Cashier)';

  @override
  String get roleManager => '매니저 (Manager)';

  @override
  String get roleAdmin => '관리자 (Admin)';

  @override
  String get pinChangeLabel => 'PIN 변경 (선택사항)';

  @override
  String get pinNewLabel => 'PIN (4자리 숫자)';

  @override
  String get pinHint => '1234';

  @override
  String get pinNoChangeHelper => '비워두면 PIN이 변경되지 않습니다';

  @override
  String get pinNewHelper => '4자리 숫자를 입력하세요';

  @override
  String get pinRequired => 'PIN을 입력하세요';

  @override
  String get pinLengthError => 'PIN은 4자리여야 합니다';

  @override
  String get pinDigitsOnly => 'PIN은 숫자만 입력 가능합니다';

  @override
  String get promotionManagement => '프로모션 관리';

  @override
  String get promotionName => '프로모션명';

  @override
  String get promotionType => '타입';

  @override
  String get promotionValue => '값';

  @override
  String get addPromotion => '프로모션 추가';

  @override
  String get editPromotion => '프로모션 수정';

  @override
  String get noPromotions => '등록된 프로모션이 없습니다';

  @override
  String get deletePromotion => '프로모션 삭제';

  @override
  String deletePromotionConfirm(Object name) {
    return '정말로 \"$name\" 프로모션을 삭제하시겠습니까?';
  }

  @override
  String get promotionNameLabel => '프로모션 이름';

  @override
  String get promotionNameHint => '예: 오렌지주스 1+1';

  @override
  String get promotionNameRequired => '프로모션 이름을 입력하세요';

  @override
  String get promotionTypeLabel => '프로모션 타입';

  @override
  String get typeBogo => '1+1 이벤트 (1개 사면 1개 무료)';

  @override
  String get typeBuy2Get1 => '2+1 이벤트 (2개 사면 1개 무료)';

  @override
  String get typePercentOff => '퍼센트 할인';

  @override
  String get typeAmountOff => '금액 할인';

  @override
  String get discountRateLabel => '할인율 (%)';

  @override
  String get discountAmountLabel => '할인 금액 (원)';

  @override
  String get discountValueHint => '예: 10';

  @override
  String get discountAmountHint => '예: 1000';

  @override
  String get discountValueRequired => '할인 값을 입력하세요';

  @override
  String get invalidNumber => '올바른 숫자를 입력하세요';

  @override
  String get maxDiscountRate => '할인율은 100% 이하여야 합니다';

  @override
  String get startDate => '시작일';

  @override
  String get endDate => '종료일';

  @override
  String get targetProduct => '적용 상품 (선택사항)';

  @override
  String get allProducts => '전체 상품';

  @override
  String get productLoadFailed => '상품 로드 실패';

  @override
  String get noSelection => '선택 안 함';

  @override
  String get bogoLabel => '1+1 이벤트';

  @override
  String get buy2Get1Label => '2+1 이벤트';

  @override
  String get percentOffLabel => '퍼센트 할인';

  @override
  String get amountOffLabel => '금액 할인';

  @override
  String get freeOne => '1개 무료';

  @override
  String get dashboard => '대시보드';

  @override
  String get todaySales => '오늘 매출';

  @override
  String get totalRevenue => '총 수익';

  @override
  String get topProducts => '인기 상품';

  @override
  String get salesDashboard => '매출 대시보드';

  @override
  String get paymentMethodSales => '결제 방법별 매출';

  @override
  String get productRanking => '상품별 매출 순위';

  @override
  String get totalSalesAmount => '매출 합계';

  @override
  String get orderCount => '주문 수';

  @override
  String get orderUnit => '건';

  @override
  String get avgOrderAmount => '평균 주문금액';

  @override
  String get inventoryValue => '재고 가치';

  @override
  String get inventoryValueDesc => '현재 보유 재고 총 가치';

  @override
  String get noSalesData => '판매 데이터 없음';

  @override
  String soldCount(Object count) {
    return '$count개 판매';
  }

  @override
  String get errorOccurred => '오류 발생';

  @override
  String get salesHistory => '주문내역';

  @override
  String get noSalesHistory => '주문 기록이 없습니다';

  @override
  String totalAmount(Object amount) {
    return '합계 $amount';
  }

  @override
  String get refunded => '환불';

  @override
  String dateMonth(Object day, Object month) {
    return '$month월 $day일';
  }

  @override
  String get lowStockAlert => '재고 부족 알림';

  @override
  String get allStockSufficient => '모든 상품의 재고가 충분합니다';

  @override
  String get aboveMinStock => '최소 재고 이상으로 유지되고 있습니다';

  @override
  String addStockTitle(Object name) {
    return '재고 추가: $name';
  }

  @override
  String currentStock(Object current, Object min) {
    return '현재 재고: $current / 최소 재고: $min';
  }

  @override
  String get addStock => '재고 추가';

  @override
  String get stockReplenishReason => '재고 보충 (부족 알림)';

  @override
  String stockAddedMsg(Object name, Object qty) {
    return '$name 재고 $qty개 추가 완료';
  }

  @override
  String get outOfStockLabel => '재고 없음';

  @override
  String get lowStockLabel => '부족';

  @override
  String get currentStockLabel => '현재 재고';

  @override
  String get minStockLabel => '최소 재고';

  @override
  String get needReplenish => '필요 보충';

  @override
  String get salesReport => '매출 리포트';

  @override
  String get exportExcel => '엑셀 내보내기';

  @override
  String excelSaved(Object path) {
    return '엑셀 파일 저장됨: $path';
  }

  @override
  String exportFailed(Object error) {
    return '내보내기 실패: $error';
  }

  @override
  String get customerManagement => '고객 관리';

  @override
  String get addCustomer => '고객 추가';

  @override
  String get editCustomer => '고객 수정';

  @override
  String get searchCustomerHint => '이름, 전화번호, 이메일 검색...';

  @override
  String get noCustomers => '등록된 고객이 없습니다';

  @override
  String get noSearchResult => '검색 결과가 없습니다';

  @override
  String get points => '포인트';

  @override
  String get earnPoints => '적립';

  @override
  String get usePoints => '사용';

  @override
  String get purchaseHistory => '구매 이력';

  @override
  String get noPurchaseHistory => '구매 이력이 없습니다';

  @override
  String get earnPointsTitle => '포인트 적립';

  @override
  String get usePointsTitle => '포인트 사용';

  @override
  String get pointsLabel => '포인트';

  @override
  String get earnPointsHint => '적립할 포인트';

  @override
  String usePointsHint(Object points) {
    return '사용할 포인트 (보유: ${points}P)';
  }

  @override
  String get customerNameLabel => '이름 *';

  @override
  String get customerPhoneLabel => '전화번호';

  @override
  String get customerEmailLabel => '이메일';

  @override
  String get customerNoteLabel => '메모';

  @override
  String get tableManagement => '테이블 관리';

  @override
  String get addTable => '테이블 추가';

  @override
  String get noTables => '테이블을 추가해주세요';

  @override
  String get noTablesFiltered => '해당 상태의 테이블이 없습니다';

  @override
  String get tableAvailable => '비어있음';

  @override
  String get tableOccupied => '사용중';

  @override
  String get tableReserved => '예약';

  @override
  String get tableNameLabel => '테이블 이름 *';

  @override
  String get tableNameHint => '예: 테이블 1, A-1';

  @override
  String get seatsLabel => '좌석 수';

  @override
  String get zoneLabel => '구역';

  @override
  String get zoneHint => '예: 홀, 테라스, 룸';

  @override
  String get startUse => '사용 시작';

  @override
  String get reserve => '예약';

  @override
  String get clearTable => '비우기 (사용 완료)';

  @override
  String get moveTable => '테이블 이동';

  @override
  String get reserveToUse => '예약 → 사용 시작';

  @override
  String get clearTableShort => '비우기';

  @override
  String moveTableTitle(Object name) {
    return '$name → 이동';
  }

  @override
  String get noEmptyTables => '이동 가능한 빈 테이블이 없습니다.';

  @override
  String seatsUnit(Object count) {
    return '$count석';
  }

  @override
  String get refundManagement => '환불/반품';

  @override
  String get searchByReceipt => '영수증 번호로 검색';

  @override
  String get receiptNumberHint => '영수증 번호 입력 (예: ODA-20250207-001)';

  @override
  String get refundedStatus => '환불됨';

  @override
  String get paidStatus => '결제완료';

  @override
  String get selectRefundItems => '환불 항목 선택';

  @override
  String get refundReasonLabel => '환불 사유';

  @override
  String get refundReasonHint => '환불 사유를 입력하세요';

  @override
  String partialRefund(Object amount) {
    return '부분 환불 ($amount)';
  }

  @override
  String get fullRefund => '전체 환불';

  @override
  String get alreadyRefunded => '이미 환불 처리된 주문입니다.';

  @override
  String get todayRefundHistory => '오늘 환불 내역';

  @override
  String get noRefundToday => '오늘 환불 내역이 없습니다';

  @override
  String get fullRefundType => '전체';

  @override
  String get partialRefundType => '부분';

  @override
  String get receiptNotFound => '해당 영수증을 찾을 수 없습니다';

  @override
  String get fullRefundComplete => '전체 환불이 완료되었습니다';

  @override
  String get partialRefundComplete => '부분 환불이 완료되었습니다';

  @override
  String refundConfirm(Object amount) {
    return '$amount 환불을 진행하시겠습니까?';
  }

  @override
  String get refundAction => '환불';

  @override
  String get cashDrawerManagement => '시재 관리';

  @override
  String get currentCashDrawer => '현재 시재';

  @override
  String get openStatus => '영업중';

  @override
  String get closedStatus => '미개점';

  @override
  String get openDrawer => '개점';

  @override
  String get closeDrawer => '마감';

  @override
  String get deposit => '입금';

  @override
  String get withdraw => '출금';

  @override
  String get sale => '매출';

  @override
  String get todayTransactions => '오늘 거래 내역';

  @override
  String get noTransactionsToday => '오늘 거래 내역이 없습니다';

  @override
  String balance(Object amount) {
    return '잔액 $amount';
  }

  @override
  String get cashDrawerOpen => '개점';

  @override
  String get cashDrawerClose => '마감';

  @override
  String get cashDrawerDeposit => '입금';

  @override
  String get cashDrawerWithdraw => '출금';

  @override
  String get cashDrawerSale => '판매';

  @override
  String get cashDrawerRefund => '환불';

  @override
  String get amountLabel => '금액';

  @override
  String get memoLabel => '메모 (선택)';

  @override
  String get closeSettlement => '마감 정산';

  @override
  String systemBalance(Object amount) {
    return '시스템 잔액: $amount';
  }

  @override
  String get actualCashAmount => '실제 시재 금액';

  @override
  String get countCashHint => '시재를 세고 금액을 입력하세요';

  @override
  String get normalClose => '정상 마감';

  @override
  String difference(Object amount) {
    return '차이: $amount';
  }

  @override
  String closeComplete(Object note) {
    return '마감 완료. $note';
  }

  @override
  String get syncStatus => '동기화 상태';

  @override
  String get network => '네트워크';

  @override
  String get connected => '연결됨';

  @override
  String get offline => '오프라인';

  @override
  String get pendingItems => '대기 중 항목';

  @override
  String pendingCount(Object count) {
    return '$count개';
  }

  @override
  String get lastSync => '마지막 동기화';

  @override
  String get notYet => '아직 없음';

  @override
  String get syncing => '동기화 중...';

  @override
  String get syncNow => '지금 동기화';

  @override
  String get syncAutoMsg => '인터넷 연결 시 자동으로 5분마다 동기화됩니다';

  @override
  String get syncOfflineMsg =>
      '오프라인 상태에서도 모든 기능을 사용할 수 있습니다.\n인터넷 연결 시 자동으로 동기화됩니다.';

  @override
  String get justNow => '방금 전';

  @override
  String minutesAgo(Object min) {
    return '$min분 전';
  }

  @override
  String hoursAgo(Object hours) {
    return '$hours시간 전';
  }

  @override
  String get offlineIndicator => '오프라인';

  @override
  String get pinLoginTitle => 'PIN을 입력하여 로그인하세요';

  @override
  String get pinMismatch => 'PIN이 일치하지 않습니다';

  @override
  String loginError(Object error) {
    return '로그인 오류: $error';
  }

  @override
  String get msgItemAdded => '장바구니에 추가되었습니다';

  @override
  String get msgPaymentSuccess => '결제가 완료되었습니다';

  @override
  String get msgPaymentFailed => '결제에 실패했습니다';

  @override
  String get msgInsufficientStock => '재고가 부족합니다';

  @override
  String get msgInvalidAmount => '잘못된 금액입니다';

  @override
  String get msgSaved => '저장되었습니다';

  @override
  String get msgDeleted => '삭제되었습니다';

  @override
  String msgError(Object error) {
    return '오류가 발생했습니다: $error';
  }

  @override
  String get quantity => '수량';

  @override
  String get price => '가격';

  @override
  String get amount => '금액';

  @override
  String get description => '설명';

  @override
  String get active => '활성';

  @override
  String get inactive => '비활성';

  @override
  String get status => '상태';

  @override
  String get cashPayment => '현금';

  @override
  String get cardPayment => '카드';

  @override
  String get qrPayment => 'QR';

  @override
  String get transferPayment => '이체';

  @override
  String get salesLabel => '매출';

  @override
  String get refundLabel => '환불';

  @override
  String get excelManage => '엑셀 관리';

  @override
  String get excelDownload => '엑셀로 다운로드';

  @override
  String get excelDownloadDesc => '현재 상품 목록 내보내기';

  @override
  String get excelUpload => '엑셀에서 업로드';

  @override
  String get excelUploadDesc => '.xlsx 파일로 상품 추가/수정';

  @override
  String get excelExporting => '엑셀 파일 생성 중...';

  @override
  String get excelSaveComplete => '엑셀 파일 저장 완료!';

  @override
  String get excelSaveFailed => '저장 취소 또는 실패. 다시 시도하세요.';

  @override
  String get excelFileSave => '엑셀 파일 저장';

  @override
  String get excelFileSelect => '엑셀 파일 선택';

  @override
  String get uploadComplete => '업로드 완료';

  @override
  String get newProductAdded => '새 상품 추가';

  @override
  String get existingProductUpdated => '기존 상품 수정';

  @override
  String get totalProcessed => '총 처리 건수';

  @override
  String countUnit(Object count) {
    return '$count건';
  }

  @override
  String errorsOccurred(Object count) {
    return '⚠️ $count건 오류 발생';
  }

  @override
  String productDeleted(Object name) {
    return '\'$name\'이(가) 삭제되었습니다';
  }

  @override
  String errorPrefix(Object error) {
    return '오류: $error';
  }

  @override
  String get noProductsFound => '상품이 없습니다';

  @override
  String get sku => 'SKU';

  @override
  String get category => '카테고리';

  @override
  String get sellingPrice => '판매가';

  @override
  String get costPrice => '원가';

  @override
  String get stock => '재고';

  @override
  String get minStock => '최소재고';

  @override
  String get action => '액션';

  @override
  String get statusOutOfStock => '품절';

  @override
  String get statusLow => '잔재고';

  @override
  String get statusNormal => '정상';

  @override
  String piecesUnit(Object count) {
    return '$count개';
  }

  @override
  String get stockAdjust => '재고 조정';

  @override
  String get basicInfo => '기본정보';

  @override
  String get productNameRequired => '상품명 *';

  @override
  String get priceInfo => '가격정보';

  @override
  String get sellingPriceRequired => '판매가 *';

  @override
  String get stockInfo => '재고정보';

  @override
  String get stockQuantity => '재고수량';

  @override
  String get categoryHint => '식품, 음료, 전자제품 등';

  @override
  String get productUpdated => '상품이 수정되었습니다';

  @override
  String get productAdded => '상품이 추가되었습니다';

  @override
  String get deleteProductTitle => '상품 삭제';

  @override
  String deleteProductConfirm(Object name) {
    return '\'$name\'을(를) 삭제하겠습니까?\n삭제된 상품은 복원할 수 없습니다.';
  }

  @override
  String get receipt => '영수증';

  @override
  String get print => '인쇄';

  @override
  String get orderNumber => '주문번호';

  @override
  String get unitPrice => '단가';

  @override
  String get cashPaidAmount => '투입금액';

  @override
  String get thankYouMessage => '이용해 주셔서 감사합니다!';

  @override
  String get newOrder => '새 주문';

  @override
  String get receiptPrint => '영수증 인쇄';

  @override
  String get paperFormat => '용지 형식';

  @override
  String get receiptFormat => '영수증 (80mm)';

  @override
  String get thermalPrinter => '열감지 프린터용';

  @override
  String get a4Format => 'A4';

  @override
  String get regularPrinter => '일반 프린터용';

  @override
  String get preview => '미리보기';

  @override
  String get printing => '인쇄 중...';

  @override
  String get receiptPreview => '영수증 미리보기';

  @override
  String receiptFileName(Object saleNumber) {
    return '영수증_$saleNumber.pdf';
  }

  @override
  String printError(Object error) {
    return '인쇄 오류: $error';
  }

  @override
  String get stockAdjustment => '재고 조정';

  @override
  String get currentStockAmount => '현재 재고';

  @override
  String get adjustmentType => '조정 유형';

  @override
  String get stockIn => '+ 입고';

  @override
  String get stockOut => '- 출고';

  @override
  String get adjustmentQuantity => '조정 수량';

  @override
  String get enterQuantity => '수량 입력';

  @override
  String get reasonOptional => '사유 (선택)';

  @override
  String get reasonHint => '예: 신규 입고, 손실 등';

  @override
  String get stockAfterAdjust => '조정 후 재고';

  @override
  String get adjustComplete => '조정 완료';

  @override
  String stockAdjusted(Object change) {
    return '재고가 조정되었습니다 ($change개)';
  }

  @override
  String get barcodeSkuInput => '바코드 / SKU 입력';

  @override
  String get barcodeOrSku => '바코드 또는 SKU';

  @override
  String get lookup => '조회';

  @override
  String get continuousScanMode => '연속 스캔 모드';

  @override
  String get autoResetAfterInput => '— 입력 후 자동 초기화';

  @override
  String get barcodeScannerHelp => 'USB 바코드 스캔기 연결 시 스캔 후 자동으로 조회됩니다.';

  @override
  String addedToCartMsg(Object name) {
    return '✓  $name — 장바구니에 추가';
  }

  @override
  String outOfStockMsg(Object name) {
    return '✗  $name — 현재 품절 중';
  }

  @override
  String productNotFoundMsg(Object input) {
    return '✗  [$input] 상품을 찾을 수 없습니다';
  }

  @override
  String get excelSheetProductList => '상품목록';

  @override
  String get excelHeaderProductName => '상품명';

  @override
  String get excelHeaderBarcode => '바코드';

  @override
  String get excelHeaderCategory => '카테고리';

  @override
  String get excelHeaderSellingPrice => '판매가';

  @override
  String get excelHeaderCostPrice => '원가';

  @override
  String get excelHeaderStock => '재고';

  @override
  String get excelHeaderMinStock => '최소재고';

  @override
  String excelRowNameEmpty(Object row) {
    return '행 $row: 상품명이 비어있습니다';
  }

  @override
  String excelRowPriceError(Object row) {
    return '행 $row: 판매가는 0 이상이어야 합니다';
  }

  @override
  String excelRowCostError(Object row) {
    return '행 $row: 원가는 0 이상이어야 합니다';
  }

  @override
  String excelRowStockError(Object row) {
    return '행 $row: 재고는 0 이상이어야 합니다';
  }

  @override
  String excelRowError(Object error, Object row) {
    return '행 $row: $error';
  }

  @override
  String insufficientStockError(Object stock) {
    return '재고가 부족합니다. 현재 재고: $stock';
  }

  @override
  String get saleReason => '판매';

  @override
  String get refundStockRestore => '환불 재고 복구';

  @override
  String get partialRefundStockRestore => '부분 환불 재고 복구';

  @override
  String get reportSheetSummary => '요약';

  @override
  String get reportTitle => 'Oda POS 매출 리포트';

  @override
  String reportPeriod(Object from, Object to) {
    return '기간: $from ~ $to';
  }

  @override
  String get reportItem => '항목';

  @override
  String get reportValue => '값';

  @override
  String get reportTotalSales => '총 매출';

  @override
  String get reportOrderCount => '주문 수';

  @override
  String get reportAvgOrder => '평균 주문금액';

  @override
  String get reportGrowthRate => '성장률 (%)';

  @override
  String get reportSheetDaily => '일별 매출';

  @override
  String get reportDate => '날짜';

  @override
  String get reportSales => '매출';

  @override
  String get reportSheetPayment => '결제 방법별';

  @override
  String get reportSheetProduct => '상품별 매출';

  @override
  String get reportRank => '순위';

  @override
  String get reportQuantitySold => '판매 수량';

  @override
  String get employeeInfoEdit => '직원 정보를 수정합니다. PIN을 변경하려면 새로운 4자리 숫자를 입력하세요.';

  @override
  String get employeeInfoNew => '새 직원이 생성됩니다. PIN을 사용하여 로그인할 수 있습니다.';

  @override
  String get barcode => '바코드';

  @override
  String get categoryAll => '전체';

  @override
  String get categoryFood => '식품';

  @override
  String get categoryBeverage => '음료';

  @override
  String get categoryElectronics => '전자제품';

  @override
  String get categoryDaily => '일용품';

  @override
  String get kdsTitle => '주방 디스플레이 시스템';

  @override
  String get kdsCompleted => '완료';

  @override
  String get kdsInProgress => '진행중';

  @override
  String get kdsAverage => '평균';

  @override
  String kdsMinutes(Object count, Object seconds) {
    return '$count분 $seconds초';
  }

  @override
  String kdsOrdersCount(Object count) {
    return '$count건';
  }

  @override
  String get kdsStatusPending => '대기';

  @override
  String get kdsStatusPreparing => '조리중';

  @override
  String get kdsStatusReady => '완료';

  @override
  String get kdsStatusServed => '서빙완료';

  @override
  String get kdsStatusCancelled => '취소';

  @override
  String get kdsPriorityNormal => '일반';

  @override
  String get kdsPriorityUrgent => '긴급';

  @override
  String get kdsFilterAll => '전체';

  @override
  String get kdsFilterPending => '대기';

  @override
  String get kdsFilterPreparing => '조리중';

  @override
  String get kdsFilterReady => '완료';

  @override
  String get kdsNoOrders => '주문이 없습니다';

  @override
  String kdsErrorOccurred(Object error) {
    return '오류 발생: $error';
  }

  @override
  String kdsTakeout(Object id) {
    return '포장 #$id';
  }

  @override
  String get kdsOrderTime => '주문 시간';

  @override
  String get kdsStatus => '상태';

  @override
  String get kdsPriority => '우선순위';

  @override
  String get kdsSpecialRequest => '특별 요청';

  @override
  String get kdsProcessingHistory => '처리 내역';

  @override
  String get kdsCancelOrder => '취소';

  @override
  String get kdsCancelOrderConfirm => '주문을 취소하시겠습니까?';

  @override
  String get kdsOrderReceived => '주문 접수';

  @override
  String get kdsPreparationStarted => '조리 시작';

  @override
  String get kdsPreparationComplete => '조리 완료';

  @override
  String get kdsServingComplete => '서빙 완료';

  @override
  String get kdsOrderCancelled => '취소됨';

  @override
  String get kdsStartPreparation => '조리 시작';

  @override
  String get kdsMarkAsReady => '조리 완료';

  @override
  String get kdsMarkAsServed => '서빙 완료';

  @override
  String kdsElapsedMinutes(Object minutes) {
    return '$minutes 분 경과';
  }

  @override
  String get kdsTableNumber => '테이블 번호';

  @override
  String get kdsSpecialInstructions => '특별 지시사항';
}

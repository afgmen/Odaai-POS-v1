// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Oda POS';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Hủy';

  @override
  String get save => 'Lưu';

  @override
  String get delete => 'Xóa';

  @override
  String get edit => 'Sửa';

  @override
  String get add => 'Thêm';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get settings => 'Cài đặt';

  @override
  String get close => 'Đóng';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get back => 'Quay lại';

  @override
  String get error => 'Lỗi';

  @override
  String get loading => 'Đang tải...';

  @override
  String get noData => 'Không có dữ liệu';

  @override
  String get retry => 'Thử lại';

  @override
  String get yes => 'Có';

  @override
  String get no => 'Không';

  @override
  String get more => 'Thêm';

  @override
  String get all => 'Tất cả';

  @override
  String get today => 'Hôm nay';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get week => 'Tuần';

  @override
  String get month => 'Tháng';

  @override
  String get customPeriod => 'Tùy chọn';

  @override
  String get none => 'Không có';

  @override
  String get apply => 'Áp dụng';

  @override
  String get activate => 'Kích hoạt';

  @override
  String get deactivate => 'Vô hiệu hóa';

  @override
  String get navPos => 'POS';

  @override
  String get navProducts => 'Sản phẩm';

  @override
  String get navSales => 'Bán hàng';

  @override
  String get navDashboard => 'Bảng điều khiển';

  @override
  String get navInventory => 'Tồn kho thấp';

  @override
  String get navEmployees => 'Nhân viên';

  @override
  String get navPromotions => 'Khuyến mãi';

  @override
  String get navReports => 'Báo cáo';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get navCustomers => 'Khách hàng';

  @override
  String get navTables => 'Bàn';

  @override
  String get navRefunds => 'Hoàn tiền';

  @override
  String get navCashDrawer => 'Quỹ';

  @override
  String get navKds => 'Bếp';

  @override
  String get navDailyClosing => 'Chốt ca';

  @override
  String get cart => 'Giỏ hàng';

  @override
  String get subtotal => 'Tạm tính';

  @override
  String get discount => 'Giảm giá';

  @override
  String get total => 'Tổng cộng';

  @override
  String get checkout => 'Thanh toán';

  @override
  String get clearCart => 'Xóa';

  @override
  String get addDiscount => 'Thêm giảm giá';

  @override
  String get applyPromotion => 'Áp dụng khuyến mãi';

  @override
  String get autoPromotionsApplied => 'Khuyến mãi tự động';

  @override
  String get cartEmpty => 'Giỏ hàng trống';

  @override
  String get addProductsPlease => 'Vui lòng thêm sản phẩm';

  @override
  String payAmount(Object amount) {
    return 'Thanh toán $amount';
  }

  @override
  String get discountSettings => 'Cài đặt giảm giá';

  @override
  String get promotion => 'Khuyến mãi';

  @override
  String get paymentAmount => 'Số tiền thanh toán';

  @override
  String itemCount(Object count) {
    return '$count món';
  }

  @override
  String get appliedProducts => 'Chọn sản phẩm';

  @override
  String get productName => 'Tên sản phẩm';

  @override
  String get productPrice => 'Giá';

  @override
  String get productStock => 'Tồn kho';

  @override
  String get productCategory => 'Danh mục';

  @override
  String get addProduct => 'Thêm sản phẩm';

  @override
  String get editProduct => 'Sửa sản phẩm';

  @override
  String get deleteProduct => 'Xóa sản phẩm';

  @override
  String get productManagement => 'Quản lý sản phẩm';

  @override
  String get noProducts => 'Không có sản phẩm';

  @override
  String get searchProductHint => 'Tìm theo tên, SKU, mã vạch...';

  @override
  String addedToCart(Object name) {
    return 'Đã thêm $name vào giỏ hàng';
  }

  @override
  String outOfStock(Object name) {
    return '$name đã hết hàng';
  }

  @override
  String get outOfStockBadge => 'Hết hàng';

  @override
  String get lowStockBadge => 'Sắp hết';

  @override
  String productNotFound(Object input) {
    return '[$input] Không tìm thấy sản phẩm';
  }

  @override
  String get paymentMethod => 'Phương thức thanh toán';

  @override
  String get cash => 'Tiền mặt';

  @override
  String get card => 'Thẻ';

  @override
  String get qr => 'Mã QR';

  @override
  String get transfer => 'Chuyển khoản';

  @override
  String get cashReceived => 'Tiền nhận';

  @override
  String get change => 'Tiền thừa';

  @override
  String get paymentComplete => 'Thanh toán thành công';

  @override
  String get selectPaymentMethod => 'Chọn phương thức thanh toán';

  @override
  String get cashInputAmount => 'Số tiền mặt';

  @override
  String get enterAmount => 'Nhập số tiền';

  @override
  String get noEmployeeLoggedIn => 'Chưa đăng nhập nhân viên';

  @override
  String get paymentFailed => 'Thanh toán thất bại';

  @override
  String get receiptNumber => 'Số hóa đơn';

  @override
  String get receiptDate => 'Ngày';

  @override
  String get receiptItems => 'Mặt hàng';

  @override
  String get receiptThankYou => 'Cảm ơn quý khách!';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsCurrency => 'Tiền tệ';

  @override
  String get settingsExchangeRate => 'Tỷ giá';

  @override
  String get settingsSelectLanguage => 'Chọn ngôn ngữ';

  @override
  String get settingsSelectCurrency => 'Chọn tiền tệ';

  @override
  String get localeSettings => 'Ngôn ngữ & Tiền tệ';

  @override
  String get storeInfo => 'Thông tin cửa hàng';

  @override
  String get storeName => 'Tên cửa hàng';

  @override
  String get storePhone => 'Số điện thoại';

  @override
  String get storeAddress => 'Địa chỉ';

  @override
  String get receiptSettings => 'Cài đặt hóa đơn';

  @override
  String get footerMessage => 'Tin nhắn cuối';

  @override
  String get footerDefault => 'Cảm ơn!';

  @override
  String get showQrCode => 'Hiển thị mã QR';

  @override
  String get appInfo => 'Thông tin ứng dụng';

  @override
  String get version => 'Phiên bản';

  @override
  String get database => 'Cơ sở dữ liệu';

  @override
  String get syncMode => 'Chế độ đồng bộ';

  @override
  String get offlineFirst => 'Ngoại tuyến';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get logoutConfirm => 'Bạn có chắc muốn đăng xuất?';

  @override
  String get langKorean => '한국어';

  @override
  String get langEnglish => 'English';

  @override
  String get langVietnamese => 'Tiếng Việt';

  @override
  String get currencyUSD => 'Đô la Mỹ (\$)';

  @override
  String get currencyVND => 'Đồng Việt Nam (₫)';

  @override
  String get employeeManagement => 'Quản lý nhân viên';

  @override
  String get employeeLogin => 'Đăng nhập nhân viên';

  @override
  String get selectEmployee => 'Chọn nhân viên';

  @override
  String get enterPinCode => 'Nhập mã PIN';

  @override
  String get noEmployeesRegistered => 'Chưa có nhân viên đăng ký';

  @override
  String get forgotPin => 'Quên mã PIN? Liên hệ quản lý';

  @override
  String get loginButton => 'Đăng nhập';

  @override
  String loginFailed(String error) {
    return 'Đăng nhập thất bại: $error';
  }

  @override
  String get employeeName => 'Tên';

  @override
  String get employeeRole => 'Vai trò';

  @override
  String get employeeUsername => 'Tên người dùng';

  @override
  String get employeePin => 'Mã PIN';

  @override
  String get addEmployee => 'Thêm nhân viên';

  @override
  String get editEmployee => 'Sửa nhân viên';

  @override
  String get noEmployees => 'Không tìm thấy nhân viên';

  @override
  String get employeeLoadError => 'Không thể tải danh sách nhân viên';

  @override
  String get employeeAdded => 'Đã thêm nhân viên mới';

  @override
  String get employeeUpdated => 'Đã cập nhật thông tin nhân viên';

  @override
  String get usernameLabel => 'Tên người dùng (ID đăng nhập)';

  @override
  String get usernameHint => 'VD: john_doe';

  @override
  String get usernameRequired => 'Vui lòng nhập tên người dùng';

  @override
  String get usernameMinLength => 'Tên người dùng phải có ít nhất 3 ký tự';

  @override
  String get nameLabel => 'Tên';

  @override
  String get nameHint => 'VD: Nguyễn Văn A';

  @override
  String get nameRequired => 'Vui lòng nhập tên';

  @override
  String get roleLabel => 'Vai trò';

  @override
  String get roleCashier => 'Thu ngân';

  @override
  String get roleManager => 'Quản lý';

  @override
  String get roleAdmin => 'Quản trị viên';

  @override
  String get roleKitchen => 'Nhà bếp';

  @override
  String get pinChangeLabel => 'Đổi PIN (tùy chọn)';

  @override
  String get pinNewLabel => 'PIN (4 chữ số)';

  @override
  String get pinHint => '1234';

  @override
  String get pinNoChangeHelper => 'Bỏ trống để giữ PIN hiện tại';

  @override
  String get pinNewHelper => 'Nhập 4 chữ số';

  @override
  String get pinRequired => 'Vui lòng nhập PIN';

  @override
  String get pinLengthError => 'PIN phải có 4 chữ số';

  @override
  String get pinDigitsOnly => 'PIN chỉ được chứa số';

  @override
  String get promotionManagement => 'Quản lý khuyến mãi';

  @override
  String get promotionName => 'Tên khuyến mãi';

  @override
  String get promotionType => 'Loại';

  @override
  String get promotionValue => 'Giá trị';

  @override
  String get addPromotion => 'Thêm khuyến mãi';

  @override
  String get editPromotion => 'Sửa khuyến mãi';

  @override
  String get noPromotions => 'Không có khuyến mãi';

  @override
  String get deletePromotion => 'Xóa khuyến mãi';

  @override
  String deletePromotionConfirm(Object name) {
    return 'Bạn có chắc muốn xóa \"$name\"?';
  }

  @override
  String get promotionNameLabel => 'Tên khuyến mãi';

  @override
  String get promotionNameHint => 'VD: Nước cam mua 1 tặng 1';

  @override
  String get promotionNameRequired => 'Vui lòng nhập tên khuyến mãi';

  @override
  String get promotionTypeLabel => 'Loại khuyến mãi';

  @override
  String get typeBogo => 'Mua 1 tặng 1';

  @override
  String get typeBuy2Get1 => 'Mua 2 tặng 1';

  @override
  String get typePercentOff => 'Giảm phần trăm';

  @override
  String get typeAmountOff => 'Giảm số tiền';

  @override
  String get discountRateLabel => 'Tỷ lệ giảm (%)';

  @override
  String get discountAmountLabel => 'Số tiền giảm';

  @override
  String get discountValueHint => 'VD: 10';

  @override
  String get discountAmountHint => 'VD: 1000';

  @override
  String get discountValueRequired => 'Vui lòng nhập giá trị giảm giá';

  @override
  String get invalidNumber => 'Vui lòng nhập số hợp lệ';

  @override
  String get maxDiscountRate => 'Tỷ lệ giảm không quá 100%';

  @override
  String get startDate => 'Ngày bắt đầu';

  @override
  String get endDate => 'Ngày kết thúc';

  @override
  String get targetProduct => 'Sản phẩm áp dụng (tùy chọn)';

  @override
  String get allProducts => 'Tất cả sản phẩm';

  @override
  String get productLoadFailed => 'Không thể tải sản phẩm';

  @override
  String get noSelection => 'Không chọn';

  @override
  String get bogoLabel => 'Mua 1 tặng 1';

  @override
  String get buy2Get1Label => 'Mua 2 tặng 1';

  @override
  String get percentOffLabel => 'Giảm %';

  @override
  String get amountOffLabel => 'Giảm tiền';

  @override
  String get freeOne => '1 miễn phí';

  @override
  String get dashboard => 'Bảng điều khiển';

  @override
  String get todaySales => 'Doanh thu hôm nay';

  @override
  String get totalRevenue => 'Tổng doanh thu';

  @override
  String get topProducts => 'Sản phẩm hàng đầu';

  @override
  String get salesDashboard => 'Bảng điều khiển bán hàng';

  @override
  String get paymentMethodSales => 'Doanh thu theo phương thức';

  @override
  String get productRanking => 'Xếp hạng sản phẩm';

  @override
  String get totalSalesAmount => 'Tổng doanh thu';

  @override
  String get totalSales => 'Tổng doanh thu';

  @override
  String get orderCount => 'Đơn hàng';

  @override
  String get orderUnit => 'đơn';

  @override
  String get avgOrderAmount => 'Giá trị TB/đơn';

  @override
  String get inventoryValue => 'Giá trị tồn kho';

  @override
  String get inventoryValueDesc => 'Tổng giá trị hàng tồn kho hiện tại';

  @override
  String get noSalesData => 'Không có dữ liệu bán hàng';

  @override
  String soldCount(Object count) {
    return 'Đã bán $count';
  }

  @override
  String errorOccurred(String error) {
    return 'Lỗi xảy ra: $error';
  }

  @override
  String get salesHistory => 'Lịch sử bán hàng';

  @override
  String get noSalesHistory => 'Không có lịch sử bán hàng';

  @override
  String totalAmount(Object amount) {
    return 'Tổng $amount';
  }

  @override
  String get refunded => 'Đã hoàn tiền';

  @override
  String dateMonth(Object day, Object month) {
    return '$day/$month';
  }

  @override
  String get lowStockAlert => 'Cảnh báo tồn kho thấp';

  @override
  String get allStockSufficient => 'Tất cả sản phẩm đủ hàng';

  @override
  String get aboveMinStock => 'Tồn kho trên mức tối thiểu';

  @override
  String addStockTitle(Object name) {
    return 'Thêm hàng: $name';
  }

  @override
  String currentStock(Object current, Object min) {
    return 'Hiện tại: $current / Tối thiểu: $min';
  }

  @override
  String get addStock => 'Thêm hàng';

  @override
  String get stockReplenishReason => 'Bổ sung hàng (cảnh báo tồn kho)';

  @override
  String stockAddedMsg(Object name, Object qty) {
    return 'Đã thêm $qty đơn vị $name';
  }

  @override
  String get outOfStockLabel => 'Hết hàng';

  @override
  String get lowStockLabel => 'Thấp';

  @override
  String get currentStockLabel => 'Tồn kho hiện tại';

  @override
  String get minStockLabel => 'Tồn kho tối thiểu';

  @override
  String get needReplenish => 'Cần bổ sung';

  @override
  String get salesReport => 'Báo cáo bán hàng';

  @override
  String get salesTrend => 'Xu hướng bán hàng';

  @override
  String get noDataAvailable => 'Không có dữ liệu';

  @override
  String get exportExcel => 'Xuất Excel';

  @override
  String excelSaved(Object path) {
    return 'Đã lưu Excel: $path';
  }

  @override
  String exportFailed(Object error) {
    return 'Xuất thất bại: $error';
  }

  @override
  String get customerManagement => 'Quản lý khách hàng';

  @override
  String get addCustomer => 'Thêm khách hàng';

  @override
  String get editCustomer => 'Sửa khách hàng';

  @override
  String get searchCustomerHint => 'Tìm theo tên, SĐT, email...';

  @override
  String get noCustomers => 'Không có khách hàng';

  @override
  String get noSearchResult => 'Không có kết quả';

  @override
  String get points => 'Điểm';

  @override
  String get earnPoints => 'Tích';

  @override
  String get usePoints => 'Dùng';

  @override
  String get purchaseHistory => 'Lịch sử mua hàng';

  @override
  String get noPurchaseHistory => 'Chưa có lịch sử mua hàng';

  @override
  String get earnPointsTitle => 'Tích điểm';

  @override
  String get usePointsTitle => 'Dùng điểm';

  @override
  String get pointsLabel => 'Điểm';

  @override
  String get earnPointsHint => 'Điểm muốn tích';

  @override
  String usePointsHint(Object points) {
    return 'Điểm muốn dùng (hiện có: ${points}P)';
  }

  @override
  String get customerNameLabel => 'Tên *';

  @override
  String get customerPhoneLabel => 'Số điện thoại';

  @override
  String get customerEmailLabel => 'Email';

  @override
  String get customerNoteLabel => 'Ghi chú';

  @override
  String get tableManagement => 'Quản lý bàn';

  @override
  String get tableLayout => 'Bố trí bàn';

  @override
  String get reservationManagement => 'Quản lý đặt chỗ';

  @override
  String get addTable => 'Thêm bàn';

  @override
  String get noTables => 'Không có bàn';

  @override
  String get noTablesFiltered => 'Không có bàn với trạng thái này';

  @override
  String get emptyTables => 'Bàn trống';

  @override
  String get occupiedTables => 'Đang sử dụng';

  @override
  String get allTables => 'Tất cả';

  @override
  String get tableAvailable => 'Trống';

  @override
  String get tableOccupied => 'Đang dùng';

  @override
  String get tableReserved => 'Đã đặt';

  @override
  String get tableSeated => 'Đang ngồi';

  @override
  String get tablePaymentComplete => 'Đã thanh toán';

  @override
  String get tableCleaning => 'Đang dọn';

  @override
  String get tableNameLabel => 'Tên bàn *';

  @override
  String get tableNumber => 'Số bàn';

  @override
  String get tableNumberHint => 'VD: 1, A1, VIP-1';

  @override
  String get tableNumberRequired => 'Vui lòng nhập số bàn';

  @override
  String tableAdded(String number) {
    return 'Đã thêm bàn $number';
  }

  @override
  String editTable(String number) {
    return 'Sửa bàn $number';
  }

  @override
  String get deleteTable => 'Xóa bàn';

  @override
  String deleteTableConfirm(String number) {
    return 'Bạn có muốn xóa bàn $number không?';
  }

  @override
  String tableDeleted(String number) {
    return 'Đã xóa bàn $number';
  }

  @override
  String tableUpdated(String number) {
    return 'Đã cập nhật bàn $number';
  }

  @override
  String get tableNameHint => 'VD: Bàn 1, A-1';

  @override
  String get seatsLabel => 'Số ghế';

  @override
  String get seatsCount => 'Số ghế';

  @override
  String get zoneLabel => 'Khu vực';

  @override
  String get zoneHint => 'VD: Sảnh, Sân thượng, Phòng';

  @override
  String get startUse => 'Bắt đầu';

  @override
  String get reserve => 'Đặt chỗ';

  @override
  String get clearTable => 'Dọn bàn (xong)';

  @override
  String get moveTable => 'Chuyển bàn';

  @override
  String get reserveToUse => 'Đặt → Sử dụng';

  @override
  String get clearTableShort => 'Dọn bàn';

  @override
  String moveTableTitle(Object name) {
    return '$name → Chuyển';
  }

  @override
  String get noEmptyTables => 'Không có bàn trống.';

  @override
  String seatsUnit(Object count) {
    return '$count ghế';
  }

  @override
  String get refundManagement => 'Hoàn tiền/Trả hàng';

  @override
  String get searchByReceipt => 'Tìm theo số hóa đơn';

  @override
  String get receiptNumberHint => 'Nhập số hóa đơn (VD: ODA-20250207-001)';

  @override
  String get refundedStatus => 'Đã hoàn tiền';

  @override
  String get paidStatus => 'Đã thanh toán';

  @override
  String get selectRefundItems => 'Chọn mục hoàn tiền';

  @override
  String get refundReasonLabel => 'Lý do hoàn tiền';

  @override
  String get refundReasonHint => 'Nhập lý do hoàn tiền';

  @override
  String partialRefund(Object amount) {
    return 'Hoàn một phần ($amount)';
  }

  @override
  String get fullRefund => 'Hoàn toàn bộ';

  @override
  String get alreadyRefunded => 'Đơn hàng đã được hoàn tiền.';

  @override
  String get todayRefundHistory => 'Hoàn tiền hôm nay';

  @override
  String get noRefundToday => 'Không có hoàn tiền hôm nay';

  @override
  String get fullRefundType => 'Toàn bộ';

  @override
  String get partialRefundType => 'Một phần';

  @override
  String get receiptNotFound => 'Không tìm thấy hóa đơn';

  @override
  String get fullRefundComplete => 'Đã hoàn tiền toàn bộ';

  @override
  String get partialRefundComplete => 'Đã hoàn tiền một phần';

  @override
  String refundConfirm(Object amount) {
    return 'Hoàn tiền $amount?';
  }

  @override
  String get refundAction => 'Hoàn tiền';

  @override
  String get cashDrawerManagement => 'Quản lý quỹ';

  @override
  String get currentCashDrawer => 'Quỹ hiện tại';

  @override
  String get openStatus => 'Đang mở';

  @override
  String get closedStatus => 'Đã đóng';

  @override
  String get openDrawer => 'Mở quỹ';

  @override
  String get closeDrawer => 'Đóng quỹ';

  @override
  String get deposit => 'Nạp tiền';

  @override
  String get withdraw => 'Rút tiền';

  @override
  String get sale => 'Bán hàng';

  @override
  String get todayTransactions => 'Giao dịch hôm nay';

  @override
  String get noTransactionsToday => 'Không có giao dịch hôm nay';

  @override
  String balance(Object amount) {
    return 'Số dư $amount';
  }

  @override
  String get cashDrawerOpen => 'Mở quỹ';

  @override
  String get cashDrawerClose => 'Đóng quỹ';

  @override
  String get cashDrawerDeposit => 'Nạp tiền';

  @override
  String get cashDrawerWithdraw => 'Rút tiền';

  @override
  String get cashDrawerSale => 'Bán hàng';

  @override
  String get cashDrawerRefund => 'Hoàn tiền';

  @override
  String get amountLabel => 'Số tiền';

  @override
  String get memoLabel => 'Ghi chú (tùy chọn)';

  @override
  String get closeSettlement => 'Đóng quỹ cuối ngày';

  @override
  String systemBalance(Object amount) {
    return 'Số dư hệ thống: $amount';
  }

  @override
  String get actualCashAmount => 'Số tiền thực tế';

  @override
  String get countCashHint => 'Đếm tiền và nhập số tiền';

  @override
  String get normalClose => 'Đóng quỹ';

  @override
  String difference(Object amount) {
    return 'Chênh lệch: $amount';
  }

  @override
  String closeComplete(Object note) {
    return 'Đã đóng quỹ. $note';
  }

  @override
  String get syncStatus => 'Trạng thái đồng bộ';

  @override
  String get network => 'Mạng';

  @override
  String get connected => 'Đã kết nối';

  @override
  String get offline => 'Ngoại tuyến';

  @override
  String get pendingItems => 'Đang chờ';

  @override
  String pendingCount(Object count) {
    return '$count mục';
  }

  @override
  String get lastSync => 'Đồng bộ cuối';

  @override
  String get notYet => 'Chưa có';

  @override
  String get syncing => 'Đang đồng bộ...';

  @override
  String get syncNow => 'Đồng bộ ngay';

  @override
  String get syncAutoMsg => 'Tự động đồng bộ 5 phút/lần khi có mạng';

  @override
  String get syncOfflineMsg =>
      'Tất cả tính năng hoạt động ngoại tuyến.\nTự động đồng bộ khi có mạng.';

  @override
  String get justNow => 'Vừa xong';

  @override
  String minutesAgo(Object min) {
    return '$min phút trước';
  }

  @override
  String hoursAgo(Object hours) {
    return '$hours giờ trước';
  }

  @override
  String get offlineIndicator => 'Ngoại tuyến';

  @override
  String get pinLoginTitle => 'Nhập PIN để đăng nhập';

  @override
  String get pinMismatch => 'PIN không đúng';

  @override
  String loginError(Object error) {
    return 'Lỗi đăng nhập: $error';
  }

  @override
  String get msgItemAdded => 'Đã thêm vào giỏ hàng';

  @override
  String get msgPaymentSuccess => 'Thanh toán thành công';

  @override
  String get msgPaymentFailed => 'Thanh toán thất bại';

  @override
  String get msgInsufficientStock => 'Không đủ hàng trong kho';

  @override
  String get msgInvalidAmount => 'Số tiền không hợp lệ';

  @override
  String get msgSaved => 'Đã lưu thành công';

  @override
  String get msgDeleted => 'Đã xóa thành công';

  @override
  String msgError(Object error) {
    return 'Đã xảy ra lỗi: $error';
  }

  @override
  String get quantity => 'Số lượng';

  @override
  String get price => 'Giá';

  @override
  String get amount => 'Số tiền';

  @override
  String get description => 'Mô tả';

  @override
  String get active => 'Hoạt động';

  @override
  String get inactive => 'Không hoạt động';

  @override
  String get status => 'Trạng thái';

  @override
  String get cashPayment => 'Tiền mặt';

  @override
  String get cardPayment => 'Thẻ';

  @override
  String get qrPayment => 'Mã QR';

  @override
  String get transferPayment => 'Chuyển khoản';

  @override
  String get salesLabel => 'Bán hàng';

  @override
  String get refundLabel => 'Hoàn tiền';

  @override
  String get excelManage => 'Quản lý Excel';

  @override
  String get excelDownload => 'Tải xuống Excel';

  @override
  String get excelDownloadDesc => 'Xuất danh sách sản phẩm hiện tại';

  @override
  String get excelUpload => 'Tải lên từ Excel';

  @override
  String get excelUploadDesc => 'Thêm/cập nhật sản phẩm từ .xlsx';

  @override
  String get excelExporting => 'Đang tạo tệp Excel...';

  @override
  String get excelSaveComplete => 'Đã lưu tệp Excel!';

  @override
  String get excelSaveFailed => 'Lưu bị hủy hoặc thất bại. Vui lòng thử lại.';

  @override
  String get excelFileSave => 'Lưu tệp Excel';

  @override
  String get excelFileSelect => 'Chọn tệp Excel';

  @override
  String get uploadComplete => 'Tải lên hoàn tất';

  @override
  String get newProductAdded => 'Sản phẩm mới đã thêm';

  @override
  String get existingProductUpdated => 'Sản phẩm đã cập nhật';

  @override
  String get totalProcessed => 'Tổng đã xử lý';

  @override
  String countUnit(Object count) {
    return '$count mục';
  }

  @override
  String errorsOccurred(Object count) {
    return '⚠️ $count lỗi đã xảy ra';
  }

  @override
  String productDeleted(Object name) {
    return '\'$name\' đã bị xóa';
  }

  @override
  String errorPrefix(Object error) {
    return 'Lỗi: $error';
  }

  @override
  String get noProductsFound => 'Không tìm thấy sản phẩm';

  @override
  String get sku => 'SKU';

  @override
  String get category => 'Danh mục';

  @override
  String get sellingPrice => 'Giá bán';

  @override
  String get costPrice => 'Giá vốn';

  @override
  String get stock => 'Tồn kho';

  @override
  String get minStock => 'Tồn kho tối thiểu';

  @override
  String get action => 'Thao tác';

  @override
  String get statusOutOfStock => 'Hết hàng';

  @override
  String get statusLow => 'Thấp';

  @override
  String get statusNormal => 'Bình thường';

  @override
  String piecesUnit(Object count) {
    return '$count';
  }

  @override
  String get stockAdjust => 'Điều chỉnh kho';

  @override
  String get basicInfo => 'Thông tin cơ bản';

  @override
  String get productNameRequired => 'Tên sản phẩm *';

  @override
  String get priceInfo => 'Thông tin giá';

  @override
  String get sellingPriceRequired => 'Giá bán *';

  @override
  String get stockInfo => 'Thông tin tồn kho';

  @override
  String get stockQuantity => 'Số lượng tồn kho';

  @override
  String get categoryHint => 'Thực phẩm, Đồ uống, Điện tử, v.v.';

  @override
  String get productUpdated => 'Đã cập nhật sản phẩm';

  @override
  String get productAdded => 'Đã thêm sản phẩm';

  @override
  String get productImage => 'Hình ảnh sản phẩm';

  @override
  String get noImage => 'Không có hình ảnh';

  @override
  String get camera => 'Máy ảnh';

  @override
  String get gallery => 'Thư viện';

  @override
  String get aiAutoSearch => 'Tìm kiếm tự động AI';

  @override
  String get aiImageSearch => 'Tìm kiếm hình ảnh AI';

  @override
  String get aiImageSearchComplete => 'Hoàn tất tìm kiếm hình ảnh AI';

  @override
  String get imageUploaded => 'Đã tải lên hình ảnh';

  @override
  String get deleteImage => 'Xóa hình ảnh';

  @override
  String get deleteImageConfirm =>
      'Bạn có thực sự muốn xóa hình ảnh này không?';

  @override
  String get imageDeleted => 'Đã xóa hình ảnh';

  @override
  String get imageSetByAi => 'Hình ảnh được đặt bởi tìm kiếm AI';

  @override
  String imageDownloadFailed(String error) {
    return 'Tải hình ảnh thất bại: $error';
  }

  @override
  String get noProductsWithoutImage =>
      'Không có sản phẩm nào không có hình ảnh';

  @override
  String get searching => 'Đang tìm kiếm...';

  @override
  String get searchFailed => 'Tìm kiếm thất bại';

  @override
  String get noSearchResults => 'Không có kết quả tìm kiếm';

  @override
  String noImagesFound(String product) {
    return 'Không tìm thấy hình ảnh cho\n\"$product\"';
  }

  @override
  String searchQuery(String query) {
    return 'Tìm kiếm: $query';
  }

  @override
  String get success => 'Thành công';

  @override
  String get failed => 'Thất bại';

  @override
  String get successRate => 'Tỷ lệ thành công';

  @override
  String failedProducts(int count) {
    return 'Sản phẩm thất bại ($count)';
  }

  @override
  String get image => 'Hình ảnh';

  @override
  String get unit => 'đơn vị';

  @override
  String get deleteProductTitle => 'Xóa sản phẩm';

  @override
  String deleteProductConfirm(Object name) {
    return 'Xóa \'$name\'?\nHành động này không thể hoàn tác.';
  }

  @override
  String get receipt => 'Hóa đơn';

  @override
  String get print => 'In';

  @override
  String get orderNumber => 'Mã đơn hàng';

  @override
  String get unitPrice => 'Đơn giá';

  @override
  String get cashPaidAmount => 'Số tiền đã trả';

  @override
  String get thankYouMessage => 'Cảm ơn quý khách!';

  @override
  String get newOrder => 'Đơn hàng mới';

  @override
  String get receiptPrint => 'In hóa đơn';

  @override
  String get paperFormat => 'Khổ giấy';

  @override
  String get receiptFormat => 'Hóa đơn (80mm)';

  @override
  String get thermalPrinter => 'Dùng cho máy in nhiệt';

  @override
  String get a4Format => 'A4';

  @override
  String get regularPrinter => 'Dùng cho máy in thường';

  @override
  String get preview => 'Xem trước';

  @override
  String get printing => 'Đang in...';

  @override
  String get receiptPreview => 'Xem trước hóa đơn';

  @override
  String receiptFileName(Object saleNumber) {
    return 'HoaDon_$saleNumber.pdf';
  }

  @override
  String printError(Object error) {
    return 'Lỗi in: $error';
  }

  @override
  String get stockAdjustment => 'Điều chỉnh tồn kho';

  @override
  String get currentStockAmount => 'Tồn kho hiện tại';

  @override
  String get adjustmentType => 'Loại điều chỉnh';

  @override
  String get stockIn => '+ Nhập kho';

  @override
  String get stockOut => '- Xuất kho';

  @override
  String get adjustmentQuantity => 'Số lượng điều chỉnh';

  @override
  String get enterQuantity => 'Nhập số lượng';

  @override
  String get reasonOptional => 'Lý do (tùy chọn)';

  @override
  String get reasonHint => 'VD: Nhập hàng mới, Hao hụt, v.v.';

  @override
  String get stockAfterAdjust => 'Tồn kho sau điều chỉnh';

  @override
  String get adjustComplete => 'Hoàn tất';

  @override
  String stockAdjusted(Object change) {
    return 'Đã điều chỉnh tồn kho ($change)';
  }

  @override
  String get barcodeSkuInput => 'Nhập mã vạch / SKU';

  @override
  String get barcodeOrSku => 'Mã vạch hoặc SKU';

  @override
  String get lookup => 'Tra cứu';

  @override
  String get continuousScanMode => 'Chế độ quét liên tục';

  @override
  String get autoResetAfterInput => '— Tự động đặt lại sau khi nhập';

  @override
  String get barcodeScannerHelp =>
      'Tự động tra cứu khi kết nối máy quét mã vạch USB.';

  @override
  String addedToCartMsg(Object name) {
    return '✓  $name — Đã thêm vào giỏ';
  }

  @override
  String outOfStockMsg(Object name) {
    return '✗  $name — Hiện đã hết hàng';
  }

  @override
  String productNotFoundMsg(Object input) {
    return '✗  [$input] Không tìm thấy sản phẩm';
  }

  @override
  String get excelSheetProductList => 'Danh sách sản phẩm';

  @override
  String get excelHeaderProductName => 'Tên sản phẩm';

  @override
  String get excelHeaderBarcode => 'Mã vạch';

  @override
  String get excelHeaderCategory => 'Danh mục';

  @override
  String get excelHeaderSellingPrice => 'Giá bán';

  @override
  String get excelHeaderCostPrice => 'Giá vốn';

  @override
  String get excelHeaderStock => 'Tồn kho';

  @override
  String get excelHeaderMinStock => 'Tồn kho tối thiểu';

  @override
  String excelRowNameEmpty(Object row) {
    return 'Hàng $row: Tên sản phẩm trống';
  }

  @override
  String excelRowPriceError(Object row) {
    return 'Hàng $row: Giá bán phải từ 0 trở lên';
  }

  @override
  String excelRowCostError(Object row) {
    return 'Hàng $row: Giá vốn phải từ 0 trở lên';
  }

  @override
  String excelRowStockError(Object row) {
    return 'Hàng $row: Tồn kho phải từ 0 trở lên';
  }

  @override
  String excelRowError(Object error, Object row) {
    return 'Hàng $row: $error';
  }

  @override
  String insufficientStockError(Object stock) {
    return 'Không đủ hàng tồn kho. Hiện tại: $stock';
  }

  @override
  String get saleReason => 'Bán hàng';

  @override
  String get refundStockRestore => 'Hoàn trả tồn kho do hoàn tiền';

  @override
  String get partialRefundStockRestore =>
      'Hoàn trả tồn kho do hoàn tiền một phần';

  @override
  String get reportSheetSummary => 'Tổng quan';

  @override
  String get reportTitle => 'Báo cáo doanh thu Oda POS';

  @override
  String reportPeriod(Object from, Object to) {
    return 'Kỳ: $from ~ $to';
  }

  @override
  String get reportItem => 'Mục';

  @override
  String get reportValue => 'Giá trị';

  @override
  String get reportTotalSales => 'Tổng doanh thu';

  @override
  String get reportOrderCount => 'Số đơn hàng';

  @override
  String get reportAvgOrder => 'Giá trị đơn trung bình';

  @override
  String get reportGrowthRate => 'Tốc độ tăng trưởng (%)';

  @override
  String get reportSheetDaily => 'Doanh thu theo ngày';

  @override
  String get reportDate => 'Ngày';

  @override
  String get reportSales => 'Doanh thu';

  @override
  String get reportSheetPayment => 'Theo phương thức thanh toán';

  @override
  String get reportSheetProduct => 'Doanh thu theo sản phẩm';

  @override
  String get reportRank => 'Xếp hạng';

  @override
  String get reportQuantitySold => 'SL đã bán';

  @override
  String get employeeInfoEdit =>
      'Chỉnh sửa thông tin nhân viên. Nhập số 4 chữ số mới để đổi PIN.';

  @override
  String get employeeInfoNew =>
      'Nhân viên mới sẽ được tạo. Họ có thể đăng nhập bằng PIN.';

  @override
  String get barcode => 'Mã vạch';

  @override
  String get categoryAll => 'Tất cả';

  @override
  String get categoryFood => 'Thực phẩm';

  @override
  String get categoryBeverage => 'Đồ uống';

  @override
  String get categoryElectronics => 'Điện tử';

  @override
  String get categoryDaily => 'Hàng hóa hàng ngày';

  @override
  String get kdsTitle => 'Hệ thống Hiển thị Nhà bếp';

  @override
  String get kdsCompleted => 'Hoàn thành';

  @override
  String get kdsInProgress => 'Đang xử lý';

  @override
  String get kdsAverage => 'Trung bình';

  @override
  String kdsMinutes(Object count, Object seconds) {
    return '$count phút $seconds giây';
  }

  @override
  String kdsOrdersCount(Object count) {
    return '$count đơn';
  }

  @override
  String get kdsStatusPending => 'Chờ xử lý';

  @override
  String get kdsStatusPreparing => 'Đang chuẩn bị';

  @override
  String get kdsStatusReady => 'Sẵn sàng';

  @override
  String get kdsStatusServed => 'Đã phục vụ';

  @override
  String get kdsStatusCancelled => 'Đã hủy';

  @override
  String get kdsPriorityNormal => 'Bình thường';

  @override
  String get kdsPriorityUrgent => 'Khẩn cấp';

  @override
  String get kdsFilterAll => 'Tất cả';

  @override
  String get kdsFilterPending => 'Chờ xử lý';

  @override
  String get kdsFilterPreparing => 'Đang chuẩn bị';

  @override
  String get kdsFilterReady => 'Sẵn sàng';

  @override
  String get kdsNoOrders => 'Không có đơn hàng';

  @override
  String kdsErrorOccurred(Object error) {
    return 'Đã xảy ra lỗi: $error';
  }

  @override
  String kdsTakeout(Object id) {
    return 'Mang đi #$id';
  }

  @override
  String get kdsOrderTime => 'Thời gian đặt hàng';

  @override
  String get kdsStatus => 'Trạng thái';

  @override
  String get kdsPriority => 'Ưu tiên';

  @override
  String get kdsSpecialRequest => 'Yêu cầu đặc biệt';

  @override
  String get kdsProcessingHistory => 'Lịch sử xử lý';

  @override
  String get kdsCancelOrder => 'Hủy';

  @override
  String get kdsCancelOrderConfirm =>
      'Bạn có chắc chắn muốn hủy đơn hàng này không?';

  @override
  String get kdsOrderReceived => 'Đã nhận đơn';

  @override
  String get kdsPreparationStarted => 'Bắt đầu chuẩn bị';

  @override
  String get kdsPreparationComplete => 'Chuẩn bị xong';

  @override
  String get kdsServingComplete => 'Hoàn thành phục vụ';

  @override
  String get kdsOrderCancelled => 'Đã hủy';

  @override
  String get kdsStartPreparation => 'Bắt đầu chuẩn bị';

  @override
  String get kdsMarkAsReady => 'Đánh dấu sẵn sàng';

  @override
  String get kdsMarkAsServed => 'Đánh dấu đã phục vụ';

  @override
  String kdsElapsedMinutes(Object minutes) {
    return 'Đã trôi qua $minutes phút';
  }

  @override
  String get kdsTableNumber => 'Số bàn';

  @override
  String get kdsSpecialInstructions => 'Hướng dẫn đặc biệt';

  @override
  String get dailyClosing => 'Đóng quỹ hàng ngày';

  @override
  String get closingHistory => 'Lịch sử đóng quỹ';

  @override
  String get closingSummary => 'Tóm tắt đóng quỹ';

  @override
  String get selectClosingDate => 'Chọn ngày đóng quỹ';

  @override
  String get selectDate => 'Chọn ngày';

  @override
  String get salesAggregation => 'Tổng hợp doanh thu';

  @override
  String get totalTransactions => 'Tổng số giao dịch';

  @override
  String transactionsCount(int count) {
    return '$count giao dịch';
  }

  @override
  String get cashCount => 'Kiểm quỹ';

  @override
  String get expectedCash => 'Tiền mặt dự kiến';

  @override
  String get actualCash => 'Tiền mặt thực tế';

  @override
  String get cashDifference => 'Chênh lệch tiền mặt';

  @override
  String get enterActualCash => 'Nhập tiền mặt thực tế';

  @override
  String get actualCashHint => 'Nhập số tiền mặt thực tế';

  @override
  String get cashDifferenceAcceptable => 'Vượt quá phạm vi cho phép (±10.000₫)';

  @override
  String get specialNotes => 'Ghi chú đặc biệt';

  @override
  String get notesPlaceholder => 'Nhập ghi chú đặc biệt nếu có';

  @override
  String get performClosing => 'Thực hiện đóng quỹ';

  @override
  String get skipCashCount => 'Đóng quỹ không kiểm tiền';

  @override
  String get closingComplete => 'Đóng quỹ hoàn tất';

  @override
  String get closingFailed => 'Đã xảy ra lỗi khi đóng quỹ';

  @override
  String get loadingClosingData => 'Đang tải dữ liệu đóng quỹ...';

  @override
  String get noClosingHistory => 'Không có lịch sử đóng quỹ';

  @override
  String get loadClosingHistoryFailed => 'Không thể tải lịch sử đóng quỹ';

  @override
  String get tryAgainLater => 'Vui lòng thử lại sau';

  @override
  String get selectPeriod => 'Chọn kỳ';

  @override
  String get viewDetails => 'Xem chi tiết';

  @override
  String get generatePdf => 'Tạo PDF';

  @override
  String savePdfQuestion(String reportName) {
    return 'Bạn có muốn lưu $reportName dưới dạng PDF không?';
  }

  @override
  String get generate => 'Tạo';

  @override
  String editActualCash(String label) {
    return 'Sửa $label';
  }

  @override
  String get closingDetails => 'Chi tiết đóng quỹ';

  @override
  String get closingTime => 'Thời gian đóng quỹ';

  @override
  String get assignedEmployee => 'Người phụ trách';

  @override
  String get unknown => 'Không rõ';

  @override
  String get averageTransaction => 'Trung bình mỗi giao dịch';

  @override
  String get taxTotal => 'Tổng thuế';

  @override
  String get discountTotal => 'Tổng giảm giá';

  @override
  String get normalCashDifference => 'Trong phạm vi';

  @override
  String pdfSaved(String path) {
    return 'Đã lưu PDF: $path';
  }

  @override
  String pdfGenerationFailed(String error) {
    return 'Tạo PDF thất bại: $error';
  }

  @override
  String get alreadyClosed => 'Ngày này đã được đóng quỹ';

  @override
  String get cannotCloseFutureDate => 'Không thể đóng quỹ cho ngày tương lai';

  @override
  String get noSalesForDate => 'Không có doanh thu cho ngày này';

  @override
  String get loginRequired => 'Yêu cầu đăng nhập';

  @override
  String get closingProcessError =>
      'Đã xảy ra lỗi khi đóng quỹ. Vui lòng thử lại sau';

  @override
  String get dailyClosingReport => 'Báo cáo đóng quỹ hàng ngày';

  @override
  String get closingInfo => 'Thông tin đóng quỹ';

  @override
  String get closingDate => 'Ngày đóng quỹ';

  @override
  String get paymentMethodBreakdown => 'Phân tích theo phương thức';

  @override
  String get qrPaymentSales => 'Thanh toán QR';

  @override
  String get transferSales => 'Chuyển khoản';

  @override
  String get cashReconciliation => 'Đối chiếu tiền mặt';

  @override
  String get signatureSection => 'Chữ ký';

  @override
  String get closingManager => 'Người đóng quỹ';

  @override
  String get verifier => 'Người xác nhận';

  @override
  String get signature => 'Chữ ký';

  @override
  String get userGuide => 'Hướng dẫn sử dụng';

  @override
  String get tutorial => 'Hướng dẫn';

  @override
  String get tutorialSkip => 'Bỏ qua';

  @override
  String get tutorialNext => 'Tiếp theo';

  @override
  String get tutorialPrevious => 'Trước';

  @override
  String get tutorialFinish => 'Hoàn thành';

  @override
  String get tutorialDontShowAgain => 'Không hiện lại';

  @override
  String get tutorial_daily_closing_welcome_title =>
      'Chào mừng đến với Đóng quỹ hàng ngày';

  @override
  String get tutorial_daily_closing_welcome_desc =>
      'Sử dụng Đóng quỹ hàng ngày để đối chiếu và ghi lại doanh thu trong ngày. Hãy bắt đầu với hướng dẫn nhanh.';

  @override
  String get tutorial_daily_closing_date_title => 'Chọn ngày đóng quỹ';

  @override
  String get tutorial_daily_closing_date_desc =>
      'Nhấn vào đây để chọn ngày bạn muốn đóng quỹ. Ngày hôm nay được chọn mặc định.';

  @override
  String get tutorial_daily_closing_summary_title => 'Tóm tắt doanh thu';

  @override
  String get tutorial_daily_closing_summary_desc =>
      'Thẻ này hiển thị tổng giao dịch, tổng doanh thu, trung bình mỗi giao dịch, thuế và giảm giá.';

  @override
  String get tutorial_daily_closing_payment_title =>
      'Phân tích theo phương thức thanh toán';

  @override
  String get tutorial_daily_closing_payment_desc =>
      'Xem doanh thu theo từng phương thức: tiền mặt, thẻ, thanh toán QR và chuyển khoản.';

  @override
  String get tutorial_daily_closing_cash_title => 'Đối chiếu tiền mặt';

  @override
  String get tutorial_daily_closing_cash_desc =>
      'So sánh tiền mặt dự kiến với số tiền mặt thực tế để xác minh chênh lệch.';

  @override
  String get tutorial_daily_closing_actual_cash_title =>
      'Nhập tiền mặt thực tế';

  @override
  String get tutorial_daily_closing_actual_cash_desc =>
      'Nhấn nút này để nhập số tiền mặt thực tế bạn đã đếm. Hệ thống sẽ xác minh xem chênh lệch có trong phạm vi chấp nhận được không.';

  @override
  String get tutorial_daily_closing_notes_title => 'Ghi chú đặc biệt';

  @override
  String get tutorial_daily_closing_notes_desc =>
      'Bạn có thể thêm ghi chú về các sự kiện đặc biệt khi đóng quỹ, chẳng hạn như hoàn tiền hoặc thiếu hụt.';

  @override
  String get tutorial_daily_closing_perform_title => 'Thực hiện đóng quỹ';

  @override
  String get tutorial_daily_closing_perform_desc =>
      'Sau khi xác minh tất cả thông tin, nhấn nút này để hoàn tất đóng quỹ. Lưu ý: Không thể hoàn tác đóng quỹ.';

  @override
  String get tutorial_daily_closing_history_title => 'Lịch sử đóng quỹ';

  @override
  String get tutorial_daily_closing_history_desc =>
      'Xem các bản ghi đóng quỹ trước đó và tải xuống dưới dạng báo cáo PDF.';

  @override
  String get reservations => 'Đặt chỗ';

  @override
  String get addReservation => 'Thêm đặt chỗ';

  @override
  String get reservationDetail => 'Chi tiết đặt chỗ';

  @override
  String get deleteReservation => 'Xóa đặt chỗ';

  @override
  String deleteReservationConfirm(String customer) {
    return 'Bạn có chắc chắn muốn xóa đặt chỗ của $customer?';
  }

  @override
  String get reservationDeleted => 'Đã xóa đặt chỗ';

  @override
  String get noReservations => 'Không có đặt chỗ';

  @override
  String reservationStatusChanged(String status) {
    return 'Trạng thái đặt chỗ đã thay đổi thành $status';
  }

  @override
  String get reservationPending => 'Chờ xử lý';

  @override
  String get reservationConfirmed => 'Đã xác nhận';

  @override
  String get reservationSeated => 'Đã ngồi';

  @override
  String get reservationCancelled => 'Đã hủy';

  @override
  String get reservationNoShow => 'Không đến';

  @override
  String get confirmed => 'Đã xác nhận';

  @override
  String get pending => 'Chờ xử lý';

  @override
  String get customerName => 'Tên khách hàng';

  @override
  String get customerPhone => 'Liên hệ';

  @override
  String get partySize => 'Số người';

  @override
  String get table => 'Bàn';

  @override
  String partySizePeople(int count) {
    return '$count người';
  }

  @override
  String get reservationDate => 'Ngày đặt chỗ';

  @override
  String get reservationTime => 'Giờ đặt chỗ';

  @override
  String get specialRequests => 'Yêu cầu đặc biệt';

  @override
  String get specialRequestsOptional => 'Yêu cầu đặc biệt (Tùy chọn)';

  @override
  String get createdAt => 'Tạo lúc';

  @override
  String get allReservations => 'Tất cả';

  @override
  String errorOccurredWithMessage(String message) {
    return 'Đã xảy ra lỗi: $message';
  }

  @override
  String get editReservation => 'Chỉnh sửa đặt chỗ';

  @override
  String get customerNameRequired => 'Vui lòng nhập tên khách hàng';

  @override
  String get customerPhoneRequired => 'Vui lòng nhập số liên hệ';

  @override
  String get partySizeRequired => 'Vui lòng nhập số người';

  @override
  String get partySizeInvalid => 'Số người phải ít nhất là 1';

  @override
  String get people => 'người';
}

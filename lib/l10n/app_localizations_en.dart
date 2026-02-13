// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Oda POS';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get search => 'Search';

  @override
  String get settings => 'Settings';

  @override
  String get close => 'Close';

  @override
  String get confirm => 'Confirm';

  @override
  String get back => 'Back';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Loading...';

  @override
  String get noData => 'No Data';

  @override
  String get retry => 'Retry';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get more => 'More';

  @override
  String get all => 'All';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get customPeriod => 'Custom';

  @override
  String get none => 'None';

  @override
  String get apply => 'Apply';

  @override
  String get activate => 'Activate';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get navPos => 'POS';

  @override
  String get navProducts => 'Products';

  @override
  String get navSales => 'Sales';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navInventory => 'Low Stock';

  @override
  String get navEmployees => 'Employees';

  @override
  String get navPromotions => 'Promotions';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navTables => 'Tables';

  @override
  String get navRefunds => 'Refunds';

  @override
  String get navCashDrawer => 'Cash';

  @override
  String get navKds => 'Kitchen';

  @override
  String get navDailyClosing => 'Daily Closing';

  @override
  String get cart => 'Cart';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get discount => 'Discount';

  @override
  String get total => 'Total';

  @override
  String get checkout => 'Checkout';

  @override
  String get clearCart => 'Clear';

  @override
  String get addDiscount => 'Add Discount';

  @override
  String get applyPromotion => 'Apply Promotion';

  @override
  String get autoPromotionsApplied => 'Auto Promotions Applied';

  @override
  String get cartEmpty => 'Your cart is empty';

  @override
  String get addProductsPlease => 'Add products to cart';

  @override
  String payAmount(Object amount) {
    return 'Pay $amount';
  }

  @override
  String get discountSettings => 'Discount Settings';

  @override
  String get promotion => 'Promotion';

  @override
  String get paymentAmount => 'Payment Amount';

  @override
  String itemCount(Object count) {
    return '$count items';
  }

  @override
  String get appliedProducts => 'Select Products';

  @override
  String get productName => 'Product Name';

  @override
  String get productPrice => 'Price';

  @override
  String get productStock => 'Stock';

  @override
  String get productCategory => 'Category';

  @override
  String get addProduct => 'Add Product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get deleteProduct => 'Delete Product';

  @override
  String get productManagement => 'Product Management';

  @override
  String get noProducts => 'No products found';

  @override
  String get searchProductHint => 'Search by name, SKU, barcode...';

  @override
  String addedToCart(Object name) {
    return '$name added to cart';
  }

  @override
  String outOfStock(Object name) {
    return '$name is out of stock';
  }

  @override
  String get outOfStockBadge => 'Out of Stock';

  @override
  String get lowStockBadge => 'Low Stock';

  @override
  String productNotFound(Object input) {
    return '[$input] Product not found';
  }

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get cash => 'Cash';

  @override
  String get card => 'Card';

  @override
  String get qr => 'QR Code';

  @override
  String get transfer => 'Transfer';

  @override
  String get cashReceived => 'Cash Received';

  @override
  String get change => 'Change';

  @override
  String get paymentComplete => 'Payment Complete';

  @override
  String get selectPaymentMethod => 'Select Payment Method';

  @override
  String get cashInputAmount => 'Cash Amount';

  @override
  String get enterAmount => 'Enter amount';

  @override
  String get noEmployeeLoggedIn => 'No employee logged in';

  @override
  String get paymentFailed => 'Payment Failed';

  @override
  String get receiptNumber => 'Receipt #';

  @override
  String get receiptDate => 'Date';

  @override
  String get receiptItems => 'Items';

  @override
  String get receiptThankYou => 'Thank you for your purchase!';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsExchangeRate => 'Exchange Rate';

  @override
  String get settingsSelectLanguage => 'Select Language';

  @override
  String get settingsSelectCurrency => 'Select Currency';

  @override
  String get localeSettings => 'Language & Currency';

  @override
  String get storeInfo => 'Store Information';

  @override
  String get storeName => 'Store Name';

  @override
  String get storePhone => 'Phone';

  @override
  String get storeAddress => 'Address';

  @override
  String get receiptSettings => 'Receipt Settings';

  @override
  String get footerMessage => 'Footer Message';

  @override
  String get footerDefault => 'Thank you!';

  @override
  String get showQrCode => 'Show QR Code';

  @override
  String get appInfo => 'App Information';

  @override
  String get version => 'Version';

  @override
  String get database => 'Database';

  @override
  String get syncMode => 'Sync Mode';

  @override
  String get offlineFirst => 'Offline-First';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get langKorean => '한국어';

  @override
  String get langEnglish => 'English';

  @override
  String get langVietnamese => 'Tiếng Việt';

  @override
  String get currencyUSD => 'US Dollar (\$)';

  @override
  String get currencyVND => 'Vietnamese Dong (₫)';

  @override
  String get employeeManagement => 'Employee Management';

  @override
  String get employeeLogin => 'Employee Login';

  @override
  String get selectEmployee => 'Select Employee';

  @override
  String get enterPinCode => 'Enter PIN Code';

  @override
  String get noEmployeesRegistered => 'No employees registered';

  @override
  String get forgotPin => 'Forgot your PIN? Contact manager';

  @override
  String get loginButton => 'Login';

  @override
  String loginFailed(String error) {
    return 'Login failed: $error';
  }

  @override
  String get employeeName => 'Name';

  @override
  String get employeeRole => 'Role';

  @override
  String get employeeUsername => 'Username';

  @override
  String get employeePin => 'PIN';

  @override
  String get addEmployee => 'Add Employee';

  @override
  String get editEmployee => 'Edit Employee';

  @override
  String get noEmployees => 'No employees found';

  @override
  String get employeeLoadError => 'Failed to load employee list';

  @override
  String get employeeAdded => 'New employee added';

  @override
  String get employeeUpdated => 'Employee info updated';

  @override
  String get usernameLabel => 'Username (Login ID)';

  @override
  String get usernameHint => 'e.g. john_doe';

  @override
  String get usernameRequired => 'Please enter username';

  @override
  String get usernameMinLength => 'Username must be at least 3 characters';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameHint => 'e.g. John Doe';

  @override
  String get nameRequired => 'Please enter name';

  @override
  String get roleLabel => 'Role';

  @override
  String get roleCashier => 'Cashier';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleKitchen => 'Kitchen';

  @override
  String get pinChangeLabel => 'Change PIN (optional)';

  @override
  String get pinNewLabel => 'PIN (4 digits)';

  @override
  String get pinHint => '1234';

  @override
  String get pinNoChangeHelper => 'Leave empty to keep current PIN';

  @override
  String get pinNewHelper => 'Enter 4 digits';

  @override
  String get pinRequired => 'Please enter PIN';

  @override
  String get pinLengthError => 'PIN must be 4 digits';

  @override
  String get pinDigitsOnly => 'PIN must contain only numbers';

  @override
  String get promotionManagement => 'Promotion Management';

  @override
  String get promotionName => 'Promotion Name';

  @override
  String get promotionType => 'Type';

  @override
  String get promotionValue => 'Value';

  @override
  String get addPromotion => 'Add Promotion';

  @override
  String get editPromotion => 'Edit Promotion';

  @override
  String get noPromotions => 'No promotions found';

  @override
  String get deletePromotion => 'Delete Promotion';

  @override
  String deletePromotionConfirm(Object name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get promotionNameLabel => 'Promotion Name';

  @override
  String get promotionNameHint => 'e.g. Orange Juice BOGO';

  @override
  String get promotionNameRequired => 'Please enter promotion name';

  @override
  String get promotionTypeLabel => 'Promotion Type';

  @override
  String get typeBogo => 'Buy 1 Get 1 Free';

  @override
  String get typeBuy2Get1 => 'Buy 2 Get 1 Free';

  @override
  String get typePercentOff => 'Percent Off';

  @override
  String get typeAmountOff => 'Amount Off';

  @override
  String get discountRateLabel => 'Discount Rate (%)';

  @override
  String get discountAmountLabel => 'Discount Amount';

  @override
  String get discountValueHint => 'e.g. 10';

  @override
  String get discountAmountHint => 'e.g. 1000';

  @override
  String get discountValueRequired => 'Please enter discount value';

  @override
  String get invalidNumber => 'Please enter a valid number';

  @override
  String get maxDiscountRate => 'Discount rate cannot exceed 100%';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get targetProduct => 'Target Product (optional)';

  @override
  String get allProducts => 'All Products';

  @override
  String get productLoadFailed => 'Failed to load products';

  @override
  String get noSelection => 'No Selection';

  @override
  String get bogoLabel => 'Buy 1 Get 1';

  @override
  String get buy2Get1Label => 'Buy 2 Get 1';

  @override
  String get percentOffLabel => '% Off';

  @override
  String get amountOffLabel => 'Amount Off';

  @override
  String get freeOne => '1 Free';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get todaySales => 'Today\'s Sales';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get topProducts => 'Top Products';

  @override
  String get salesDashboard => 'Sales Dashboard';

  @override
  String get paymentMethodSales => 'Sales by Payment Method';

  @override
  String get productRanking => 'Product Sales Ranking';

  @override
  String get totalSalesAmount => 'Total Sales';

  @override
  String get totalSales => 'Total Sales';

  @override
  String get orderCount => 'Orders';

  @override
  String get orderUnit => 'orders';

  @override
  String get avgOrderAmount => 'Avg. Order Amount';

  @override
  String get inventoryValue => 'Inventory Value';

  @override
  String get inventoryValueDesc => 'Total value of current inventory';

  @override
  String get noSalesData => 'No sales data';

  @override
  String soldCount(Object count) {
    return '$count sold';
  }

  @override
  String errorOccurred(String error) {
    return 'Error occurred: $error';
  }

  @override
  String get salesHistory => 'Sales History';

  @override
  String get noSalesHistory => 'No sales records';

  @override
  String totalAmount(Object amount) {
    return 'Total $amount';
  }

  @override
  String get refunded => 'Refunded';

  @override
  String dateMonth(Object day, Object month) {
    return '$month/$day';
  }

  @override
  String get lowStockAlert => 'Low Stock Alert';

  @override
  String get allStockSufficient => 'All products have sufficient stock';

  @override
  String get aboveMinStock => 'Stock levels are above minimum';

  @override
  String addStockTitle(Object name) {
    return 'Add Stock: $name';
  }

  @override
  String currentStock(Object current, Object min) {
    return 'Current: $current / Min: $min';
  }

  @override
  String get addStock => 'Add Stock';

  @override
  String get stockReplenishReason => 'Stock replenishment (low stock alert)';

  @override
  String stockAddedMsg(Object name, Object qty) {
    return 'Added $qty units of $name';
  }

  @override
  String get outOfStockLabel => 'Out of Stock';

  @override
  String get lowStockLabel => 'Low';

  @override
  String get currentStockLabel => 'Current Stock';

  @override
  String get minStockLabel => 'Min Stock';

  @override
  String get needReplenish => 'Need Replenish';

  @override
  String get salesReport => 'Sales Report';

  @override
  String get salesTrend => 'Sales Trend';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String excelSaved(Object path) {
    return 'Excel saved: $path';
  }

  @override
  String exportFailed(Object error) {
    return 'Export failed: $error';
  }

  @override
  String get customerManagement => 'Customer Management';

  @override
  String get addCustomer => 'Add Customer';

  @override
  String get editCustomer => 'Edit Customer';

  @override
  String get searchCustomerHint => 'Search by name, phone, email...';

  @override
  String get noCustomers => 'No customers found';

  @override
  String get noSearchResult => 'No search results';

  @override
  String get points => 'Points';

  @override
  String get earnPoints => 'Earn';

  @override
  String get usePoints => 'Use';

  @override
  String get purchaseHistory => 'Purchase History';

  @override
  String get noPurchaseHistory => 'No purchase history';

  @override
  String get earnPointsTitle => 'Earn Points';

  @override
  String get usePointsTitle => 'Use Points';

  @override
  String get pointsLabel => 'Points';

  @override
  String get earnPointsHint => 'Points to earn';

  @override
  String usePointsHint(Object points) {
    return 'Points to use (balance: ${points}P)';
  }

  @override
  String get customerNameLabel => 'Name *';

  @override
  String get customerPhoneLabel => 'Phone';

  @override
  String get customerEmailLabel => 'Email';

  @override
  String get customerNoteLabel => 'Notes';

  @override
  String get tableManagement => 'Table Management';

  @override
  String get tableLayout => 'Table Layout';

  @override
  String get reservationManagement => 'Reservation Management';

  @override
  String get addTable => 'Add Table';

  @override
  String get noTables => 'No tables available';

  @override
  String get noTablesFiltered => 'No tables with this status';

  @override
  String get emptyTables => 'Empty Tables';

  @override
  String get occupiedTables => 'Occupied';

  @override
  String get allTables => 'All';

  @override
  String get tableAvailable => 'Available';

  @override
  String get tableOccupied => 'Occupied';

  @override
  String get tableReserved => 'Reserved';

  @override
  String get tableSeated => 'Seated';

  @override
  String get tablePaymentComplete => 'Payment Complete';

  @override
  String get tableCleaning => 'Cleaning';

  @override
  String get tableNameLabel => 'Table Name *';

  @override
  String get tableNumber => 'Table Number';

  @override
  String get tableNumberHint => 'e.g. 1, A1, VIP-1';

  @override
  String get tableNumberRequired => 'Please enter table number';

  @override
  String tableAdded(String number) {
    return 'Table $number added';
  }

  @override
  String editTable(String number) {
    return 'Edit Table $number';
  }

  @override
  String get deleteTable => 'Delete Table';

  @override
  String deleteTableConfirm(String number) {
    return 'Do you want to delete table $number?';
  }

  @override
  String tableDeleted(String number) {
    return 'Table $number deleted';
  }

  @override
  String tableUpdated(String number) {
    return 'Table $number updated';
  }

  @override
  String get tableNameHint => 'e.g. Table 1, A-1';

  @override
  String get seatsLabel => 'Seats';

  @override
  String get seatsCount => 'Seats';

  @override
  String get zoneLabel => 'Zone';

  @override
  String get zoneHint => 'e.g. Hall, Terrace, Room';

  @override
  String get startUse => 'Start Use';

  @override
  String get reserve => 'Reserve';

  @override
  String get clearTable => 'Clear (Done)';

  @override
  String get moveTable => 'Move Table';

  @override
  String get reserveToUse => 'Reserved → Start';

  @override
  String get clearTableShort => 'Clear';

  @override
  String moveTableTitle(Object name) {
    return '$name → Move';
  }

  @override
  String get noEmptyTables => 'No empty tables available.';

  @override
  String seatsUnit(Object count) {
    return '$count seats';
  }

  @override
  String get refundManagement => 'Refunds';

  @override
  String get searchByReceipt => 'Search by Receipt #';

  @override
  String get receiptNumberHint => 'Enter receipt # (e.g. ODA-20250207-001)';

  @override
  String get refundedStatus => 'Refunded';

  @override
  String get paidStatus => 'Paid';

  @override
  String get selectRefundItems => 'Select Refund Items';

  @override
  String get refundReasonLabel => 'Refund Reason';

  @override
  String get refundReasonHint => 'Enter refund reason';

  @override
  String partialRefund(Object amount) {
    return 'Partial Refund ($amount)';
  }

  @override
  String get fullRefund => 'Full Refund';

  @override
  String get alreadyRefunded => 'This order has already been refunded.';

  @override
  String get todayRefundHistory => 'Today\'s Refunds';

  @override
  String get noRefundToday => 'No refunds today';

  @override
  String get fullRefundType => 'Full';

  @override
  String get partialRefundType => 'Partial';

  @override
  String get receiptNotFound => 'Receipt not found';

  @override
  String get fullRefundComplete => 'Full refund complete';

  @override
  String get partialRefundComplete => 'Partial refund complete';

  @override
  String refundConfirm(Object amount) {
    return 'Proceed with $amount refund?';
  }

  @override
  String get refundAction => 'Refund';

  @override
  String get cashDrawerManagement => 'Cash Drawer';

  @override
  String get currentCashDrawer => 'Current Drawer';

  @override
  String get openStatus => 'Open';

  @override
  String get closedStatus => 'Closed';

  @override
  String get openDrawer => 'Open';

  @override
  String get closeDrawer => 'Close';

  @override
  String get deposit => 'Deposit';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get sale => 'Sale';

  @override
  String get todayTransactions => 'Today\'s Transactions';

  @override
  String get noTransactionsToday => 'No transactions today';

  @override
  String balance(Object amount) {
    return 'Balance $amount';
  }

  @override
  String get cashDrawerOpen => 'Open';

  @override
  String get cashDrawerClose => 'Close';

  @override
  String get cashDrawerDeposit => 'Deposit';

  @override
  String get cashDrawerWithdraw => 'Withdraw';

  @override
  String get cashDrawerSale => 'Sale';

  @override
  String get cashDrawerRefund => 'Refund';

  @override
  String get amountLabel => 'Amount';

  @override
  String get memoLabel => 'Memo (optional)';

  @override
  String get closeSettlement => 'Close Settlement';

  @override
  String systemBalance(Object amount) {
    return 'System Balance: $amount';
  }

  @override
  String get actualCashAmount => 'Actual Cash Amount';

  @override
  String get countCashHint => 'Count cash and enter amount';

  @override
  String get normalClose => 'Close Drawer';

  @override
  String difference(Object amount) {
    return 'Diff: $amount';
  }

  @override
  String closeComplete(Object note) {
    return 'Closed. $note';
  }

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get network => 'Network';

  @override
  String get connected => 'Connected';

  @override
  String get offline => 'Offline';

  @override
  String get pendingItems => 'Pending Items';

  @override
  String pendingCount(Object count) {
    return '$count items';
  }

  @override
  String get lastSync => 'Last Sync';

  @override
  String get notYet => 'Not yet';

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get syncAutoMsg => 'Auto-syncs every 5 minutes when connected';

  @override
  String get syncOfflineMsg =>
      'All features work offline.\nAuto-syncs when connected.';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(Object min) {
    return '$min min ago';
  }

  @override
  String hoursAgo(Object hours) {
    return '$hours hours ago';
  }

  @override
  String get offlineIndicator => 'Offline';

  @override
  String get pinLoginTitle => 'Enter PIN to login';

  @override
  String get pinMismatch => 'Incorrect PIN';

  @override
  String loginError(Object error) {
    return 'Login error: $error';
  }

  @override
  String get msgItemAdded => 'Item added to cart';

  @override
  String get msgPaymentSuccess => 'Payment successful';

  @override
  String get msgPaymentFailed => 'Payment failed';

  @override
  String get msgInsufficientStock => 'Insufficient stock';

  @override
  String get msgInvalidAmount => 'Invalid amount';

  @override
  String get msgSaved => 'Saved successfully';

  @override
  String get msgDeleted => 'Deleted successfully';

  @override
  String msgError(Object error) {
    return 'An error occurred: $error';
  }

  @override
  String get quantity => 'Quantity';

  @override
  String get price => 'Price';

  @override
  String get amount => 'Amount';

  @override
  String get description => 'Description';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get status => 'Status';

  @override
  String get cashPayment => 'Cash';

  @override
  String get cardPayment => 'Card';

  @override
  String get qrPayment => 'QR Code';

  @override
  String get transferPayment => 'Transfer';

  @override
  String get salesLabel => 'Sales';

  @override
  String get refundLabel => 'Refund';

  @override
  String get excelManage => 'Excel Manage';

  @override
  String get excelDownload => 'Download as Excel';

  @override
  String get excelDownloadDesc => 'Export current product list';

  @override
  String get excelUpload => 'Upload from Excel';

  @override
  String get excelUploadDesc => 'Add/update products via .xlsx';

  @override
  String get excelExporting => 'Creating Excel file...';

  @override
  String get excelSaveComplete => 'Excel file saved!';

  @override
  String get excelSaveFailed => 'Save cancelled or failed. Please try again.';

  @override
  String get excelFileSave => 'Save Excel File';

  @override
  String get excelFileSelect => 'Select Excel File';

  @override
  String get uploadComplete => 'Upload Complete';

  @override
  String get newProductAdded => 'New Products Added';

  @override
  String get existingProductUpdated => 'Existing Products Updated';

  @override
  String get totalProcessed => 'Total Processed';

  @override
  String countUnit(Object count) {
    return '$count items';
  }

  @override
  String errorsOccurred(Object count) {
    return '⚠️ $count errors occurred';
  }

  @override
  String productDeleted(Object name) {
    return '\'$name\' has been deleted';
  }

  @override
  String errorPrefix(Object error) {
    return 'Error: $error';
  }

  @override
  String get noProductsFound => 'No products found';

  @override
  String get sku => 'SKU';

  @override
  String get category => 'Category';

  @override
  String get sellingPrice => 'Selling Price';

  @override
  String get costPrice => 'Cost';

  @override
  String get stock => 'Stock';

  @override
  String get minStock => 'Min Stock';

  @override
  String get action => 'Action';

  @override
  String get statusOutOfStock => 'Out of Stock';

  @override
  String get statusLow => 'Low';

  @override
  String get statusNormal => 'Normal';

  @override
  String piecesUnit(Object count) {
    return '$count';
  }

  @override
  String get stockAdjust => 'Stock Adjust';

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get productNameRequired => 'Product Name *';

  @override
  String get priceInfo => 'Price Info';

  @override
  String get sellingPriceRequired => 'Selling Price *';

  @override
  String get stockInfo => 'Stock Info';

  @override
  String get stockQuantity => 'Stock Quantity';

  @override
  String get categoryHint => 'Food, Beverage, Electronics, etc.';

  @override
  String get productUpdated => 'Product has been updated';

  @override
  String get productAdded => 'Product has been added';

  @override
  String get productImage => 'Product Image';

  @override
  String get noImage => 'No image';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get aiAutoSearch => 'AI Auto Search';

  @override
  String get aiImageSearch => 'AI Image Search';

  @override
  String get aiImageSearchComplete => 'AI Image Search Complete';

  @override
  String get imageUploaded => 'Image uploaded';

  @override
  String get deleteImage => 'Delete Image';

  @override
  String get deleteImageConfirm => 'Do you really want to delete this image?';

  @override
  String get imageDeleted => 'Image deleted';

  @override
  String get imageSetByAi => 'Image set by AI search';

  @override
  String imageDownloadFailed(String error) {
    return 'Image download failed: $error';
  }

  @override
  String get noProductsWithoutImage => 'No products without images';

  @override
  String get searching => 'Searching...';

  @override
  String get searchFailed => 'Search failed';

  @override
  String get noSearchResults => 'No search results';

  @override
  String noImagesFound(String product) {
    return 'No images found for\n\"$product\"';
  }

  @override
  String searchQuery(String query) {
    return 'Search: $query';
  }

  @override
  String get success => 'Success';

  @override
  String get failed => 'Failed';

  @override
  String get successRate => 'Success Rate';

  @override
  String failedProducts(int count) {
    return 'Failed Products ($count)';
  }

  @override
  String get image => 'Image';

  @override
  String get unit => 'unit';

  @override
  String get deleteProductTitle => 'Delete Product';

  @override
  String deleteProductConfirm(Object name) {
    return 'Delete \'$name\'?\nThis action cannot be undone.';
  }

  @override
  String get receipt => 'Receipt';

  @override
  String get print => 'Print';

  @override
  String get orderNumber => 'Order #';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get cashPaidAmount => 'Paid Amount';

  @override
  String get thankYouMessage => 'Thank you for your purchase!';

  @override
  String get newOrder => 'New Order';

  @override
  String get receiptPrint => 'Receipt Print';

  @override
  String get paperFormat => 'Paper Format';

  @override
  String get receiptFormat => 'Receipt (80mm)';

  @override
  String get thermalPrinter => 'For thermal printer';

  @override
  String get a4Format => 'A4';

  @override
  String get regularPrinter => 'For regular printer';

  @override
  String get preview => 'Preview';

  @override
  String get printing => 'Printing...';

  @override
  String get receiptPreview => 'Receipt Preview';

  @override
  String receiptFileName(Object saleNumber) {
    return 'Receipt_$saleNumber.pdf';
  }

  @override
  String printError(Object error) {
    return 'Print error: $error';
  }

  @override
  String get stockAdjustment => 'Stock Adjustment';

  @override
  String get currentStockAmount => 'Current Stock';

  @override
  String get adjustmentType => 'Adjustment Type';

  @override
  String get stockIn => '+ Receive';

  @override
  String get stockOut => '- Dispatch';

  @override
  String get adjustmentQuantity => 'Adjustment Qty';

  @override
  String get enterQuantity => 'Enter quantity';

  @override
  String get reasonOptional => 'Reason (optional)';

  @override
  String get reasonHint => 'e.g. New stock, Loss, etc.';

  @override
  String get stockAfterAdjust => 'Stock After Adjustment';

  @override
  String get adjustComplete => 'Complete';

  @override
  String stockAdjusted(Object change) {
    return 'Stock adjusted ($change)';
  }

  @override
  String get barcodeSkuInput => 'Barcode / SKU Input';

  @override
  String get barcodeOrSku => 'Barcode or SKU';

  @override
  String get lookup => 'Lookup';

  @override
  String get continuousScanMode => 'Continuous Scan Mode';

  @override
  String get autoResetAfterInput => '— Auto-reset after input';

  @override
  String get barcodeScannerHelp =>
      'Automatically looks up when USB barcode scanner is connected.';

  @override
  String addedToCartMsg(Object name) {
    return '✓  $name — Added to cart';
  }

  @override
  String outOfStockMsg(Object name) {
    return '✗  $name — Currently out of stock';
  }

  @override
  String productNotFoundMsg(Object input) {
    return '✗  [$input] Product not found';
  }

  @override
  String get excelSheetProductList => 'Product List';

  @override
  String get excelHeaderProductName => 'Product Name';

  @override
  String get excelHeaderBarcode => 'Barcode';

  @override
  String get excelHeaderCategory => 'Category';

  @override
  String get excelHeaderSellingPrice => 'Selling Price';

  @override
  String get excelHeaderCostPrice => 'Cost';

  @override
  String get excelHeaderStock => 'Stock';

  @override
  String get excelHeaderMinStock => 'Min Stock';

  @override
  String excelRowNameEmpty(Object row) {
    return 'Row $row: Product name is empty';
  }

  @override
  String excelRowPriceError(Object row) {
    return 'Row $row: Selling price must be 0 or greater';
  }

  @override
  String excelRowCostError(Object row) {
    return 'Row $row: Cost must be 0 or greater';
  }

  @override
  String excelRowStockError(Object row) {
    return 'Row $row: Stock must be 0 or greater';
  }

  @override
  String excelRowError(Object error, Object row) {
    return 'Row $row: $error';
  }

  @override
  String insufficientStockError(Object stock) {
    return 'Insufficient stock. Current: $stock';
  }

  @override
  String get saleReason => 'Sale';

  @override
  String get refundStockRestore => 'Refund stock restore';

  @override
  String get partialRefundStockRestore => 'Partial refund stock restore';

  @override
  String get reportSheetSummary => 'Summary';

  @override
  String get reportTitle => 'Oda POS Sales Report';

  @override
  String reportPeriod(Object from, Object to) {
    return 'Period: $from ~ $to';
  }

  @override
  String get reportItem => 'Item';

  @override
  String get reportValue => 'Value';

  @override
  String get reportTotalSales => 'Total Sales';

  @override
  String get reportOrderCount => 'Orders';

  @override
  String get reportAvgOrder => 'Avg. Order Amount';

  @override
  String get reportGrowthRate => 'Growth Rate (%)';

  @override
  String get reportSheetDaily => 'Daily Sales';

  @override
  String get reportDate => 'Date';

  @override
  String get reportSales => 'Sales';

  @override
  String get reportSheetPayment => 'By Payment Method';

  @override
  String get reportSheetProduct => 'Product Sales';

  @override
  String get reportRank => 'Rank';

  @override
  String get reportQuantitySold => 'Qty Sold';

  @override
  String get employeeInfoEdit =>
      'Edit employee info. Enter a new 4-digit number to change PIN.';

  @override
  String get employeeInfoNew =>
      'A new employee will be created. They can log in using the PIN.';

  @override
  String get barcode => 'Barcode';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryBeverage => 'Beverage';

  @override
  String get categoryElectronics => 'Electronics';

  @override
  String get categoryDaily => 'Daily Goods';

  @override
  String get kdsTitle => 'Kitchen Display System';

  @override
  String get kdsCompleted => 'Completed';

  @override
  String get kdsInProgress => 'In Progress';

  @override
  String get kdsAverage => 'Average';

  @override
  String kdsMinutes(Object count, Object seconds) {
    return '${count}min ${seconds}sec';
  }

  @override
  String kdsOrdersCount(Object count) {
    return '$count orders';
  }

  @override
  String get kdsStatusPending => 'Pending';

  @override
  String get kdsStatusPreparing => 'Preparing';

  @override
  String get kdsStatusReady => 'Ready';

  @override
  String get kdsStatusServed => 'Served';

  @override
  String get kdsStatusCancelled => 'Cancelled';

  @override
  String get kdsPriorityNormal => 'Normal';

  @override
  String get kdsPriorityUrgent => 'Urgent';

  @override
  String get kdsFilterAll => 'All';

  @override
  String get kdsFilterPending => 'Pending';

  @override
  String get kdsFilterPreparing => 'Preparing';

  @override
  String get kdsFilterReady => 'Ready';

  @override
  String get kdsNoOrders => 'No orders';

  @override
  String kdsErrorOccurred(Object error) {
    return 'Error occurred: $error';
  }

  @override
  String kdsTakeout(Object id) {
    return 'Takeout #$id';
  }

  @override
  String get kdsOrderTime => 'Order Time';

  @override
  String get kdsStatus => 'Status';

  @override
  String get kdsPriority => 'Priority';

  @override
  String get kdsSpecialRequest => 'Special Request';

  @override
  String get kdsProcessingHistory => 'Processing History';

  @override
  String get kdsCancelOrder => 'Cancel Order';

  @override
  String get kdsCancelOrderConfirm =>
      'Are you sure you want to cancel this order?';

  @override
  String get kdsOrderReceived => 'Order Received';

  @override
  String get kdsPreparationStarted => 'Preparation Started';

  @override
  String get kdsPreparationComplete => 'Preparation Complete';

  @override
  String get kdsServingComplete => 'Serving Complete';

  @override
  String get kdsOrderCancelled => 'Order Cancelled';

  @override
  String get kdsStartPreparation => 'Start Preparation';

  @override
  String get kdsMarkAsReady => 'Mark as Ready';

  @override
  String get kdsMarkAsServed => 'Mark as Served';

  @override
  String kdsElapsedMinutes(Object minutes) {
    return '$minutes min elapsed';
  }

  @override
  String get kdsTableNumber => 'Table Number';

  @override
  String get kdsSpecialInstructions => 'Special Instructions';

  @override
  String get dailyClosing => 'Daily Closing';

  @override
  String get closingHistory => 'Closing History';

  @override
  String get closingSummary => 'Closing Summary';

  @override
  String get selectClosingDate => 'Select Closing Date';

  @override
  String get selectDate => 'Select Date';

  @override
  String get salesAggregation => 'Sales Aggregation';

  @override
  String get totalTransactions => 'Total Transactions';

  @override
  String transactionsCount(int count) {
    return '$count transactions';
  }

  @override
  String get cashCount => 'Cash Count';

  @override
  String get expectedCash => 'Expected Cash';

  @override
  String get actualCash => 'Actual Cash';

  @override
  String get cashDifference => 'Cash Difference';

  @override
  String get enterActualCash => 'Enter Actual Cash';

  @override
  String get actualCashHint => 'Enter the actual cash amount';

  @override
  String get cashDifferenceAcceptable => 'Exceeds acceptable range (±\$10)';

  @override
  String get specialNotes => 'Special Notes';

  @override
  String get notesPlaceholder => 'Enter any special notes';

  @override
  String get performClosing => 'Perform Closing';

  @override
  String get skipCashCount => 'Close Without Cash Count';

  @override
  String get closingComplete => 'Closing completed successfully';

  @override
  String get closingFailed => 'An error occurred during closing';

  @override
  String get loadingClosingData => 'Loading closing data...';

  @override
  String get noClosingHistory => 'No closing history';

  @override
  String get loadClosingHistoryFailed => 'Unable to load closing history';

  @override
  String get tryAgainLater => 'Please try again later';

  @override
  String get selectPeriod => 'Select Period';

  @override
  String get viewDetails => 'View Details';

  @override
  String get generatePdf => 'Generate PDF';

  @override
  String savePdfQuestion(String reportName) {
    return 'Would you like to save $reportName as PDF?';
  }

  @override
  String get generate => 'Generate';

  @override
  String editActualCash(String label) {
    return 'Edit $label';
  }

  @override
  String get closingDetails => 'Closing Details';

  @override
  String get closingTime => 'Closing Time';

  @override
  String get assignedEmployee => 'Assigned Employee';

  @override
  String get unknown => 'Unknown';

  @override
  String get averageTransaction => 'Average Transaction';

  @override
  String get taxTotal => 'Total Tax';

  @override
  String get discountTotal => 'Total Discount';

  @override
  String get normalCashDifference => 'Within Range';

  @override
  String pdfSaved(String path) {
    return 'PDF saved: $path';
  }

  @override
  String pdfGenerationFailed(String error) {
    return 'PDF generation failed: $error';
  }

  @override
  String get alreadyClosed => 'This date has already been closed';

  @override
  String get cannotCloseFutureDate => 'Cannot close future dates';

  @override
  String get noSalesForDate => 'No sales found for this date';

  @override
  String get loginRequired => 'Login required';

  @override
  String get closingProcessError =>
      'An error occurred during closing. Please try again later';

  @override
  String get dailyClosingReport => 'Daily Closing Report';

  @override
  String get closingInfo => 'Closing Information';

  @override
  String get closingDate => 'Closing Date';

  @override
  String get paymentMethodBreakdown => 'Payment Method Breakdown';

  @override
  String get qrPaymentSales => 'QR Payment';

  @override
  String get transferSales => 'Transfer';

  @override
  String get cashReconciliation => 'Cash Reconciliation';

  @override
  String get signatureSection => 'Signatures';

  @override
  String get closingManager => 'Closing Manager';

  @override
  String get verifier => 'Verifier';

  @override
  String get signature => 'Signature';

  @override
  String get userGuide => 'User Guide';

  @override
  String get tutorial => 'Tutorial';

  @override
  String get tutorialSkip => 'Skip';

  @override
  String get tutorialNext => 'Next';

  @override
  String get tutorialPrevious => 'Previous';

  @override
  String get tutorialFinish => 'Finish';

  @override
  String get tutorialDontShowAgain => 'Don\'t show again';

  @override
  String get tutorial_daily_closing_welcome_title => 'Welcome to Daily Closing';

  @override
  String get tutorial_daily_closing_welcome_desc =>
      'Use Daily Closing to reconcile and record your daily sales. Let\'s start with a quick guide.';

  @override
  String get tutorial_daily_closing_date_title => 'Select Closing Date';

  @override
  String get tutorial_daily_closing_date_desc =>
      'Tap here to select the date you want to close. Today\'s date is selected by default.';

  @override
  String get tutorial_daily_closing_summary_title => 'Sales Summary';

  @override
  String get tutorial_daily_closing_summary_desc =>
      'This card shows total transactions, total sales, average transaction, taxes, and discounts.';

  @override
  String get tutorial_daily_closing_payment_title => 'Payment Method Breakdown';

  @override
  String get tutorial_daily_closing_payment_desc =>
      'View sales breakdown by payment method: cash, card, QR payment, and transfer.';

  @override
  String get tutorial_daily_closing_cash_title => 'Cash Reconciliation';

  @override
  String get tutorial_daily_closing_cash_desc =>
      'Compare expected cash sales with actual cash count to verify differences.';

  @override
  String get tutorial_daily_closing_actual_cash_title => 'Enter Actual Cash';

  @override
  String get tutorial_daily_closing_actual_cash_desc =>
      'Tap this button to enter the actual cash amount you counted. The system will verify if the difference is within acceptable range.';

  @override
  String get tutorial_daily_closing_notes_title => 'Record Special Notes';

  @override
  String get tutorial_daily_closing_notes_desc =>
      'You can add notes about special occurrences during closing, such as refunds or shortages.';

  @override
  String get tutorial_daily_closing_perform_title => 'Perform Closing';

  @override
  String get tutorial_daily_closing_perform_desc =>
      'After verifying all information, tap this button to complete the closing. Note: Closing cannot be undone.';

  @override
  String get tutorial_daily_closing_history_title => 'Closing History';

  @override
  String get tutorial_daily_closing_history_desc =>
      'View previous closing records and download them as PDF reports.';

  @override
  String get reservations => 'Reservations';

  @override
  String get addReservation => 'Add Reservation';

  @override
  String get reservationDetail => 'Reservation Detail';

  @override
  String get deleteReservation => 'Delete Reservation';

  @override
  String deleteReservationConfirm(String customer) {
    return 'Are you sure you want to delete the reservation for $customer?';
  }

  @override
  String get reservationDeleted => 'Reservation deleted';

  @override
  String get noReservations => 'No reservations';

  @override
  String reservationStatusChanged(String status) {
    return 'Reservation status changed to $status';
  }

  @override
  String get reservationPending => 'Pending';

  @override
  String get reservationConfirmed => 'Confirmed';

  @override
  String get reservationSeated => 'Seated';

  @override
  String get reservationCancelled => 'Cancelled';

  @override
  String get reservationNoShow => 'No Show';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get pending => 'Pending';

  @override
  String get customerName => 'Customer Name';

  @override
  String get customerPhone => 'Contact';

  @override
  String get partySize => 'Party Size';

  @override
  String get table => 'Table';

  @override
  String partySizePeople(int count) {
    return '$count people';
  }

  @override
  String get reservationDate => 'Reservation Date';

  @override
  String get reservationTime => 'Reservation Time';

  @override
  String get specialRequests => 'Special Requests';

  @override
  String get specialRequestsOptional => 'Special Requests (Optional)';

  @override
  String get createdAt => 'Created At';

  @override
  String get allReservations => 'All';

  @override
  String errorOccurredWithMessage(String message) {
    return 'Error occurred: $message';
  }

  @override
  String get editReservation => 'Edit Reservation';

  @override
  String get customerNameRequired => 'Please enter customer name';

  @override
  String get customerPhoneRequired => 'Please enter contact number';

  @override
  String get partySizeRequired => 'Please enter party size';

  @override
  String get partySizeInvalid => 'Party size must be at least 1';

  @override
  String get people => 'people';
}

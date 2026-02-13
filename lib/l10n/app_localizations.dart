import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Oda POS'**
  String get appName;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get noData;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @customPeriod.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customPeriod;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @navPos.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get navPos;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get navSales;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get navInventory;

  /// No description provided for @navEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get navEmployees;

  /// No description provided for @navPromotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get navPromotions;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navTables.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get navTables;

  /// No description provided for @navRefunds.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get navRefunds;

  /// No description provided for @navCashDrawer.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get navCashDrawer;

  /// No description provided for @navKds.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get navKds;

  /// No description provided for @navDailyClosing.
  ///
  /// In en, this message translates to:
  /// **'Daily Closing'**
  String get navDailyClosing;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @clearCart.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearCart;

  /// No description provided for @addDiscount.
  ///
  /// In en, this message translates to:
  /// **'Add Discount'**
  String get addDiscount;

  /// No description provided for @applyPromotion.
  ///
  /// In en, this message translates to:
  /// **'Apply Promotion'**
  String get applyPromotion;

  /// No description provided for @autoPromotionsApplied.
  ///
  /// In en, this message translates to:
  /// **'Auto Promotions Applied'**
  String get autoPromotionsApplied;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// No description provided for @addProductsPlease.
  ///
  /// In en, this message translates to:
  /// **'Add products to cart'**
  String get addProductsPlease;

  /// No description provided for @payAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String payAmount(Object amount);

  /// No description provided for @discountSettings.
  ///
  /// In en, this message translates to:
  /// **'Discount Settings'**
  String get discountSettings;

  /// No description provided for @promotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get promotion;

  /// No description provided for @paymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Payment Amount'**
  String get paymentAmount;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemCount(Object count);

  /// No description provided for @appliedProducts.
  ///
  /// In en, this message translates to:
  /// **'Select Products'**
  String get appliedProducts;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @productPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get productPrice;

  /// No description provided for @productStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get productStock;

  /// No description provided for @productCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get productCategory;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @productManagement.
  ///
  /// In en, this message translates to:
  /// **'Product Management'**
  String get productManagement;

  /// No description provided for @noProducts.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProducts;

  /// No description provided for @searchProductHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, SKU, barcode...'**
  String get searchProductHint;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'{name} added to cart'**
  String addedToCart(Object name);

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'{name} is out of stock'**
  String outOfStock(Object name);

  /// No description provided for @outOfStockBadge.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStockBadge;

  /// No description provided for @lowStockBadge.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStockBadge;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'[{input}] Product not found'**
  String productNotFound(Object input);

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @qr.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qr;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @cashReceived.
  ///
  /// In en, this message translates to:
  /// **'Cash Received'**
  String get cashReceived;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @paymentComplete.
  ///
  /// In en, this message translates to:
  /// **'Payment Complete'**
  String get paymentComplete;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// No description provided for @cashInputAmount.
  ///
  /// In en, this message translates to:
  /// **'Cash Amount'**
  String get cashInputAmount;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @noEmployeeLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'No employee logged in'**
  String get noEmployeeLoggedIn;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment Failed'**
  String get paymentFailed;

  /// No description provided for @receiptNumber.
  ///
  /// In en, this message translates to:
  /// **'Receipt #'**
  String get receiptNumber;

  /// No description provided for @receiptDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get receiptDate;

  /// No description provided for @receiptItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get receiptItems;

  /// No description provided for @receiptThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your purchase!'**
  String get receiptThankYou;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsExchangeRate.
  ///
  /// In en, this message translates to:
  /// **'Exchange Rate'**
  String get settingsExchangeRate;

  /// No description provided for @settingsSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get settingsSelectLanguage;

  /// No description provided for @settingsSelectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get settingsSelectCurrency;

  /// No description provided for @localeSettings.
  ///
  /// In en, this message translates to:
  /// **'Language & Currency'**
  String get localeSettings;

  /// No description provided for @storeInfo.
  ///
  /// In en, this message translates to:
  /// **'Store Information'**
  String get storeInfo;

  /// No description provided for @storeName.
  ///
  /// In en, this message translates to:
  /// **'Store Name'**
  String get storeName;

  /// No description provided for @storePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get storePhone;

  /// No description provided for @storeAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get storeAddress;

  /// No description provided for @receiptSettings.
  ///
  /// In en, this message translates to:
  /// **'Receipt Settings'**
  String get receiptSettings;

  /// No description provided for @footerMessage.
  ///
  /// In en, this message translates to:
  /// **'Footer Message'**
  String get footerMessage;

  /// No description provided for @footerDefault.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get footerDefault;

  /// No description provided for @showQrCode.
  ///
  /// In en, this message translates to:
  /// **'Show QR Code'**
  String get showQrCode;

  /// No description provided for @appInfo.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get appInfo;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @database.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get database;

  /// No description provided for @syncMode.
  ///
  /// In en, this message translates to:
  /// **'Sync Mode'**
  String get syncMode;

  /// No description provided for @offlineFirst.
  ///
  /// In en, this message translates to:
  /// **'Offline-First'**
  String get offlineFirst;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirm;

  /// No description provided for @langKorean.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get langKorean;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get langVietnamese;

  /// No description provided for @currencyUSD.
  ///
  /// In en, this message translates to:
  /// **'US Dollar (\$)'**
  String get currencyUSD;

  /// No description provided for @currencyVND.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese Dong (₫)'**
  String get currencyVND;

  /// No description provided for @employeeManagement.
  ///
  /// In en, this message translates to:
  /// **'Employee Management'**
  String get employeeManagement;

  /// No description provided for @employeeLogin.
  ///
  /// In en, this message translates to:
  /// **'Employee Login'**
  String get employeeLogin;

  /// No description provided for @selectEmployee.
  ///
  /// In en, this message translates to:
  /// **'Select Employee'**
  String get selectEmployee;

  /// No description provided for @enterPinCode.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN Code'**
  String get enterPinCode;

  /// No description provided for @noEmployeesRegistered.
  ///
  /// In en, this message translates to:
  /// **'No employees registered'**
  String get noEmployeesRegistered;

  /// No description provided for @forgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot your PIN? Contact manager'**
  String get forgotPin;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailed(String error);

  /// No description provided for @employeeName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get employeeName;

  /// No description provided for @employeeRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get employeeRole;

  /// No description provided for @employeeUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get employeeUsername;

  /// No description provided for @employeePin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get employeePin;

  /// No description provided for @addEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get addEmployee;

  /// No description provided for @editEmployee.
  ///
  /// In en, this message translates to:
  /// **'Edit Employee'**
  String get editEmployee;

  /// No description provided for @noEmployees.
  ///
  /// In en, this message translates to:
  /// **'No employees found'**
  String get noEmployees;

  /// No description provided for @employeeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load employee list'**
  String get employeeLoadError;

  /// No description provided for @employeeAdded.
  ///
  /// In en, this message translates to:
  /// **'New employee added'**
  String get employeeAdded;

  /// No description provided for @employeeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Employee info updated'**
  String get employeeUpdated;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username (Login ID)'**
  String get usernameLabel;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. john_doe'**
  String get usernameHint;

  /// No description provided for @usernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter username'**
  String get usernameRequired;

  /// No description provided for @usernameMinLength.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get usernameMinLength;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. John Doe'**
  String get nameHint;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter name'**
  String get nameRequired;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @roleCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get roleCashier;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get roleKitchen;

  /// No description provided for @pinChangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Change PIN (optional)'**
  String get pinChangeLabel;

  /// No description provided for @pinNewLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN (4 digits)'**
  String get pinNewLabel;

  /// No description provided for @pinHint.
  ///
  /// In en, this message translates to:
  /// **'1234'**
  String get pinHint;

  /// No description provided for @pinNoChangeHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to keep current PIN'**
  String get pinNoChangeHelper;

  /// No description provided for @pinNewHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter 4 digits'**
  String get pinNewHelper;

  /// No description provided for @pinRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter PIN'**
  String get pinRequired;

  /// No description provided for @pinLengthError.
  ///
  /// In en, this message translates to:
  /// **'PIN must be 4 digits'**
  String get pinLengthError;

  /// No description provided for @pinDigitsOnly.
  ///
  /// In en, this message translates to:
  /// **'PIN must contain only numbers'**
  String get pinDigitsOnly;

  /// No description provided for @promotionManagement.
  ///
  /// In en, this message translates to:
  /// **'Promotion Management'**
  String get promotionManagement;

  /// No description provided for @promotionName.
  ///
  /// In en, this message translates to:
  /// **'Promotion Name'**
  String get promotionName;

  /// No description provided for @promotionType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get promotionType;

  /// No description provided for @promotionValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get promotionValue;

  /// No description provided for @addPromotion.
  ///
  /// In en, this message translates to:
  /// **'Add Promotion'**
  String get addPromotion;

  /// No description provided for @editPromotion.
  ///
  /// In en, this message translates to:
  /// **'Edit Promotion'**
  String get editPromotion;

  /// No description provided for @noPromotions.
  ///
  /// In en, this message translates to:
  /// **'No promotions found'**
  String get noPromotions;

  /// No description provided for @deletePromotion.
  ///
  /// In en, this message translates to:
  /// **'Delete Promotion'**
  String get deletePromotion;

  /// No description provided for @deletePromotionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deletePromotionConfirm(Object name);

  /// No description provided for @promotionNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Promotion Name'**
  String get promotionNameLabel;

  /// No description provided for @promotionNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Orange Juice BOGO'**
  String get promotionNameHint;

  /// No description provided for @promotionNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter promotion name'**
  String get promotionNameRequired;

  /// No description provided for @promotionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Promotion Type'**
  String get promotionTypeLabel;

  /// No description provided for @typeBogo.
  ///
  /// In en, this message translates to:
  /// **'Buy 1 Get 1 Free'**
  String get typeBogo;

  /// No description provided for @typeBuy2Get1.
  ///
  /// In en, this message translates to:
  /// **'Buy 2 Get 1 Free'**
  String get typeBuy2Get1;

  /// No description provided for @typePercentOff.
  ///
  /// In en, this message translates to:
  /// **'Percent Off'**
  String get typePercentOff;

  /// No description provided for @typeAmountOff.
  ///
  /// In en, this message translates to:
  /// **'Amount Off'**
  String get typeAmountOff;

  /// No description provided for @discountRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount Rate (%)'**
  String get discountRateLabel;

  /// No description provided for @discountAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount Amount'**
  String get discountAmountLabel;

  /// No description provided for @discountValueHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 10'**
  String get discountValueHint;

  /// No description provided for @discountAmountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1000'**
  String get discountAmountHint;

  /// No description provided for @discountValueRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter discount value'**
  String get discountValueRequired;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get invalidNumber;

  /// No description provided for @maxDiscountRate.
  ///
  /// In en, this message translates to:
  /// **'Discount rate cannot exceed 100%'**
  String get maxDiscountRate;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @targetProduct.
  ///
  /// In en, this message translates to:
  /// **'Target Product (optional)'**
  String get targetProduct;

  /// No description provided for @allProducts.
  ///
  /// In en, this message translates to:
  /// **'All Products'**
  String get allProducts;

  /// No description provided for @productLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products'**
  String get productLoadFailed;

  /// No description provided for @noSelection.
  ///
  /// In en, this message translates to:
  /// **'No Selection'**
  String get noSelection;

  /// No description provided for @bogoLabel.
  ///
  /// In en, this message translates to:
  /// **'Buy 1 Get 1'**
  String get bogoLabel;

  /// No description provided for @buy2Get1Label.
  ///
  /// In en, this message translates to:
  /// **'Buy 2 Get 1'**
  String get buy2Get1Label;

  /// No description provided for @percentOffLabel.
  ///
  /// In en, this message translates to:
  /// **'% Off'**
  String get percentOffLabel;

  /// No description provided for @amountOffLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount Off'**
  String get amountOffLabel;

  /// No description provided for @freeOne.
  ///
  /// In en, this message translates to:
  /// **'1 Free'**
  String get freeOne;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @todaySales.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Sales'**
  String get todaySales;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @topProducts.
  ///
  /// In en, this message translates to:
  /// **'Top Products'**
  String get topProducts;

  /// No description provided for @salesDashboard.
  ///
  /// In en, this message translates to:
  /// **'Sales Dashboard'**
  String get salesDashboard;

  /// No description provided for @paymentMethodSales.
  ///
  /// In en, this message translates to:
  /// **'Sales by Payment Method'**
  String get paymentMethodSales;

  /// No description provided for @productRanking.
  ///
  /// In en, this message translates to:
  /// **'Product Sales Ranking'**
  String get productRanking;

  /// No description provided for @totalSalesAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get totalSalesAmount;

  /// No description provided for @totalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get totalSales;

  /// No description provided for @orderCount.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orderCount;

  /// No description provided for @orderUnit.
  ///
  /// In en, this message translates to:
  /// **'orders'**
  String get orderUnit;

  /// No description provided for @avgOrderAmount.
  ///
  /// In en, this message translates to:
  /// **'Avg. Order Amount'**
  String get avgOrderAmount;

  /// No description provided for @inventoryValue.
  ///
  /// In en, this message translates to:
  /// **'Inventory Value'**
  String get inventoryValue;

  /// No description provided for @inventoryValueDesc.
  ///
  /// In en, this message translates to:
  /// **'Total value of current inventory'**
  String get inventoryValueDesc;

  /// No description provided for @noSalesData.
  ///
  /// In en, this message translates to:
  /// **'No sales data'**
  String get noSalesData;

  /// No description provided for @soldCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sold'**
  String soldCount(Object count);

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error occurred: {error}'**
  String errorOccurred(String error);

  /// No description provided for @salesHistory.
  ///
  /// In en, this message translates to:
  /// **'Sales History'**
  String get salesHistory;

  /// No description provided for @noSalesHistory.
  ///
  /// In en, this message translates to:
  /// **'No sales records'**
  String get noSalesHistory;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total {amount}'**
  String totalAmount(Object amount);

  /// No description provided for @refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refunded;

  /// No description provided for @dateMonth.
  ///
  /// In en, this message translates to:
  /// **'{month}/{day}'**
  String dateMonth(Object day, Object month);

  /// No description provided for @lowStockAlert.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Alert'**
  String get lowStockAlert;

  /// No description provided for @allStockSufficient.
  ///
  /// In en, this message translates to:
  /// **'All products have sufficient stock'**
  String get allStockSufficient;

  /// No description provided for @aboveMinStock.
  ///
  /// In en, this message translates to:
  /// **'Stock levels are above minimum'**
  String get aboveMinStock;

  /// No description provided for @addStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Stock: {name}'**
  String addStockTitle(Object name);

  /// No description provided for @currentStock.
  ///
  /// In en, this message translates to:
  /// **'Current: {current} / Min: {min}'**
  String currentStock(Object current, Object min);

  /// No description provided for @addStock.
  ///
  /// In en, this message translates to:
  /// **'Add Stock'**
  String get addStock;

  /// No description provided for @stockReplenishReason.
  ///
  /// In en, this message translates to:
  /// **'Stock replenishment (low stock alert)'**
  String get stockReplenishReason;

  /// No description provided for @stockAddedMsg.
  ///
  /// In en, this message translates to:
  /// **'Added {qty} units of {name}'**
  String stockAddedMsg(Object name, Object qty);

  /// No description provided for @outOfStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStockLabel;

  /// No description provided for @lowStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowStockLabel;

  /// No description provided for @currentStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Stock'**
  String get currentStockLabel;

  /// No description provided for @minStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Min Stock'**
  String get minStockLabel;

  /// No description provided for @needReplenish.
  ///
  /// In en, this message translates to:
  /// **'Need Replenish'**
  String get needReplenish;

  /// No description provided for @salesReport.
  ///
  /// In en, this message translates to:
  /// **'Sales Report'**
  String get salesReport;

  /// No description provided for @salesTrend.
  ///
  /// In en, this message translates to:
  /// **'Sales Trend'**
  String get salesTrend;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get exportExcel;

  /// No description provided for @excelSaved.
  ///
  /// In en, this message translates to:
  /// **'Excel saved: {path}'**
  String excelSaved(Object path);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(Object error);

  /// No description provided for @customerManagement.
  ///
  /// In en, this message translates to:
  /// **'Customer Management'**
  String get customerManagement;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add Customer'**
  String get addCustomer;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomer;

  /// No description provided for @searchCustomerHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, phone, email...'**
  String get searchCustomerHint;

  /// No description provided for @noCustomers.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get noCustomers;

  /// No description provided for @noSearchResult.
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get noSearchResult;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @earnPoints.
  ///
  /// In en, this message translates to:
  /// **'Earn'**
  String get earnPoints;

  /// No description provided for @usePoints.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get usePoints;

  /// No description provided for @purchaseHistory.
  ///
  /// In en, this message translates to:
  /// **'Purchase History'**
  String get purchaseHistory;

  /// No description provided for @noPurchaseHistory.
  ///
  /// In en, this message translates to:
  /// **'No purchase history'**
  String get noPurchaseHistory;

  /// No description provided for @earnPointsTitle.
  ///
  /// In en, this message translates to:
  /// **'Earn Points'**
  String get earnPointsTitle;

  /// No description provided for @usePointsTitle.
  ///
  /// In en, this message translates to:
  /// **'Use Points'**
  String get usePointsTitle;

  /// No description provided for @pointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get pointsLabel;

  /// No description provided for @earnPointsHint.
  ///
  /// In en, this message translates to:
  /// **'Points to earn'**
  String get earnPointsHint;

  /// No description provided for @usePointsHint.
  ///
  /// In en, this message translates to:
  /// **'Points to use (balance: {points}P)'**
  String usePointsHint(Object points);

  /// No description provided for @customerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get customerNameLabel;

  /// No description provided for @customerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get customerPhoneLabel;

  /// No description provided for @customerEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get customerEmailLabel;

  /// No description provided for @customerNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get customerNoteLabel;

  /// No description provided for @tableManagement.
  ///
  /// In en, this message translates to:
  /// **'Table Management'**
  String get tableManagement;

  /// No description provided for @tableLayout.
  ///
  /// In en, this message translates to:
  /// **'Table Layout'**
  String get tableLayout;

  /// No description provided for @reservationManagement.
  ///
  /// In en, this message translates to:
  /// **'Reservation Management'**
  String get reservationManagement;

  /// No description provided for @addTable.
  ///
  /// In en, this message translates to:
  /// **'Add Table'**
  String get addTable;

  /// No description provided for @noTables.
  ///
  /// In en, this message translates to:
  /// **'No tables available'**
  String get noTables;

  /// No description provided for @noTablesFiltered.
  ///
  /// In en, this message translates to:
  /// **'No tables with this status'**
  String get noTablesFiltered;

  /// No description provided for @emptyTables.
  ///
  /// In en, this message translates to:
  /// **'Empty Tables'**
  String get emptyTables;

  /// No description provided for @occupiedTables.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get occupiedTables;

  /// No description provided for @allTables.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allTables;

  /// No description provided for @tableAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get tableAvailable;

  /// No description provided for @tableOccupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get tableOccupied;

  /// No description provided for @tableReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get tableReserved;

  /// No description provided for @tableSeated.
  ///
  /// In en, this message translates to:
  /// **'Seated'**
  String get tableSeated;

  /// No description provided for @tablePaymentComplete.
  ///
  /// In en, this message translates to:
  /// **'Payment Complete'**
  String get tablePaymentComplete;

  /// No description provided for @tableCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get tableCleaning;

  /// No description provided for @tableNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Table Name *'**
  String get tableNameLabel;

  /// No description provided for @tableNumber.
  ///
  /// In en, this message translates to:
  /// **'Table Number'**
  String get tableNumber;

  /// No description provided for @tableNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1, A1, VIP-1'**
  String get tableNumberHint;

  /// No description provided for @tableNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter table number'**
  String get tableNumberRequired;

  /// No description provided for @tableAdded.
  ///
  /// In en, this message translates to:
  /// **'Table {number} added'**
  String tableAdded(String number);

  /// No description provided for @editTable.
  ///
  /// In en, this message translates to:
  /// **'Edit Table {number}'**
  String editTable(String number);

  /// No description provided for @deleteTable.
  ///
  /// In en, this message translates to:
  /// **'Delete Table'**
  String get deleteTable;

  /// No description provided for @deleteTableConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete table {number}?'**
  String deleteTableConfirm(String number);

  /// No description provided for @tableDeleted.
  ///
  /// In en, this message translates to:
  /// **'Table {number} deleted'**
  String tableDeleted(String number);

  /// No description provided for @tableUpdated.
  ///
  /// In en, this message translates to:
  /// **'Table {number} updated'**
  String tableUpdated(String number);

  /// No description provided for @tableNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Table 1, A-1'**
  String get tableNameHint;

  /// No description provided for @seatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get seatsLabel;

  /// No description provided for @seatsCount.
  ///
  /// In en, this message translates to:
  /// **'Seats'**
  String get seatsCount;

  /// No description provided for @zoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get zoneLabel;

  /// No description provided for @zoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Hall, Terrace, Room'**
  String get zoneHint;

  /// No description provided for @startUse.
  ///
  /// In en, this message translates to:
  /// **'Start Use'**
  String get startUse;

  /// No description provided for @reserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve'**
  String get reserve;

  /// No description provided for @clearTable.
  ///
  /// In en, this message translates to:
  /// **'Clear (Done)'**
  String get clearTable;

  /// No description provided for @moveTable.
  ///
  /// In en, this message translates to:
  /// **'Move Table'**
  String get moveTable;

  /// No description provided for @reserveToUse.
  ///
  /// In en, this message translates to:
  /// **'Reserved → Start'**
  String get reserveToUse;

  /// No description provided for @clearTableShort.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearTableShort;

  /// No description provided for @moveTableTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} → Move'**
  String moveTableTitle(Object name);

  /// No description provided for @noEmptyTables.
  ///
  /// In en, this message translates to:
  /// **'No empty tables available.'**
  String get noEmptyTables;

  /// No description provided for @seatsUnit.
  ///
  /// In en, this message translates to:
  /// **'{count} seats'**
  String seatsUnit(Object count);

  /// No description provided for @refundManagement.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get refundManagement;

  /// No description provided for @searchByReceipt.
  ///
  /// In en, this message translates to:
  /// **'Search by Receipt #'**
  String get searchByReceipt;

  /// No description provided for @receiptNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter receipt # (e.g. ODA-20250207-001)'**
  String get receiptNumberHint;

  /// No description provided for @refundedStatus.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refundedStatus;

  /// No description provided for @paidStatus.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidStatus;

  /// No description provided for @selectRefundItems.
  ///
  /// In en, this message translates to:
  /// **'Select Refund Items'**
  String get selectRefundItems;

  /// No description provided for @refundReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Refund Reason'**
  String get refundReasonLabel;

  /// No description provided for @refundReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Enter refund reason'**
  String get refundReasonHint;

  /// No description provided for @partialRefund.
  ///
  /// In en, this message translates to:
  /// **'Partial Refund ({amount})'**
  String partialRefund(Object amount);

  /// No description provided for @fullRefund.
  ///
  /// In en, this message translates to:
  /// **'Full Refund'**
  String get fullRefund;

  /// No description provided for @alreadyRefunded.
  ///
  /// In en, this message translates to:
  /// **'This order has already been refunded.'**
  String get alreadyRefunded;

  /// No description provided for @todayRefundHistory.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Refunds'**
  String get todayRefundHistory;

  /// No description provided for @noRefundToday.
  ///
  /// In en, this message translates to:
  /// **'No refunds today'**
  String get noRefundToday;

  /// No description provided for @fullRefundType.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get fullRefundType;

  /// No description provided for @partialRefundType.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partialRefundType;

  /// No description provided for @receiptNotFound.
  ///
  /// In en, this message translates to:
  /// **'Receipt not found'**
  String get receiptNotFound;

  /// No description provided for @fullRefundComplete.
  ///
  /// In en, this message translates to:
  /// **'Full refund complete'**
  String get fullRefundComplete;

  /// No description provided for @partialRefundComplete.
  ///
  /// In en, this message translates to:
  /// **'Partial refund complete'**
  String get partialRefundComplete;

  /// No description provided for @refundConfirm.
  ///
  /// In en, this message translates to:
  /// **'Proceed with {amount} refund?'**
  String refundConfirm(Object amount);

  /// No description provided for @refundAction.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refundAction;

  /// No description provided for @cashDrawerManagement.
  ///
  /// In en, this message translates to:
  /// **'Cash Drawer'**
  String get cashDrawerManagement;

  /// No description provided for @currentCashDrawer.
  ///
  /// In en, this message translates to:
  /// **'Current Drawer'**
  String get currentCashDrawer;

  /// No description provided for @openStatus.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openStatus;

  /// No description provided for @closedStatus.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedStatus;

  /// No description provided for @openDrawer.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openDrawer;

  /// No description provided for @closeDrawer.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeDrawer;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @sale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get sale;

  /// No description provided for @todayTransactions.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Transactions'**
  String get todayTransactions;

  /// No description provided for @noTransactionsToday.
  ///
  /// In en, this message translates to:
  /// **'No transactions today'**
  String get noTransactionsToday;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance {amount}'**
  String balance(Object amount);

  /// No description provided for @cashDrawerOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get cashDrawerOpen;

  /// No description provided for @cashDrawerClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get cashDrawerClose;

  /// No description provided for @cashDrawerDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get cashDrawerDeposit;

  /// No description provided for @cashDrawerWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get cashDrawerWithdraw;

  /// No description provided for @cashDrawerSale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get cashDrawerSale;

  /// No description provided for @cashDrawerRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get cashDrawerRefund;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @memoLabel.
  ///
  /// In en, this message translates to:
  /// **'Memo (optional)'**
  String get memoLabel;

  /// No description provided for @closeSettlement.
  ///
  /// In en, this message translates to:
  /// **'Close Settlement'**
  String get closeSettlement;

  /// No description provided for @systemBalance.
  ///
  /// In en, this message translates to:
  /// **'System Balance: {amount}'**
  String systemBalance(Object amount);

  /// No description provided for @actualCashAmount.
  ///
  /// In en, this message translates to:
  /// **'Actual Cash Amount'**
  String get actualCashAmount;

  /// No description provided for @countCashHint.
  ///
  /// In en, this message translates to:
  /// **'Count cash and enter amount'**
  String get countCashHint;

  /// No description provided for @normalClose.
  ///
  /// In en, this message translates to:
  /// **'Close Drawer'**
  String get normalClose;

  /// No description provided for @difference.
  ///
  /// In en, this message translates to:
  /// **'Diff: {amount}'**
  String difference(Object amount);

  /// No description provided for @closeComplete.
  ///
  /// In en, this message translates to:
  /// **'Closed. {note}'**
  String closeComplete(Object note);

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @pendingItems.
  ///
  /// In en, this message translates to:
  /// **'Pending Items'**
  String get pendingItems;

  /// No description provided for @pendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String pendingCount(Object count);

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last Sync'**
  String get lastSync;

  /// No description provided for @notYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get notYet;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @syncAutoMsg.
  ///
  /// In en, this message translates to:
  /// **'Auto-syncs every 5 minutes when connected'**
  String get syncAutoMsg;

  /// No description provided for @syncOfflineMsg.
  ///
  /// In en, this message translates to:
  /// **'All features work offline.\nAuto-syncs when connected.'**
  String get syncOfflineMsg;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{min} min ago'**
  String minutesAgo(Object min);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String hoursAgo(Object hours);

  /// No description provided for @offlineIndicator.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineIndicator;

  /// No description provided for @pinLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN to login'**
  String get pinLoginTitle;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get pinMismatch;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Login error: {error}'**
  String loginError(Object error);

  /// No description provided for @msgItemAdded.
  ///
  /// In en, this message translates to:
  /// **'Item added to cart'**
  String get msgItemAdded;

  /// No description provided for @msgPaymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get msgPaymentSuccess;

  /// No description provided for @msgPaymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get msgPaymentFailed;

  /// No description provided for @msgInsufficientStock.
  ///
  /// In en, this message translates to:
  /// **'Insufficient stock'**
  String get msgInsufficientStock;

  /// No description provided for @msgInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get msgInvalidAmount;

  /// No description provided for @msgSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get msgSaved;

  /// No description provided for @msgDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get msgDeleted;

  /// No description provided for @msgError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred: {error}'**
  String msgError(Object error);

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @cashPayment.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cashPayment;

  /// No description provided for @cardPayment.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get cardPayment;

  /// No description provided for @qrPayment.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrPayment;

  /// No description provided for @transferPayment.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferPayment;

  /// No description provided for @salesLabel.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get salesLabel;

  /// No description provided for @refundLabel.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refundLabel;

  /// No description provided for @excelManage.
  ///
  /// In en, this message translates to:
  /// **'Excel Manage'**
  String get excelManage;

  /// No description provided for @excelDownload.
  ///
  /// In en, this message translates to:
  /// **'Download as Excel'**
  String get excelDownload;

  /// No description provided for @excelDownloadDesc.
  ///
  /// In en, this message translates to:
  /// **'Export current product list'**
  String get excelDownloadDesc;

  /// No description provided for @excelUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload from Excel'**
  String get excelUpload;

  /// No description provided for @excelUploadDesc.
  ///
  /// In en, this message translates to:
  /// **'Add/update products via .xlsx'**
  String get excelUploadDesc;

  /// No description provided for @excelExporting.
  ///
  /// In en, this message translates to:
  /// **'Creating Excel file...'**
  String get excelExporting;

  /// No description provided for @excelSaveComplete.
  ///
  /// In en, this message translates to:
  /// **'Excel file saved!'**
  String get excelSaveComplete;

  /// No description provided for @excelSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save cancelled or failed. Please try again.'**
  String get excelSaveFailed;

  /// No description provided for @excelFileSave.
  ///
  /// In en, this message translates to:
  /// **'Save Excel File'**
  String get excelFileSave;

  /// No description provided for @excelFileSelect.
  ///
  /// In en, this message translates to:
  /// **'Select Excel File'**
  String get excelFileSelect;

  /// No description provided for @uploadComplete.
  ///
  /// In en, this message translates to:
  /// **'Upload Complete'**
  String get uploadComplete;

  /// No description provided for @newProductAdded.
  ///
  /// In en, this message translates to:
  /// **'New Products Added'**
  String get newProductAdded;

  /// No description provided for @existingProductUpdated.
  ///
  /// In en, this message translates to:
  /// **'Existing Products Updated'**
  String get existingProductUpdated;

  /// No description provided for @totalProcessed.
  ///
  /// In en, this message translates to:
  /// **'Total Processed'**
  String get totalProcessed;

  /// No description provided for @countUnit.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String countUnit(Object count);

  /// No description provided for @errorsOccurred.
  ///
  /// In en, this message translates to:
  /// **'⚠️ {count} errors occurred'**
  String errorsOccurred(Object count);

  /// No description provided for @productDeleted.
  ///
  /// In en, this message translates to:
  /// **'\'{name}\' has been deleted'**
  String productDeleted(Object name);

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(Object error);

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFound;

  /// No description provided for @sku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get sku;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @sellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get sellingPrice;

  /// No description provided for @costPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get costPrice;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @minStock.
  ///
  /// In en, this message translates to:
  /// **'Min Stock'**
  String get minStock;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @statusOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get statusOutOfStock;

  /// No description provided for @statusLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get statusLow;

  /// No description provided for @statusNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get statusNormal;

  /// No description provided for @piecesUnit.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String piecesUnit(Object count);

  /// No description provided for @stockAdjust.
  ///
  /// In en, this message translates to:
  /// **'Stock Adjust'**
  String get stockAdjust;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @productNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Product Name *'**
  String get productNameRequired;

  /// No description provided for @priceInfo.
  ///
  /// In en, this message translates to:
  /// **'Price Info'**
  String get priceInfo;

  /// No description provided for @sellingPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Selling Price *'**
  String get sellingPriceRequired;

  /// No description provided for @stockInfo.
  ///
  /// In en, this message translates to:
  /// **'Stock Info'**
  String get stockInfo;

  /// No description provided for @stockQuantity.
  ///
  /// In en, this message translates to:
  /// **'Stock Quantity'**
  String get stockQuantity;

  /// No description provided for @categoryHint.
  ///
  /// In en, this message translates to:
  /// **'Food, Beverage, Electronics, etc.'**
  String get categoryHint;

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product has been updated'**
  String get productUpdated;

  /// No description provided for @productAdded.
  ///
  /// In en, this message translates to:
  /// **'Product has been added'**
  String get productAdded;

  /// No description provided for @productImage.
  ///
  /// In en, this message translates to:
  /// **'Product Image'**
  String get productImage;

  /// No description provided for @noImage.
  ///
  /// In en, this message translates to:
  /// **'No image'**
  String get noImage;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @aiAutoSearch.
  ///
  /// In en, this message translates to:
  /// **'AI Auto Search'**
  String get aiAutoSearch;

  /// No description provided for @aiImageSearch.
  ///
  /// In en, this message translates to:
  /// **'AI Image Search'**
  String get aiImageSearch;

  /// No description provided for @aiImageSearchComplete.
  ///
  /// In en, this message translates to:
  /// **'AI Image Search Complete'**
  String get aiImageSearchComplete;

  /// No description provided for @imageUploaded.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded'**
  String get imageUploaded;

  /// No description provided for @deleteImage.
  ///
  /// In en, this message translates to:
  /// **'Delete Image'**
  String get deleteImage;

  /// No description provided for @deleteImageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to delete this image?'**
  String get deleteImageConfirm;

  /// No description provided for @imageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Image deleted'**
  String get imageDeleted;

  /// No description provided for @imageSetByAi.
  ///
  /// In en, this message translates to:
  /// **'Image set by AI search'**
  String get imageSetByAi;

  /// No description provided for @imageDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image download failed: {error}'**
  String imageDownloadFailed(String error);

  /// No description provided for @noProductsWithoutImage.
  ///
  /// In en, this message translates to:
  /// **'No products without images'**
  String get noProductsWithoutImage;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get searchFailed;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No search results'**
  String get noSearchResults;

  /// No description provided for @noImagesFound.
  ///
  /// In en, this message translates to:
  /// **'No images found for\n\"{product}\"'**
  String noImagesFound(String product);

  /// No description provided for @searchQuery.
  ///
  /// In en, this message translates to:
  /// **'Search: {query}'**
  String searchQuery(String query);

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @successRate.
  ///
  /// In en, this message translates to:
  /// **'Success Rate'**
  String get successRate;

  /// No description provided for @failedProducts.
  ///
  /// In en, this message translates to:
  /// **'Failed Products ({count})'**
  String failedProducts(int count);

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'unit'**
  String get unit;

  /// No description provided for @deleteProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProductTitle;

  /// No description provided for @deleteProductConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \'{name}\'?\nThis action cannot be undone.'**
  String deleteProductConfirm(Object name);

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #'**
  String get orderNumber;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @cashPaidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid Amount'**
  String get cashPaidAmount;

  /// No description provided for @thankYouMessage.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your purchase!'**
  String get thankYouMessage;

  /// No description provided for @newOrder.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get newOrder;

  /// No description provided for @receiptPrint.
  ///
  /// In en, this message translates to:
  /// **'Receipt Print'**
  String get receiptPrint;

  /// No description provided for @paperFormat.
  ///
  /// In en, this message translates to:
  /// **'Paper Format'**
  String get paperFormat;

  /// No description provided for @receiptFormat.
  ///
  /// In en, this message translates to:
  /// **'Receipt (80mm)'**
  String get receiptFormat;

  /// No description provided for @thermalPrinter.
  ///
  /// In en, this message translates to:
  /// **'For thermal printer'**
  String get thermalPrinter;

  /// No description provided for @a4Format.
  ///
  /// In en, this message translates to:
  /// **'A4'**
  String get a4Format;

  /// No description provided for @regularPrinter.
  ///
  /// In en, this message translates to:
  /// **'For regular printer'**
  String get regularPrinter;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @printing.
  ///
  /// In en, this message translates to:
  /// **'Printing...'**
  String get printing;

  /// No description provided for @receiptPreview.
  ///
  /// In en, this message translates to:
  /// **'Receipt Preview'**
  String get receiptPreview;

  /// No description provided for @receiptFileName.
  ///
  /// In en, this message translates to:
  /// **'Receipt_{saleNumber}.pdf'**
  String receiptFileName(Object saleNumber);

  /// No description provided for @printError.
  ///
  /// In en, this message translates to:
  /// **'Print error: {error}'**
  String printError(Object error);

  /// No description provided for @stockAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Stock Adjustment'**
  String get stockAdjustment;

  /// No description provided for @currentStockAmount.
  ///
  /// In en, this message translates to:
  /// **'Current Stock'**
  String get currentStockAmount;

  /// No description provided for @adjustmentType.
  ///
  /// In en, this message translates to:
  /// **'Adjustment Type'**
  String get adjustmentType;

  /// No description provided for @stockIn.
  ///
  /// In en, this message translates to:
  /// **'+ Receive'**
  String get stockIn;

  /// No description provided for @stockOut.
  ///
  /// In en, this message translates to:
  /// **'- Dispatch'**
  String get stockOut;

  /// No description provided for @adjustmentQuantity.
  ///
  /// In en, this message translates to:
  /// **'Adjustment Qty'**
  String get adjustmentQuantity;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity'**
  String get enterQuantity;

  /// No description provided for @reasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get reasonOptional;

  /// No description provided for @reasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. New stock, Loss, etc.'**
  String get reasonHint;

  /// No description provided for @stockAfterAdjust.
  ///
  /// In en, this message translates to:
  /// **'Stock After Adjustment'**
  String get stockAfterAdjust;

  /// No description provided for @adjustComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get adjustComplete;

  /// No description provided for @stockAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Stock adjusted ({change})'**
  String stockAdjusted(Object change);

  /// No description provided for @barcodeSkuInput.
  ///
  /// In en, this message translates to:
  /// **'Barcode / SKU Input'**
  String get barcodeSkuInput;

  /// No description provided for @barcodeOrSku.
  ///
  /// In en, this message translates to:
  /// **'Barcode or SKU'**
  String get barcodeOrSku;

  /// No description provided for @lookup.
  ///
  /// In en, this message translates to:
  /// **'Lookup'**
  String get lookup;

  /// No description provided for @continuousScanMode.
  ///
  /// In en, this message translates to:
  /// **'Continuous Scan Mode'**
  String get continuousScanMode;

  /// No description provided for @autoResetAfterInput.
  ///
  /// In en, this message translates to:
  /// **'— Auto-reset after input'**
  String get autoResetAfterInput;

  /// No description provided for @barcodeScannerHelp.
  ///
  /// In en, this message translates to:
  /// **'Automatically looks up when USB barcode scanner is connected.'**
  String get barcodeScannerHelp;

  /// No description provided for @addedToCartMsg.
  ///
  /// In en, this message translates to:
  /// **'✓  {name} — Added to cart'**
  String addedToCartMsg(Object name);

  /// No description provided for @outOfStockMsg.
  ///
  /// In en, this message translates to:
  /// **'✗  {name} — Currently out of stock'**
  String outOfStockMsg(Object name);

  /// No description provided for @productNotFoundMsg.
  ///
  /// In en, this message translates to:
  /// **'✗  [{input}] Product not found'**
  String productNotFoundMsg(Object input);

  /// No description provided for @excelSheetProductList.
  ///
  /// In en, this message translates to:
  /// **'Product List'**
  String get excelSheetProductList;

  /// No description provided for @excelHeaderProductName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get excelHeaderProductName;

  /// No description provided for @excelHeaderBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get excelHeaderBarcode;

  /// No description provided for @excelHeaderCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get excelHeaderCategory;

  /// No description provided for @excelHeaderSellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get excelHeaderSellingPrice;

  /// No description provided for @excelHeaderCostPrice.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get excelHeaderCostPrice;

  /// No description provided for @excelHeaderStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get excelHeaderStock;

  /// No description provided for @excelHeaderMinStock.
  ///
  /// In en, this message translates to:
  /// **'Min Stock'**
  String get excelHeaderMinStock;

  /// No description provided for @excelRowNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: Product name is empty'**
  String excelRowNameEmpty(Object row);

  /// No description provided for @excelRowPriceError.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: Selling price must be 0 or greater'**
  String excelRowPriceError(Object row);

  /// No description provided for @excelRowCostError.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: Cost must be 0 or greater'**
  String excelRowCostError(Object row);

  /// No description provided for @excelRowStockError.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: Stock must be 0 or greater'**
  String excelRowStockError(Object row);

  /// No description provided for @excelRowError.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: {error}'**
  String excelRowError(Object error, Object row);

  /// No description provided for @insufficientStockError.
  ///
  /// In en, this message translates to:
  /// **'Insufficient stock. Current: {stock}'**
  String insufficientStockError(Object stock);

  /// No description provided for @saleReason.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get saleReason;

  /// No description provided for @refundStockRestore.
  ///
  /// In en, this message translates to:
  /// **'Refund stock restore'**
  String get refundStockRestore;

  /// No description provided for @partialRefundStockRestore.
  ///
  /// In en, this message translates to:
  /// **'Partial refund stock restore'**
  String get partialRefundStockRestore;

  /// No description provided for @reportSheetSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get reportSheetSummary;

  /// No description provided for @reportTitle.
  ///
  /// In en, this message translates to:
  /// **'Oda POS Sales Report'**
  String get reportTitle;

  /// No description provided for @reportPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period: {from} ~ {to}'**
  String reportPeriod(Object from, Object to);

  /// No description provided for @reportItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get reportItem;

  /// No description provided for @reportValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get reportValue;

  /// No description provided for @reportTotalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get reportTotalSales;

  /// No description provided for @reportOrderCount.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get reportOrderCount;

  /// No description provided for @reportAvgOrder.
  ///
  /// In en, this message translates to:
  /// **'Avg. Order Amount'**
  String get reportAvgOrder;

  /// No description provided for @reportGrowthRate.
  ///
  /// In en, this message translates to:
  /// **'Growth Rate (%)'**
  String get reportGrowthRate;

  /// No description provided for @reportSheetDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily Sales'**
  String get reportSheetDaily;

  /// No description provided for @reportDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reportDate;

  /// No description provided for @reportSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get reportSales;

  /// No description provided for @reportSheetPayment.
  ///
  /// In en, this message translates to:
  /// **'By Payment Method'**
  String get reportSheetPayment;

  /// No description provided for @reportSheetProduct.
  ///
  /// In en, this message translates to:
  /// **'Product Sales'**
  String get reportSheetProduct;

  /// No description provided for @reportRank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get reportRank;

  /// No description provided for @reportQuantitySold.
  ///
  /// In en, this message translates to:
  /// **'Qty Sold'**
  String get reportQuantitySold;

  /// No description provided for @employeeInfoEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit employee info. Enter a new 4-digit number to change PIN.'**
  String get employeeInfoEdit;

  /// No description provided for @employeeInfoNew.
  ///
  /// In en, this message translates to:
  /// **'A new employee will be created. They can log in using the PIN.'**
  String get employeeInfoNew;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryBeverage.
  ///
  /// In en, this message translates to:
  /// **'Beverage'**
  String get categoryBeverage;

  /// No description provided for @categoryElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get categoryElectronics;

  /// No description provided for @categoryDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily Goods'**
  String get categoryDaily;

  /// No description provided for @kdsTitle.
  ///
  /// In en, this message translates to:
  /// **'Kitchen Display System'**
  String get kdsTitle;

  /// No description provided for @kdsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get kdsCompleted;

  /// No description provided for @kdsInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get kdsInProgress;

  /// No description provided for @kdsAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get kdsAverage;

  /// No description provided for @kdsMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}min {seconds}sec'**
  String kdsMinutes(Object count, Object seconds);

  /// No description provided for @kdsOrdersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} orders'**
  String kdsOrdersCount(Object count);

  /// No description provided for @kdsStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get kdsStatusPending;

  /// No description provided for @kdsStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get kdsStatusPreparing;

  /// No description provided for @kdsStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get kdsStatusReady;

  /// No description provided for @kdsStatusServed.
  ///
  /// In en, this message translates to:
  /// **'Served'**
  String get kdsStatusServed;

  /// No description provided for @kdsStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get kdsStatusCancelled;

  /// No description provided for @kdsPriorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get kdsPriorityNormal;

  /// No description provided for @kdsPriorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get kdsPriorityUrgent;

  /// No description provided for @kdsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get kdsFilterAll;

  /// No description provided for @kdsFilterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get kdsFilterPending;

  /// No description provided for @kdsFilterPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get kdsFilterPreparing;

  /// No description provided for @kdsFilterReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get kdsFilterReady;

  /// No description provided for @kdsNoOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders'**
  String get kdsNoOrders;

  /// No description provided for @kdsErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error occurred: {error}'**
  String kdsErrorOccurred(Object error);

  /// No description provided for @kdsTakeout.
  ///
  /// In en, this message translates to:
  /// **'Takeout #{id}'**
  String kdsTakeout(Object id);

  /// No description provided for @kdsOrderTime.
  ///
  /// In en, this message translates to:
  /// **'Order Time'**
  String get kdsOrderTime;

  /// No description provided for @kdsStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get kdsStatus;

  /// No description provided for @kdsPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get kdsPriority;

  /// No description provided for @kdsSpecialRequest.
  ///
  /// In en, this message translates to:
  /// **'Special Request'**
  String get kdsSpecialRequest;

  /// No description provided for @kdsProcessingHistory.
  ///
  /// In en, this message translates to:
  /// **'Processing History'**
  String get kdsProcessingHistory;

  /// No description provided for @kdsCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get kdsCancelOrder;

  /// No description provided for @kdsCancelOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this order?'**
  String get kdsCancelOrderConfirm;

  /// No description provided for @kdsOrderReceived.
  ///
  /// In en, this message translates to:
  /// **'Order Received'**
  String get kdsOrderReceived;

  /// No description provided for @kdsPreparationStarted.
  ///
  /// In en, this message translates to:
  /// **'Preparation Started'**
  String get kdsPreparationStarted;

  /// No description provided for @kdsPreparationComplete.
  ///
  /// In en, this message translates to:
  /// **'Preparation Complete'**
  String get kdsPreparationComplete;

  /// No description provided for @kdsServingComplete.
  ///
  /// In en, this message translates to:
  /// **'Serving Complete'**
  String get kdsServingComplete;

  /// No description provided for @kdsOrderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order Cancelled'**
  String get kdsOrderCancelled;

  /// No description provided for @kdsStartPreparation.
  ///
  /// In en, this message translates to:
  /// **'Start Preparation'**
  String get kdsStartPreparation;

  /// No description provided for @kdsMarkAsReady.
  ///
  /// In en, this message translates to:
  /// **'Mark as Ready'**
  String get kdsMarkAsReady;

  /// No description provided for @kdsMarkAsServed.
  ///
  /// In en, this message translates to:
  /// **'Mark as Served'**
  String get kdsMarkAsServed;

  /// No description provided for @kdsElapsedMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min elapsed'**
  String kdsElapsedMinutes(Object minutes);

  /// No description provided for @kdsTableNumber.
  ///
  /// In en, this message translates to:
  /// **'Table Number'**
  String get kdsTableNumber;

  /// No description provided for @kdsSpecialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special Instructions'**
  String get kdsSpecialInstructions;

  /// No description provided for @dailyClosing.
  ///
  /// In en, this message translates to:
  /// **'Daily Closing'**
  String get dailyClosing;

  /// No description provided for @closingHistory.
  ///
  /// In en, this message translates to:
  /// **'Closing History'**
  String get closingHistory;

  /// No description provided for @closingSummary.
  ///
  /// In en, this message translates to:
  /// **'Closing Summary'**
  String get closingSummary;

  /// No description provided for @selectClosingDate.
  ///
  /// In en, this message translates to:
  /// **'Select Closing Date'**
  String get selectClosingDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @salesAggregation.
  ///
  /// In en, this message translates to:
  /// **'Sales Aggregation'**
  String get salesAggregation;

  /// No description provided for @totalTransactions.
  ///
  /// In en, this message translates to:
  /// **'Total Transactions'**
  String get totalTransactions;

  /// No description provided for @transactionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions'**
  String transactionsCount(int count);

  /// No description provided for @cashCount.
  ///
  /// In en, this message translates to:
  /// **'Cash Count'**
  String get cashCount;

  /// No description provided for @expectedCash.
  ///
  /// In en, this message translates to:
  /// **'Expected Cash'**
  String get expectedCash;

  /// No description provided for @actualCash.
  ///
  /// In en, this message translates to:
  /// **'Actual Cash'**
  String get actualCash;

  /// No description provided for @cashDifference.
  ///
  /// In en, this message translates to:
  /// **'Cash Difference'**
  String get cashDifference;

  /// No description provided for @enterActualCash.
  ///
  /// In en, this message translates to:
  /// **'Enter Actual Cash'**
  String get enterActualCash;

  /// No description provided for @actualCashHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the actual cash amount'**
  String get actualCashHint;

  /// No description provided for @cashDifferenceAcceptable.
  ///
  /// In en, this message translates to:
  /// **'Exceeds acceptable range (±\$10)'**
  String get cashDifferenceAcceptable;

  /// No description provided for @specialNotes.
  ///
  /// In en, this message translates to:
  /// **'Special Notes'**
  String get specialNotes;

  /// No description provided for @notesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter any special notes'**
  String get notesPlaceholder;

  /// No description provided for @performClosing.
  ///
  /// In en, this message translates to:
  /// **'Perform Closing'**
  String get performClosing;

  /// No description provided for @skipCashCount.
  ///
  /// In en, this message translates to:
  /// **'Close Without Cash Count'**
  String get skipCashCount;

  /// No description provided for @closingComplete.
  ///
  /// In en, this message translates to:
  /// **'Closing completed successfully'**
  String get closingComplete;

  /// No description provided for @closingFailed.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during closing'**
  String get closingFailed;

  /// No description provided for @loadingClosingData.
  ///
  /// In en, this message translates to:
  /// **'Loading closing data...'**
  String get loadingClosingData;

  /// No description provided for @noClosingHistory.
  ///
  /// In en, this message translates to:
  /// **'No closing history'**
  String get noClosingHistory;

  /// No description provided for @loadClosingHistoryFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load closing history'**
  String get loadClosingHistoryFailed;

  /// No description provided for @tryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get tryAgainLater;

  /// No description provided for @selectPeriod.
  ///
  /// In en, this message translates to:
  /// **'Select Period'**
  String get selectPeriod;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @generatePdf.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF'**
  String get generatePdf;

  /// No description provided for @savePdfQuestion.
  ///
  /// In en, this message translates to:
  /// **'Would you like to save {reportName} as PDF?'**
  String savePdfQuestion(String reportName);

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @editActualCash.
  ///
  /// In en, this message translates to:
  /// **'Edit {label}'**
  String editActualCash(String label);

  /// No description provided for @closingDetails.
  ///
  /// In en, this message translates to:
  /// **'Closing Details'**
  String get closingDetails;

  /// No description provided for @closingTime.
  ///
  /// In en, this message translates to:
  /// **'Closing Time'**
  String get closingTime;

  /// No description provided for @assignedEmployee.
  ///
  /// In en, this message translates to:
  /// **'Assigned Employee'**
  String get assignedEmployee;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @averageTransaction.
  ///
  /// In en, this message translates to:
  /// **'Average Transaction'**
  String get averageTransaction;

  /// No description provided for @taxTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Tax'**
  String get taxTotal;

  /// No description provided for @discountTotal.
  ///
  /// In en, this message translates to:
  /// **'Total Discount'**
  String get discountTotal;

  /// No description provided for @normalCashDifference.
  ///
  /// In en, this message translates to:
  /// **'Within Range'**
  String get normalCashDifference;

  /// No description provided for @pdfSaved.
  ///
  /// In en, this message translates to:
  /// **'PDF saved: {path}'**
  String pdfSaved(String path);

  /// No description provided for @pdfGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'PDF generation failed: {error}'**
  String pdfGenerationFailed(String error);

  /// No description provided for @alreadyClosed.
  ///
  /// In en, this message translates to:
  /// **'This date has already been closed'**
  String get alreadyClosed;

  /// No description provided for @cannotCloseFutureDate.
  ///
  /// In en, this message translates to:
  /// **'Cannot close future dates'**
  String get cannotCloseFutureDate;

  /// No description provided for @noSalesForDate.
  ///
  /// In en, this message translates to:
  /// **'No sales found for this date'**
  String get noSalesForDate;

  /// No description provided for @loginRequired.
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get loginRequired;

  /// No description provided for @closingProcessError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during closing. Please try again later'**
  String get closingProcessError;

  /// No description provided for @dailyClosingReport.
  ///
  /// In en, this message translates to:
  /// **'Daily Closing Report'**
  String get dailyClosingReport;

  /// No description provided for @closingInfo.
  ///
  /// In en, this message translates to:
  /// **'Closing Information'**
  String get closingInfo;

  /// No description provided for @closingDate.
  ///
  /// In en, this message translates to:
  /// **'Closing Date'**
  String get closingDate;

  /// No description provided for @paymentMethodBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Payment Method Breakdown'**
  String get paymentMethodBreakdown;

  /// No description provided for @qrPaymentSales.
  ///
  /// In en, this message translates to:
  /// **'QR Payment'**
  String get qrPaymentSales;

  /// No description provided for @transferSales.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferSales;

  /// No description provided for @cashReconciliation.
  ///
  /// In en, this message translates to:
  /// **'Cash Reconciliation'**
  String get cashReconciliation;

  /// No description provided for @signatureSection.
  ///
  /// In en, this message translates to:
  /// **'Signatures'**
  String get signatureSection;

  /// No description provided for @closingManager.
  ///
  /// In en, this message translates to:
  /// **'Closing Manager'**
  String get closingManager;

  /// No description provided for @verifier.
  ///
  /// In en, this message translates to:
  /// **'Verifier'**
  String get verifier;

  /// No description provided for @signature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get signature;

  /// No description provided for @userGuide.
  ///
  /// In en, this message translates to:
  /// **'User Guide'**
  String get userGuide;

  /// No description provided for @tutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get tutorial;

  /// No description provided for @tutorialSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutorialSkip;

  /// No description provided for @tutorialNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutorialNext;

  /// No description provided for @tutorialPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get tutorialPrevious;

  /// No description provided for @tutorialFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get tutorialFinish;

  /// No description provided for @tutorialDontShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show again'**
  String get tutorialDontShowAgain;

  /// No description provided for @tutorial_daily_closing_welcome_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Daily Closing'**
  String get tutorial_daily_closing_welcome_title;

  /// No description provided for @tutorial_daily_closing_welcome_desc.
  ///
  /// In en, this message translates to:
  /// **'Use Daily Closing to reconcile and record your daily sales. Let\'s start with a quick guide.'**
  String get tutorial_daily_closing_welcome_desc;

  /// No description provided for @tutorial_daily_closing_date_title.
  ///
  /// In en, this message translates to:
  /// **'Select Closing Date'**
  String get tutorial_daily_closing_date_title;

  /// No description provided for @tutorial_daily_closing_date_desc.
  ///
  /// In en, this message translates to:
  /// **'Tap here to select the date you want to close. Today\'s date is selected by default.'**
  String get tutorial_daily_closing_date_desc;

  /// No description provided for @tutorial_daily_closing_summary_title.
  ///
  /// In en, this message translates to:
  /// **'Sales Summary'**
  String get tutorial_daily_closing_summary_title;

  /// No description provided for @tutorial_daily_closing_summary_desc.
  ///
  /// In en, this message translates to:
  /// **'This card shows total transactions, total sales, average transaction, taxes, and discounts.'**
  String get tutorial_daily_closing_summary_desc;

  /// No description provided for @tutorial_daily_closing_payment_title.
  ///
  /// In en, this message translates to:
  /// **'Payment Method Breakdown'**
  String get tutorial_daily_closing_payment_title;

  /// No description provided for @tutorial_daily_closing_payment_desc.
  ///
  /// In en, this message translates to:
  /// **'View sales breakdown by payment method: cash, card, QR payment, and transfer.'**
  String get tutorial_daily_closing_payment_desc;

  /// No description provided for @tutorial_daily_closing_cash_title.
  ///
  /// In en, this message translates to:
  /// **'Cash Reconciliation'**
  String get tutorial_daily_closing_cash_title;

  /// No description provided for @tutorial_daily_closing_cash_desc.
  ///
  /// In en, this message translates to:
  /// **'Compare expected cash sales with actual cash count to verify differences.'**
  String get tutorial_daily_closing_cash_desc;

  /// No description provided for @tutorial_daily_closing_actual_cash_title.
  ///
  /// In en, this message translates to:
  /// **'Enter Actual Cash'**
  String get tutorial_daily_closing_actual_cash_title;

  /// No description provided for @tutorial_daily_closing_actual_cash_desc.
  ///
  /// In en, this message translates to:
  /// **'Tap this button to enter the actual cash amount you counted. The system will verify if the difference is within acceptable range.'**
  String get tutorial_daily_closing_actual_cash_desc;

  /// No description provided for @tutorial_daily_closing_notes_title.
  ///
  /// In en, this message translates to:
  /// **'Record Special Notes'**
  String get tutorial_daily_closing_notes_title;

  /// No description provided for @tutorial_daily_closing_notes_desc.
  ///
  /// In en, this message translates to:
  /// **'You can add notes about special occurrences during closing, such as refunds or shortages.'**
  String get tutorial_daily_closing_notes_desc;

  /// No description provided for @tutorial_daily_closing_perform_title.
  ///
  /// In en, this message translates to:
  /// **'Perform Closing'**
  String get tutorial_daily_closing_perform_title;

  /// No description provided for @tutorial_daily_closing_perform_desc.
  ///
  /// In en, this message translates to:
  /// **'After verifying all information, tap this button to complete the closing. Note: Closing cannot be undone.'**
  String get tutorial_daily_closing_perform_desc;

  /// No description provided for @tutorial_daily_closing_history_title.
  ///
  /// In en, this message translates to:
  /// **'Closing History'**
  String get tutorial_daily_closing_history_title;

  /// No description provided for @tutorial_daily_closing_history_desc.
  ///
  /// In en, this message translates to:
  /// **'View previous closing records and download them as PDF reports.'**
  String get tutorial_daily_closing_history_desc;

  /// No description provided for @reservations.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get reservations;

  /// No description provided for @addReservation.
  ///
  /// In en, this message translates to:
  /// **'Add Reservation'**
  String get addReservation;

  /// No description provided for @reservationDetail.
  ///
  /// In en, this message translates to:
  /// **'Reservation Detail'**
  String get reservationDetail;

  /// No description provided for @deleteReservation.
  ///
  /// In en, this message translates to:
  /// **'Delete Reservation'**
  String get deleteReservation;

  /// No description provided for @deleteReservationConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the reservation for {customer}?'**
  String deleteReservationConfirm(String customer);

  /// No description provided for @reservationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Reservation deleted'**
  String get reservationDeleted;

  /// No description provided for @noReservations.
  ///
  /// In en, this message translates to:
  /// **'No reservations'**
  String get noReservations;

  /// No description provided for @reservationStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Reservation status changed to {status}'**
  String reservationStatusChanged(String status);

  /// No description provided for @reservationPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get reservationPending;

  /// No description provided for @reservationConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get reservationConfirmed;

  /// No description provided for @reservationSeated.
  ///
  /// In en, this message translates to:
  /// **'Seated'**
  String get reservationSeated;

  /// No description provided for @reservationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get reservationCancelled;

  /// No description provided for @reservationNoShow.
  ///
  /// In en, this message translates to:
  /// **'No Show'**
  String get reservationNoShow;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @customerPhone.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get customerPhone;

  /// No description provided for @partySize.
  ///
  /// In en, this message translates to:
  /// **'Party Size'**
  String get partySize;

  /// No description provided for @table.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get table;

  /// No description provided for @partySizePeople.
  ///
  /// In en, this message translates to:
  /// **'{count} people'**
  String partySizePeople(int count);

  /// No description provided for @reservationDate.
  ///
  /// In en, this message translates to:
  /// **'Reservation Date'**
  String get reservationDate;

  /// No description provided for @reservationTime.
  ///
  /// In en, this message translates to:
  /// **'Reservation Time'**
  String get reservationTime;

  /// No description provided for @specialRequests.
  ///
  /// In en, this message translates to:
  /// **'Special Requests'**
  String get specialRequests;

  /// No description provided for @specialRequestsOptional.
  ///
  /// In en, this message translates to:
  /// **'Special Requests (Optional)'**
  String get specialRequestsOptional;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @allReservations.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allReservations;

  /// No description provided for @errorOccurredWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error occurred: {message}'**
  String errorOccurredWithMessage(String message);

  /// No description provided for @editReservation.
  ///
  /// In en, this message translates to:
  /// **'Edit Reservation'**
  String get editReservation;

  /// No description provided for @customerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter customer name'**
  String get customerNameRequired;

  /// No description provided for @customerPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter contact number'**
  String get customerPhoneRequired;

  /// No description provided for @partySizeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter party size'**
  String get partySizeRequired;

  /// No description provided for @partySizeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Party size must be at least 1'**
  String get partySizeInvalid;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'people'**
  String get people;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

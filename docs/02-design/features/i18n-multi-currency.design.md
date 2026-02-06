# Design: i18n-multi-currency

> **Related Plan**: [i18n-multi-currency.plan.md](../../01-plan/features/i18n-multi-currency.plan.md)

## 1. Architecture Overview

### 1.1 System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
├─────────────────────────────────────────────────────────────┤
│  Localized Widgets (AppLocalizations)                       │
│  ├─ POS Screen        (다국어 UI)                           │
│  ├─ Product Screen    (다국어 상품명)                       │
│  ├─ Settings Screen   (언어/통화 선택)                      │
│  └─ Receipt Screen    (다국어 영수증)                       │
├─────────────────────────────────────────────────────────────┤
│                      Business Logic Layer                    │
├─────────────────────────────────────────────────────────────┤
│  LocaleProvider (언어 상태 관리)                            │
│  CurrencyProvider (통화 상태 관리)                          │
│  ExchangeRateService (환율 계산)                            │
│  PriceFormatter (가격 포맷팅)                               │
├─────────────────────────────────────────────────────────────┤
│                      Data Layer                              │
├─────────────────────────────────────────────────────────────┤
│  ProductTranslationsDao (다국어 상품명)                     │
│  ExchangeRatesDao (환율 데이터)                             │
│  SettingsDao (언어/통화 설정)                               │
│  SharedPreferences (로컬 설정 캐시)                         │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Data Flow

```
User Action (언어 변경)
  ↓
LocaleProvider.setLocale('vi')
  ↓
SharedPreferences 저장
  ↓
MaterialApp rebuild
  ↓
All Widgets re-render with new locale
  ↓
AppLocalizations.of(context) returns Vietnamese strings
```

```
User Action (통화 변경)
  ↓
CurrencyProvider.setCurrency('VND')
  ↓
Database에 설정 저장
  ↓
PriceFormatter 업데이트
  ↓
모든 가격 표시 위젯 rebuild
  ↓
VND 형식으로 가격 표시 (₫20,000)
```

## 2. Database Design

### 2.1 Schema Changes

#### 2.1.1 New Tables

```sql
-- 다국어 상품 번역
CREATE TABLE product_translations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL,
  language_code TEXT NOT NULL,  -- 'ko', 'en', 'vi'
  name TEXT NOT NULL,
  description TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
  UNIQUE(product_id, language_code)
);

-- 환율 설정
CREATE TABLE exchange_rates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  from_currency TEXT NOT NULL,  -- 'KRW', 'USD', 'VND'
  to_currency TEXT NOT NULL,
  rate REAL NOT NULL,
  is_active BOOLEAN DEFAULT 1,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(from_currency, to_currency)
);

-- 앱 설정 (확장)
CREATE TABLE IF NOT EXISTS app_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),  -- 싱글톤
  language_code TEXT DEFAULT 'ko',
  currency_code TEXT DEFAULT 'KRW',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

#### 2.1.2 Migration Script (Schema v2 → v3)

```dart
// lib/database/app_database.dart

@override
int get schemaVersion => 3;

@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedInitialData();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // v1 → v2: Promotions 추가
      if (from == 1 && to >= 2) {
        await m.createTable(promotions);
      }

      // v2 → v3: i18n & Multi-currency
      if (from <= 2 && to >= 3) {
        await m.createTable(productTranslations);
        await m.createTable(exchangeRates);
        await m.createTable(appSettings);
        await _seedDefaultSettings();
        await _seedDefaultExchangeRates();
      }
    },
    // ...
  );
}

Future<void> _seedDefaultSettings() async {
  await into(appSettings).insert(
    AppSettingsCompanion.insert(
      languageCode: const Value('ko'),
      currencyCode: const Value('KRW'),
    ),
  );
}

Future<void> _seedDefaultExchangeRates() async {
  // KRW 기준 환율
  final rates = [
    ('KRW', 'USD', 0.00075),  // 1 KRW = 0.00075 USD
    ('KRW', 'VND', 19.5),     // 1 KRW = 19.5 VND
    ('USD', 'KRW', 1333.33),  // 1 USD = 1333.33 KRW
    ('USD', 'VND', 26000.0),  // 1 USD = 26000 VND
    ('VND', 'KRW', 0.051),    // 1 VND = 0.051 KRW
    ('VND', 'USD', 0.000038), // 1 VND = 0.000038 USD
  ];

  for (final (from, to, rate) in rates) {
    await into(exchangeRates).insert(
      ExchangeRatesCompanion.insert(
        fromCurrency: from,
        toCurrency: to,
        rate: rate,
      ),
    );
  }
}
```

### 2.2 Drift Table Definitions

```dart
// lib/database/tables/product_translations.dart
import 'package:drift/drift.dart';
import 'products.dart';

class ProductTranslations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id, onDelete: KeyAction.cascade)();
  TextColumn get languageCode => text().withLength(min: 2, max: 5)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {productId, languageCode},
  ];
}

// lib/database/tables/exchange_rates.dart
import 'package:drift/drift.dart';

class ExchangeRates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fromCurrency => text().withLength(min: 3, max: 3)();
  TextColumn get toCurrency => text().withLength(min: 3, max: 3)();
  RealColumn get rate => real()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {fromCurrency, toCurrency},
  ];
}

// lib/database/tables/app_settings.dart
import 'package:drift/drift.dart';

class AppSettings extends Table {
  IntColumn get id => integer().check(id.equals(1))();  // Singleton
  TextColumn get languageCode => text().withDefault(const Constant('ko'))();
  TextColumn get currencyCode => text().withDefault(const Constant('KRW'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

## 3. Internationalization (i18n) Design

### 3.1 Flutter Localization Setup

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

flutter:
  generate: true  # ARB 파일 자동 생성
```

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

### 3.2 ARB File Structure

```json
// lib/l10n/app_en.arb (English - Template)
{
  "@@locale": "en",

  // Common
  "appName": "Oda POS",
  "ok": "OK",
  "cancel": "Cancel",
  "save": "Save",
  "delete": "Delete",
  "edit": "Edit",
  "add": "Add",
  "search": "Search",
  "settings": "Settings",

  // Navigation
  "navPos": "POS",
  "navProducts": "Products",
  "navSales": "Sales",
  "navDashboard": "Dashboard",
  "navInventory": "Inventory",
  "navEmployees": "Employees",
  "navPromotions": "Promotions",

  // POS Screen
  "cart": "Cart",
  "subtotal": "Subtotal",
  "discount": "Discount",
  "total": "Total",
  "checkout": "Checkout",
  "clearCart": "Clear",
  "addDiscount": "Add Discount",
  "applyPromotion": "Apply Promotion",

  // Product Screen
  "productName": "Product Name",
  "productPrice": "Price",
  "productStock": "Stock",
  "productCategory": "Category",
  "addProduct": "Add Product",
  "editProduct": "Edit Product",
  "deleteProduct": "Delete Product",

  // Payment
  "paymentMethod": "Payment Method",
  "cash": "Cash",
  "card": "Card",
  "qr": "QR Code",
  "cashReceived": "Cash Received",
  "change": "Change",
  "paymentComplete": "Payment Complete",

  // Receipt
  "receiptNumber": "Receipt #",
  "receiptDate": "Date",
  "receiptItems": "Items",
  "receiptThankYou": "Thank you for your purchase!",

  // Settings
  "settingsLanguage": "Language",
  "settingsCurrency": "Currency",
  "settingsExchangeRate": "Exchange Rate",
  "settingsSelectLanguage": "Select Language",
  "settingsSelectCurrency": "Select Currency",

  // Languages
  "langKorean": "한국어",
  "langEnglish": "English",
  "langVietnamese": "Tiếng Việt",

  // Currencies
  "currencyKRW": "Korean Won (₩)",
  "currencyUSD": "US Dollar ($)",
  "currencyVND": "Vietnamese Dong (₫)",

  // Messages
  "msgItemAdded": "Item added to cart",
  "msgPaymentSuccess": "Payment successful",
  "msgPaymentFailed": "Payment failed",
  "msgInsufficientStock": "Insufficient stock",
  "msgInvalidAmount": "Invalid amount"
}
```

```json
// lib/l10n/app_ko.arb (Korean)
{
  "@@locale": "ko",
  "appName": "오다 POS",
  "ok": "확인",
  "cancel": "취소",
  "save": "저장",
  "delete": "삭제",
  "edit": "수정",
  "add": "추가",
  "search": "검색",
  "settings": "설정",

  "navPos": "POS",
  "navProducts": "상품관리",
  "navSales": "주문내역",
  "navDashboard": "대시보드",
  "navInventory": "재고부족",
  "navEmployees": "직원관리",
  "navPromotions": "프로모션",

  "cart": "장바구니",
  "subtotal": "소계",
  "discount": "할인",
  "total": "합계",
  "checkout": "결제",
  "clearCart": "초기화",
  "addDiscount": "할인 추가",
  "applyPromotion": "프로모션 적용",

  "productName": "상품명",
  "productPrice": "가격",
  "productStock": "재고",
  "productCategory": "카테고리",
  "addProduct": "상품 추가",
  "editProduct": "상품 수정",
  "deleteProduct": "상품 삭제",

  "paymentMethod": "결제 방법",
  "cash": "현금",
  "card": "카드",
  "qr": "QR",
  "cashReceived": "받은 금액",
  "change": "거스름돈",
  "paymentComplete": "결제 완료",

  "receiptNumber": "영수증 번호",
  "receiptDate": "일시",
  "receiptItems": "항목",
  "receiptThankYou": "감사합니다!",

  "settingsLanguage": "언어",
  "settingsCurrency": "통화",
  "settingsExchangeRate": "환율",
  "settingsSelectLanguage": "언어 선택",
  "settingsSelectCurrency": "통화 선택",

  "langKorean": "한국어",
  "langEnglish": "English",
  "langVietnamese": "Tiếng Việt",

  "currencyKRW": "원 (₩)",
  "currencyUSD": "달러 ($)",
  "currencyVND": "동 (₫)",

  "msgItemAdded": "장바구니에 추가되었습니다",
  "msgPaymentSuccess": "결제가 완료되었습니다",
  "msgPaymentFailed": "결제에 실패했습니다",
  "msgInsufficientStock": "재고가 부족합니다",
  "msgInvalidAmount": "잘못된 금액입니다"
}
```

```json
// lib/l10n/app_vi.arb (Vietnamese)
{
  "@@locale": "vi",
  "appName": "Oda POS",
  "ok": "OK",
  "cancel": "Hủy",
  "save": "Lưu",
  "delete": "Xóa",
  "edit": "Sửa",
  "add": "Thêm",
  "search": "Tìm kiếm",
  "settings": "Cài đặt",

  "navPos": "POS",
  "navProducts": "Sản phẩm",
  "navSales": "Bán hàng",
  "navDashboard": "Bảng điều khiển",
  "navInventory": "Tồn kho",
  "navEmployees": "Nhân viên",
  "navPromotions": "Khuyến mãi",

  "cart": "Giỏ hàng",
  "subtotal": "Tạm tính",
  "discount": "Giảm giá",
  "total": "Tổng cộng",
  "checkout": "Thanh toán",
  "clearCart": "Xóa",
  "addDiscount": "Thêm giảm giá",
  "applyPromotion": "Áp dụng khuyến mãi",

  "productName": "Tên sản phẩm",
  "productPrice": "Giá",
  "productStock": "Tồn kho",
  "productCategory": "Danh mục",
  "addProduct": "Thêm sản phẩm",
  "editProduct": "Sửa sản phẩm",
  "deleteProduct": "Xóa sản phẩm",

  "paymentMethod": "Phương thức thanh toán",
  "cash": "Tiền mặt",
  "card": "Thẻ",
  "qr": "Mã QR",
  "cashReceived": "Tiền nhận",
  "change": "Tiền thừa",
  "paymentComplete": "Thanh toán thành công",

  "receiptNumber": "Số hóa đơn",
  "receiptDate": "Ngày",
  "receiptItems": "Mặt hàng",
  "receiptThankYou": "Cảm ơn quý khách!",

  "settingsLanguage": "Ngôn ngữ",
  "settingsCurrency": "Tiền tệ",
  "settingsExchangeRate": "Tỷ giá",
  "settingsSelectLanguage": "Chọn ngôn ngữ",
  "settingsSelectCurrency": "Chọn tiền tệ",

  "langKorean": "한국어",
  "langEnglish": "English",
  "langVietnamese": "Tiếng Việt",

  "currencyKRW": "Won (₩)",
  "currencyUSD": "Đô la Mỹ ($)",
  "currencyVND": "Đồng Việt Nam (₫)",

  "msgItemAdded": "Đã thêm vào giỏ hàng",
  "msgPaymentSuccess": "Thanh toán thành công",
  "msgPaymentFailed": "Thanh toán thất bại",
  "msgInsufficientStock": "Không đủ hàng trong kho",
  "msgInvalidAmount": "Số tiền không hợp lệ"
}
```

### 3.3 Main App Configuration

```dart
// lib/main.dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OdaPosApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Oda POS',

      // Localization delegates
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Supported locales
      supportedLocales: const [
        Locale('ko', ''),  // Korean
        Locale('en', ''),  // English
        Locale('vi', ''),  // Vietnamese
      ],

      // Current locale
      locale: locale,

      // Locale resolution
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return supportedLocales.first;

        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }

        return supportedLocales.first;
      },

      theme: AppTheme.lightTheme,
      home: const PinLoginScreen(),
    );
  }
}
```

## 4. Multi-Currency Design

### 4.1 Currency Model

```dart
// lib/core/models/currency.dart
enum AppCurrency {
  krw('KRW', '₩', 'won', 1, 0),
  usd('USD', '\$', 'dollar', 0.00075, 2),
  vnd('VND', '₫', 'dong', 19.5, 0);

  final String code;
  final String symbol;
  final String name;
  final double defaultRate;  // KRW 기준 환율
  final int decimalDigits;   // 소수점 자릿수

  const AppCurrency(
    this.code,
    this.symbol,
    this.name,
    this.defaultRate,
    this.decimalDigits,
  );

  static AppCurrency fromCode(String code) {
    return AppCurrency.values.firstWhere(
      (c) => c.code == code,
      orElse: () => AppCurrency.krw,
    );
  }
}
```

### 4.2 Price Formatter Service

```dart
// lib/core/services/price_formatter.dart
import 'package:intl/intl.dart';

class PriceFormatter {
  final AppCurrency currency;
  final double exchangeRate;

  PriceFormatter({
    required this.currency,
    required this.exchangeRate,
  });

  /// KRW 가격을 현재 통화로 변환
  double convert(double priceInKRW) {
    return priceInKRW * exchangeRate;
  }

  /// 현재 통화를 KRW로 역변환
  double toKRW(double priceInCurrency) {
    return priceInCurrency / exchangeRate;
  }

  /// 가격을 현재 통화 형식으로 포맷팅
  String format(double priceInKRW, {bool includeSymbol = true}) {
    final convertedPrice = convert(priceInKRW);

    final formatter = NumberFormat.currency(
      locale: _getLocaleForCurrency(),
      symbol: includeSymbol ? currency.symbol : '',
      decimalDigits: currency.decimalDigits,
    );

    return formatter.format(convertedPrice);
  }

  /// 간단한 포맷팅 (천 단위 구분)
  String formatSimple(double priceInKRW) {
    final convertedPrice = convert(priceInKRW);
    final rounded = convertedPrice.toStringAsFixed(currency.decimalDigits);

    final parts = rounded.split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );

    final result = parts.length > 1 && currency.decimalDigits > 0
        ? '$integerPart.${parts[1]}'
        : integerPart;

    return '${currency.symbol}$result';
  }

  String _getLocaleForCurrency() {
    switch (currency) {
      case AppCurrency.krw:
        return 'ko_KR';
      case AppCurrency.usd:
        return 'en_US';
      case AppCurrency.vnd:
        return 'vi_VN';
    }
  }
}
```

### 4.3 Currency Provider

```dart
// lib/providers/currency_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 현재 통화 Provider
final currencyProvider = StateNotifierProvider<CurrencyNotifier, AppCurrency>((ref) {
  return CurrencyNotifier(ref);
});

class CurrencyNotifier extends StateNotifier<AppCurrency> {
  final Ref ref;

  CurrencyNotifier(this.ref) : super(AppCurrency.krw) {
    _loadSavedCurrency();
  }

  Future<void> _loadSavedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyCode = prefs.getString('currency_code') ?? 'KRW';
    state = AppCurrency.fromCode(currencyCode);
  }

  Future<void> setCurrency(AppCurrency currency) async {
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', currency.code);

    // DB에도 저장
    final db = ref.read(databaseProvider);
    await db.into(db.appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(
        id: const Value(1),
        currencyCode: Value(currency.code),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

/// 환율 Provider
final exchangeRateProvider = FutureProvider.family<double, String>((ref, toCurrency) async {
  final db = ref.watch(databaseProvider);
  final fromCurrency = 'KRW';  // 기준 통화

  final rate = await (db.select(db.exchangeRates)
        ..where((r) =>
            r.fromCurrency.equals(fromCurrency) &
            r.toCurrency.equals(toCurrency) &
            r.isActive.equals(true)))
      .getSingleOrNull();

  return rate?.rate ?? AppCurrency.fromCode(toCurrency).defaultRate;
});

/// Price Formatter Provider
final priceFormatterProvider = Provider<PriceFormatter>((ref) {
  final currency = ref.watch(currencyProvider);
  final exchangeRateAsync = ref.watch(exchangeRateProvider(currency.code));

  return exchangeRateAsync.when(
    data: (rate) => PriceFormatter(currency: currency, exchangeRate: rate),
    loading: () => PriceFormatter(currency: currency, exchangeRate: currency.defaultRate),
    error: (_, __) => PriceFormatter(currency: currency, exchangeRate: currency.defaultRate),
  );
});
```

## 5. Locale Provider Design

```dart
// lib/providers/locale_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 언어 열거형
enum AppLanguage {
  ko('ko', '한국어', 'KO'),
  en('en', 'English', 'EN'),
  vi('vi', 'Tiếng Việt', 'VI');

  final String code;
  final String nativeName;
  final String shortCode;

  const AppLanguage(this.code, this.nativeName, this.shortCode);

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.ko,
    );
  }
}

/// 현재 로케일 Provider
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final Ref ref;

  LocaleNotifier(this.ref) : super(const Locale('ko')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'ko';
    state = Locale(languageCode);
  }

  Future<void> setLocale(AppLanguage language) async {
    state = language.locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', language.code);

    // DB에도 저장
    final db = ref.read(databaseProvider);
    await db.into(db.appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(
        id: const Value(1),
        languageCode: Value(language.code),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

/// 현재 언어 Provider
final currentLanguageProvider = Provider<AppLanguage>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLanguage.fromCode(locale.languageCode);
});
```

## 6. Product Translation Design

### 6.1 Product Translation Service

```dart
// lib/features/products/services/product_translation_service.dart
class ProductTranslationService {
  final AppDatabase _db;

  ProductTranslationService(this._db);

  /// 상품 번역 추가/수정
  Future<void> saveTranslation({
    required int productId,
    required String languageCode,
    required String name,
    String? description,
  }) async {
    await _db.into(_db.productTranslations).insertOnConflictUpdate(
      ProductTranslationsCompanion.insert(
        productId: productId,
        languageCode: languageCode,
        name: name,
        description: Value(description),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 특정 언어로 상품명 조회
  Future<String?> getProductName(int productId, String languageCode) async {
    final translation = await (_db.select(_db.productTranslations)
          ..where((t) =>
              t.productId.equals(productId) &
              t.languageCode.equals(languageCode)))
        .getSingleOrNull();

    return translation?.name;
  }

  /// 모든 번역 조회
  Future<Map<String, ProductTranslation>> getAllTranslations(int productId) async {
    final translations = await (_db.select(_db.productTranslations)
          ..where((t) => t.productId.equals(productId)))
        .get();

    return {
      for (var t in translations) t.languageCode: t,
    };
  }

  /// 현재 언어로 상품 목록 조회 (Fallback 지원)
  Future<List<LocalizedProduct>> getLocalizedProducts(String languageCode) async {
    final products = await _db.select(_db.products).get();
    final List<LocalizedProduct> result = [];

    for (final product in products) {
      // 번역 시도
      final translation = await getProductName(product.id, languageCode);

      result.add(LocalizedProduct(
        product: product,
        localizedName: translation ?? product.name,  // Fallback to default
        hasTranslation: translation != null,
      ));
    }

    return result;
  }
}

class LocalizedProduct {
  final Product product;
  final String localizedName;
  final bool hasTranslation;

  LocalizedProduct({
    required this.product,
    required this.localizedName,
    required this.hasTranslation,
  });
}

/// Provider
final productTranslationServiceProvider = Provider<ProductTranslationService>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductTranslationService(db);
});

/// 현재 언어로 로컬라이즈된 상품 목록 Provider
final localizedProductsProvider = FutureProvider<List<LocalizedProduct>>((ref) async {
  final locale = ref.watch(localeProvider);
  final service = ref.watch(productTranslationServiceProvider);
  return service.getLocalizedProducts(locale.languageCode);
});
```

## 7. Settings Screen Design

### 7.1 Language & Currency Settings Screen

```dart
// lib/features/settings/presentation/screens/locale_settings_screen.dart
class LocaleSettingsScreen extends ConsumerWidget {
  const LocaleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(currentLanguageProvider);
    final currentCurrency = ref.watch(currencyProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          // 언어 설정
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            subtitle: Text(currentLanguage.nativeName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context, ref),
          ),
          const Divider(),

          // 통화 설정
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: Text(l10n.settingsCurrency),
            subtitle: Text('${currentCurrency.symbol} ${currentCurrency.code}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCurrencyPicker(context, ref),
          ),
          const Divider(),

          // 환율 설정
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: Text(l10n.settingsExchangeRate),
            subtitle: const Text('환율 관리'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExchangeRateScreen()),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsSelectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((lang) {
            return RadioListTile<AppLanguage>(
              title: Text(lang.nativeName),
              value: lang,
              groupValue: ref.read(currentLanguageProvider),
              onChanged: (value) {
                if (value != null) {
                  ref.read(localeProvider.notifier).setLocale(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsSelectCurrency),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppCurrency.values.map((currency) {
            return RadioListTile<AppCurrency>(
              title: Text('${currency.symbol} ${currency.code}'),
              subtitle: Text(currency.name),
              value: currency,
              groupValue: ref.read(currencyProvider),
              onChanged: (value) {
                if (value != null) {
                  ref.read(currencyProvider.notifier).setCurrency(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
```

### 7.2 Exchange Rate Management Screen

```dart
// lib/features/settings/presentation/screens/exchange_rate_screen.dart
class ExchangeRateScreen extends ConsumerWidget {
  const ExchangeRateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exchangeRatesAsync = ref.watch(allExchangeRatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('환율 설정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(allExchangeRatesProvider),
          ),
        ],
      ),
      body: exchangeRatesAsync.when(
        data: (rates) => ListView.builder(
          itemCount: rates.length,
          itemBuilder: (context, index) {
            final rate = rates[index];
            return ListTile(
              title: Text('${rate.fromCurrency} → ${rate.toCurrency}'),
              subtitle: Text('환율: ${rate.rate.toStringAsFixed(6)}'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editExchangeRate(context, ref, rate),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _editExchangeRate(BuildContext context, WidgetRef ref, ExchangeRate rate) {
    final controller = TextEditingController(text: rate.rate.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${rate.fromCurrency} → ${rate.toCurrency} 환율 수정'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: '환율',
            hintText: '예: 1333.33',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final newRate = double.tryParse(controller.text);
              if (newRate != null) {
                await ref.read(exchangeRateServiceProvider).updateRate(
                  fromCurrency: rate.fromCurrency,
                  toCurrency: rate.toCurrency,
                  rate: newRate,
                );
                ref.refresh(allExchangeRatesProvider);
                Navigator.pop(context);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}

/// Provider
final allExchangeRatesProvider = FutureProvider<List<ExchangeRate>>((ref) async {
  final db = ref.watch(databaseProvider);
  return (db.select(db.exchangeRates)
        ..where((r) => r.isActive.equals(true))
        ..orderBy([(r) => OrderingTerm.asc(r.fromCurrency)]))
      .get();
});
```

## 8. UI Component Updates

### 8.1 Localized Text Usage

```dart
// Before (Hardcoded)
Text('장바구니'),

// After (Localized)
Text(AppLocalizations.of(context)!.cart),

// Or with extension
Text(context.l10n.cart),
```

### 8.2 Price Display Widget

```dart
// lib/core/widgets/price_text.dart
class PriceText extends ConsumerWidget {
  final double priceInKRW;
  final TextStyle? style;
  final bool showSymbol;

  const PriceText({
    super.key,
    required this.priceInKRW,
    this.style,
    this.showSymbol = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = ref.watch(priceFormatterProvider);
    final formattedPrice = formatter.formatSimple(priceInKRW);

    return Text(
      formattedPrice,
      style: style,
    );
  }
}

// Usage
PriceText(
  priceInKRW: product.price,
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
)
```

## 9. Implementation Order

### Phase 1: 기본 인프라 (Day 1-2)
1. ✅ 패키지 추가 (`flutter_localizations`, `intl`, `shared_preferences`)
2. ✅ ARB 파일 생성 (3개 언어)
3. ✅ `LocaleProvider` 구현
4. ✅ `CurrencyProvider` 구현
5. ✅ `PriceFormatter` 서비스 구현
6. ✅ `main.dart` 설정 업데이트

### Phase 2: 데이터베이스 확장 (Day 3-4)
1. ✅ Drift 테이블 정의 (`ProductTranslations`, `ExchangeRates`, `AppSettings`)
2. ✅ 마이그레이션 스크립트 작성 (v2 → v3)
3. ✅ Drift 코드 생성 (`dart run build_runner build`)
4. ✅ `ProductTranslationService` 구현
5. ✅ 기본 환율 데이터 시드

### Phase 3: UI 다국어화 (Day 5-7)
1. ✅ 모든 하드코딩 텍스트 → ARB 키로 변경
2. ✅ `PriceText` 위젯 구현 및 적용
3. ✅ 상품 등록/수정 UI에 다국어 입력 추가
4. ✅ 영수증 화면 다국어 적용
5. ✅ 모든 화면 테스트 (3개 언어)

### Phase 4: 설정 UI (Day 8-9)
1. ✅ `LocaleSettingsScreen` 구현
2. ✅ `ExchangeRateScreen` 구현
3. ✅ 설정 탭에 통합
4. ✅ 언어/통화 선택 다이얼로그 구현

### Phase 5: 테스트 및 최적화 (Day 10)
1. ✅ 각 언어/통화 조합 테스트
2. ✅ 데이터 마이그레이션 테스트
3. ✅ 성능 최적화 (번역 캐싱 등)
4. ✅ 버그 수정 및 문서 작성

## 10. Testing Strategy

### 10.1 Unit Tests
```dart
// test/services/price_formatter_test.dart
void main() {
  group('PriceFormatter', () {
    test('KRW formatting', () {
      final formatter = PriceFormatter(
        currency: AppCurrency.krw,
        exchangeRate: 1.0,
      );
      expect(formatter.formatSimple(1000), '₩1,000');
    });

    test('USD formatting with conversion', () {
      final formatter = PriceFormatter(
        currency: AppCurrency.usd,
        exchangeRate: 0.00075,
      );
      expect(formatter.formatSimple(1000), '\$0.75');
    });

    test('VND formatting', () {
      final formatter = PriceFormatter(
        currency: AppCurrency.vnd,
        exchangeRate: 19.5,
      );
      expect(formatter.formatSimple(1000), '₫19,500');
    });
  });
}
```

### 10.2 Widget Tests
```dart
// test/widgets/price_text_test.dart
void main() {
  testWidgets('PriceText displays formatted price', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currencyProvider.overrideWith((ref) => AppCurrency.usd),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PriceText(priceInKRW: 1000),
          ),
        ),
      ),
    );

    expect(find.text('\$0.75'), findsOneWidget);
  });
}
```

### 10.3 Integration Tests
- [ ] 언어 전환 후 모든 화면 텍스트 변경 확인
- [ ] 통화 전환 후 모든 가격 표시 확인
- [ ] 상품 다국어 입력 및 조회 확인
- [ ] 환율 변경 후 가격 업데이트 확인
- [ ] 데이터베이스 마이그레이션 무결성 확인

## 11. Performance Considerations

### 11.1 Optimization Strategies
1. **번역 캐싱**: `AppLocalizations` 자동 캐싱 활용
2. **Provider Memoization**: 환율 Provider는 family로 캐싱
3. **Lazy Loading**: 상품 번역은 필요 시에만 로드
4. **Batch Updates**: 통화 변경 시 rebuild 최소화

### 11.2 Memory Management
- ARB 파일은 컴파일 타임에 로드되어 메모리 효율적
- 환율 데이터는 Provider로 캐싱
- 상품 번역은 FutureProvider로 필요 시 로드

## 12. Error Handling

### 12.1 Fallback Strategies
```dart
// 번역 없을 때 기본 언어로 Fallback
String getLocalizedProductName(Product product, String languageCode) {
  final translation = await getTranslation(product.id, languageCode);
  return translation ?? product.name;  // Fallback to Korean
}

// 환율 조회 실패 시 기본 환율 사용
double getExchangeRate(String currency) {
  try {
    return await fetchRate(currency);
  } catch (e) {
    return AppCurrency.fromCode(currency).defaultRate;
  }
}
```

### 12.2 Migration Error Handling
```dart
// 마이그레이션 실패 시 롤백
try {
  await _migrateToV3();
} catch (e) {
  logger.error('Migration failed: $e');
  await _rollbackToV2();
  rethrow;
}
```

## 13. Documentation

### 13.1 Developer Guide
- ARB 파일 작성 가이드
- 새 언어 추가 방법
- 새 통화 추가 방법
- 상품 번역 추가 방법

### 13.2 User Guide
- 언어 변경 방법
- 통화 변경 방법
- 환율 설정 방법
- 다국어 상품 등록 방법

## 14. Future Enhancements

### 14.1 Planned Features
- [ ] 실시간 환율 API 연동
- [ ] 자동 번역 제안
- [ ] 언어별 키보드 레이아웃
- [ ] 지역별 세금 정책 지원

## 15. Approval & Next Steps

### 15.1 Design Review Checklist
- [ ] 아키텍처 검토 완료
- [ ] 데이터베이스 스키마 승인
- [ ] API 설계 승인
- [ ] UI/UX 가이드 승인

### 15.2 Ready for Implementation
Design 문서 승인 후:
```bash
# Implementation 시작
/pdca do i18n-multi-currency
```

---

**Design Document Version**: 1.0
**Last Updated**: 2026-02-06
**Status**: Ready for Review

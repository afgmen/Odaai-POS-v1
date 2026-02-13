import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/currency.dart';
import '../core/services/price_formatter.dart';
import 'database_providers.dart';

/// 현재 통화 Provider
final currencyProvider = StateNotifierProvider<CurrencyNotifier, AppCurrency>((ref) {
  return CurrencyNotifier(ref);
});

class CurrencyNotifier extends StateNotifier<AppCurrency> {
  final Ref ref;

  CurrencyNotifier(this.ref) : super(AppCurrency.vnd) {
    _loadSavedCurrency();
  }

  Future<void> _loadSavedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyCode = prefs.getString('currency_code') ?? 'VND';
    print('🔍 [CurrencyProvider] Loading currency: $currencyCode');
    state = AppCurrency.fromCode(currencyCode);
    print('✅ [CurrencyProvider] Loaded currency: ${state.code} ${state.symbol}');
  }

  Future<void> setCurrency(AppCurrency currency) async {
    print('💰 [CurrencyProvider] Setting currency to: ${currency.code} ${currency.symbol}');
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', currency.code);
    print('✅ [CurrencyProvider] Currency saved to SharedPreferences');

    // DB에도 저장 (AppSettings 테이블 추가 후 활성화)
    // final db = ref.read(databaseProvider);
    // await db.updateCurrencySetting(currency.code);
  }
}

/// 환율 Provider (데이터베이스 연동 전까지는 기본 환율 사용)
final exchangeRateProvider = Provider.family<double, String>((ref, toCurrency) {
  // TODO: 데이터베이스에서 환율 조회
  // final db = ref.watch(databaseProvider);
  // return db.getExchangeRate('VND', toCurrency);

  // 임시: 기본 환율 사용
  return AppCurrency.fromCode(toCurrency).defaultRate;
});

/// Price Formatter Provider
final priceFormatterProvider = Provider<PriceFormatter>((ref) {
  final currency = ref.watch(currencyProvider);
  final exchangeRate = ref.watch(exchangeRateProvider(currency.code));

  return PriceFormatter(
    currency: currency,
    exchangeRate: exchangeRate,
  );
});

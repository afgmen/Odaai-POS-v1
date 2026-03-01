import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/currency.dart';
import '../core/services/price_formatter.dart';

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
    debugPrint('🔍 [CurrencyProvider] Loading currency: $currencyCode');
    state = AppCurrency.fromCode(currencyCode);
    debugPrint('✅ [CurrencyProvider] Loaded currency: ${state.code} ${state.symbol}');
  }

  Future<void> setCurrency(AppCurrency currency) async {
    debugPrint('💰 [CurrencyProvider] Setting currency to: ${currency.code} ${currency.symbol}');
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', currency.code);
    debugPrint('✅ [CurrencyProvider] Currency saved to SharedPreferences');

    // DB에도 저장 (AppSettings 테이블 추가 후 활성화)
    // final db = ref.read(databaseProvider);
    // await db.updateCurrencySetting(currency.code);
  }
}

/// Exchange Rate Service
final exchangeRateServiceProvider = Provider<ExchangeRateService>((ref) {
  return ExchangeRateService();
});

/// 환율 Provider (SharedPreferences 연동)
final exchangeRateProvider = FutureProvider.family<double, String>((ref, toCurrency) async {
  final service = ref.watch(exchangeRateServiceProvider);
  final fromCurrency = ref.watch(currencyProvider).code;
  
  // Load from SharedPreferences, fallback to default rate
  final rate = await service.getExchangeRate(fromCurrency, toCurrency);
  return rate ?? AppCurrency.fromCode(toCurrency).defaultRate;
});

/// Exchange Rate Service
class ExchangeRateService {
  /// Save exchange rate to SharedPreferences
  Future<void> saveExchangeRate(String fromCurrency, String toCurrency, double rate) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'exchange_rate_${fromCurrency}_$toCurrency';
    await prefs.setDouble(key, rate);
    debugPrint('💱 [ExchangeRate] Saved: $fromCurrency → $toCurrency = $rate');
  }

  /// Load exchange rate from SharedPreferences
  Future<double?> getExchangeRate(String fromCurrency, String toCurrency) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'exchange_rate_${fromCurrency}_$toCurrency';
    final rate = prefs.getDouble(key);
    
    if (rate != null) {
      debugPrint('💱 [ExchangeRate] Loaded: $fromCurrency → $toCurrency = $rate');
    } else {
      debugPrint('💱 [ExchangeRate] Not found: $fromCurrency → $toCurrency (using default)');
    }
    
    return rate;
  }

  /// Get all saved exchange rates
  Future<Map<String, double>> getAllExchangeRates() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('exchange_rate_'));
    
    final Map<String, double> rates = {};
    for (final key in keys) {
      final rate = prefs.getDouble(key);
      if (rate != null) {
        rates[key.replaceFirst('exchange_rate_', '')] = rate;
      }
    }
    
    return rates;
  }
}

/// Price Formatter Provider
final priceFormatterProvider = Provider<PriceFormatter>((ref) {
  final currency = ref.watch(currencyProvider);
  
  // Try to get saved exchange rate, fallback to default
  final exchangeRateAsync = ref.watch(exchangeRateProvider(currency.code));
  final exchangeRate = exchangeRateAsync.maybeWhen(
    data: (rate) => rate,
    orElse: () => currency.defaultRate,
  );

  return PriceFormatter(
    currency: currency,
    exchangeRate: exchangeRate,
  );
});

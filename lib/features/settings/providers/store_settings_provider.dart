import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../user_guide/presentation/providers/tutorial_preference_provider.dart';

/// Keys for store settings in SharedPreferences
class StoreSettingsKeys {
  static const storeName = 'store_name';
  static const storePhone = 'store_phone';
  static const storeAddress = 'store_address';
  static const receiptFooter = 'receipt_footer';
  static const showQrCode = 'show_qr_code';
  static const taxEnabled = 'tax_enabled';
  static const taxRate = 'tax_rate';
  static const taxInclusive = 'tax_inclusive';
}

class StoreSettingsNotifier extends Notifier<Map<String, dynamic>> {
  @override
  Map<String, dynamic> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return {
      StoreSettingsKeys.storeName:
          prefs.getString(StoreSettingsKeys.storeName) ?? 'Oda POS',
      StoreSettingsKeys.storePhone:
          prefs.getString(StoreSettingsKeys.storePhone) ?? '',
      StoreSettingsKeys.storeAddress:
          prefs.getString(StoreSettingsKeys.storeAddress) ?? '',
      StoreSettingsKeys.receiptFooter:
          prefs.getString(StoreSettingsKeys.receiptFooter) ?? '',
      StoreSettingsKeys.showQrCode:
          prefs.getBool(StoreSettingsKeys.showQrCode) ?? false,
      StoreSettingsKeys.taxEnabled:
          prefs.getBool(StoreSettingsKeys.taxEnabled) ?? true,
      StoreSettingsKeys.taxRate:
          prefs.getDouble(StoreSettingsKeys.taxRate) ?? 10.0,
      StoreSettingsKeys.taxInclusive:
          prefs.getBool(StoreSettingsKeys.taxInclusive) ?? true,
    };
  }

  Future<void> setString(String key, String value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(key, value);
    state = {...state, key: value};
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(key, value);
    state = {...state, key: value};
  }

  Future<void> setDouble(String key, double value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(key, value);
    state = {...state, key: value};
  }
}

final storeSettingsProvider =
    NotifierProvider<StoreSettingsNotifier, Map<String, dynamic>>(
  StoreSettingsNotifier.new,
);

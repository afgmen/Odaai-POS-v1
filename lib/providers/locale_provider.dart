import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database_providers.dart';

/// Language enumeration
enum AppLanguage {
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
      orElse: () => AppLanguage.en,
    );
  }
}

/// Current locale Provider
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final Ref ref;

  LocaleNotifier(this.ref) : super(const Locale('en')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    state = Locale(languageCode);
  }

  Future<void> setLocale(AppLanguage language) async {
    state = language.locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', language.code);

    // Also save to DB (activate after AppSettings table is added)
    // final db = ref.read(databaseProvider);
    // await db.updateLanguageSetting(language.code);
  }
}

/// Current language Provider
final currentLanguageProvider = Provider<AppLanguage>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLanguage.fromCode(locale.languageCode);
});

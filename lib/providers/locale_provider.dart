import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database_providers.dart';

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

    // DB에도 저장 (AppSettings 테이블 추가 후 활성화)
    // final db = ref.read(databaseProvider);
    // await db.updateLanguageSetting(language.code);
  }
}

/// 현재 언어 Provider
final currentLanguageProvider = Provider<AppLanguage>((ref) {
  final locale = ref.watch(localeProvider);
  return AppLanguage.fromCode(locale.languageCode);
});

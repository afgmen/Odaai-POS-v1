import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/pin_login_screen.dart';
import 'providers/locale_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: OdaPosApp(),
    ),
  );
}

class OdaPosApp extends ConsumerWidget {
  const OdaPosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Oda POS',
      debugShowCheckedModeBanner: false,

      // Localization configuration
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Supported locales
      supportedLocales: const [
        Locale('en', ''),  // English (default)
        Locale('ko', ''),  // Korean
        Locale('vi', ''),  // Vietnamese
      ],

      // Current locale
      locale: locale,

      // Locale resolution
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale == null) return supportedLocales.first;

        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == deviceLocale.languageCode) {
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

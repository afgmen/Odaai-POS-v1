import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/pin_login_screen.dart';
import 'features/app_root_screen.dart';
import 'providers/locale_provider.dart';
import 'features/user_guide/presentation/providers/tutorial_preference_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ========================================
  // Global Error Handler (B-084)
  // ========================================
  
  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // Debug mode: Show full error
      FlutterError.presentError(details);
    } else {
      // Release mode: Log only, show friendly message
      debugPrint('Flutter Error: ${details.exception}');
      // Error will be caught by Zone handler
    }
  };

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Run app in error-catching zone
  runZonedGuarded(
    () {
      runApp(
        ProviderScope(
          overrides: [
            // Override the SharedPreferences provider
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ],
          child: const OdaPosApp(),
        ),
      );
    },
    (error, stackTrace) {
      if (kDebugMode) {
        // Debug mode: Print full error
        debugPrint('Zone Error: $error');
        debugPrint('Stack trace: $stackTrace');
      } else {
        // Release mode: Log sanitized error
        final sanitizedError = _sanitizeError(error);
        debugPrint('Error occurred: $sanitizedError');
      }
    },
  );
}

/// Sanitize error messages for production
String _sanitizeError(Object error) {
  final errorString = error.toString().toLowerCase();
  
  // Hide SQL-specific errors
  if (errorString.contains('sqlite') || 
      errorString.contains('sql') ||
      errorString.contains('database')) {
    return 'Database error occurred';
  }
  
  // Hide stack traces and technical details
  if (errorString.contains('exception:') || 
      errorString.contains('error:')) {
    return 'An error occurred';
  }
  
  return 'Unexpected error';
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

      // Route configuration
      routes: {
        '/home': (context) => const AppRootScreen(),
      },
    );
  }
}

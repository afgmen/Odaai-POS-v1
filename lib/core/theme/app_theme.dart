import 'package:flutter/material.dart';

/// Oda POS 앱 테마 정의 (토스 POS 스타일 참고)
class AppTheme {
  // ─── 색상 상수 ──────────────────────────────────
  static const Color primary = Color(0xFF3182F6);        // 파란색
  static const Color primaryDark = Color(0xFF1A6BE0);
  static const Color success = Color(0xFF03B26C);        // 초록
  static const Color successDark = Color(0xFF028A53);
  static const Color error = Color(0xFFE53935);          // 빨강
  static const Color warning = Color(0xFFFFA726);        // 주황
  static const Color background = Color(0xFFF5F5F7);     // 배경 라이트 그레이
  static const Color cardWhite = Color(0xFFFFFFFF);      // 카드 흰색
  static const Color divider = Color(0xFFE8E8EA);        // 구분선
  static const Color textPrimary = Color(0xFF1A1A1A);    // 본문 텍스트
  static const Color textSecondary = Color(0xFF6B7280);  // 세컨더리 텍스트
  static const Color textDisabled = Color(0xFFAEB5BC);   // 비활성 텍스트
  static const Color iconColor = Color(0xFF6B7280);      // 아이콘

  // ─── Light Theme ────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        primaryContainer: Color(0xFFE8F0FE),
        onPrimary: Colors.white,
        onPrimaryContainer: primary,
        secondary: success,
        secondaryContainer: Color(0xFFE6FAF2),
        onSecondary: Colors.white,
        onSecondaryContainer: success,
        error: error,
        onError: Colors.white,
        errorContainer: Color(0xFFFDEBEB),
        onErrorContainer: error,
        surface: cardWhite,
        onSurface: textPrimary,
        surfaceContainerHighest: background,
        onSurfaceVariant: textSecondary,
        outline: divider,
        outlineVariant: Color(0xFFF0F0F2),
      ),
      scaffoldBackgroundColor: background,

      // ─── AppBar ───────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: cardWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),

      // ─── Card ─────────────────────────────────
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: divider, width: 1),
        ),
      ),

      // ─── ElevatedButton ───────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── OutlinedButton ───────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── IconButton ───────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(iconColor),
        ),
      ),

      // ─── TextField ────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(color: textDisabled, fontSize: 14),
      ),

      // ─── Divider ──────────────────────────────
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        indent: 0,
        endIndent: 0,
      ),

      // ─── Typography ───────────────────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
        labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textDisabled),
      ),
    );
  }
}

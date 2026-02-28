import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'oda_colors.dart';

/// Oda POS 앱 테마 정의 (토스 POS 스타일 참고)
class AppTheme {
  // ─── 색상 상수 ──────────────────────────────────
  static const Color primary = Color(0xFF3182F6);        // 파란색
  static const Color primaryDark = Color(0xFF1A6BE0);
  static const Color success = OdaColors.green600;        // #35974F
  static const Color successDark = OdaColors.green700;    // #2A793F
  static const Color error = Color(0xFFE53935);          // 빨강
  static const Color warning = OdaColors.orange500;       // #E58435
  static const Color info = OdaColors.blue400;            // #2196F3
  static const Color background = Color(0xFFF5F5F7);     // 배경 라이트 그레이
  static const Color cardWhite = Color(0xFFFFFFFF);      // 카드 흰색
  static const Color divider = OdaColors.neutral80;       // #B9B9C3
  static const Color textPrimary = Color(0xFF1A1A1A);    // 본문 텍스트
  static const Color textSecondary = Color(0xFF6B7280);  // 세컨더리 텍스트
  static const Color textDisabled = Color(0xFFAEB5BC);   // 비활성 텍스트
  static const Color iconColor = Color(0xFF6B7280);      // 아이콘

  // ─── Light Theme ────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.notoSans().fontFamily,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        primaryContainer: Color(0xFFE8F0FE),
        onPrimary: Colors.white,
        onPrimaryContainer: primary,
        secondary: success,
        secondaryContainer: OdaColors.green60,
        onSecondary: Colors.white,
        onSecondaryContainer: success,
        error: error,
        onError: Colors.white,
        errorContainer: OdaColors.red80,
        onErrorContainer: error,
        surface: cardWhite,
        onSurface: textPrimary,
        surfaceContainerHighest: background,
        onSurfaceVariant: textSecondary,
        outline: divider,
        outlineVariant: OdaColors.neutral40,
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
        displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w500, color: textPrimary, height: 48/34),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w500, color: textPrimary, height: 40/28),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary, height: 32/22),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary, height: 28/20),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary, height: 24/18),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary, height: 24/16),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary, height: 24/16),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary, height: 24/16),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary, height: 24/16),
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary, height: 20/15),
        bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary, height: 20/14),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary, height: 20/15),
        labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary, height: 20/14),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary, height: 16/12),
      ),
    );
  }
}

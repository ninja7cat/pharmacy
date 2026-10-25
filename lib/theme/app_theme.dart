import 'package:flutter/material.dart';

class AppTheme {
  // ─────────────────────────────────────────────
  // Typeface
  // ─────────────────────────────────────────────
  //
  // Cairo covers both Latin and Arabic, so English and Arabic look like one
  // family. Add the font files to assets/fonts and declare them in
  // pubspec.yaml (see the notes that came with this file). If the files are
  // missing the site still works, it just falls back to the default font.

  static const String fontFamily = 'Cairo';
  static const List<String> fontFallback = ['Arial', 'Tahoma', 'sans-serif'];

  // ─────────────────────────────────────────────
  // Brand colors
  // ─────────────────────────────────────────────

  /// Royal blue taken from the logo.
  static const Color primary = Color(0xFF1D4FA3);

  /// Deep navy (#013973), used for dark sections.
  static const Color primaryDark = Color(0xFF013973);
  static const Color primaryLight = Color(0xFF5B86CF);

  /// Bronze (#9b7a50) accent and a lighter bronze for use on dark navy.
  /// (The names `coral` and `sun` are kept so the other files still work.)
  static const Color coral = Color(0xFF9B7A50);
  static const Color sun = Color(0xFFD2B070);

  /// Soft tints used as card / section backgrounds.
  static const Color mint = Color(0xFFDCE6F2); // navy tint
  static const Color mintSoft = Color(0xFFEEF2F7); // lighter navy tint
  static const Color blush = Color(0xFFE3E2DD); // stone tint
  static const Color sunSoft = Color(0xFFF1E8D9); // bronze tint
  static const Color sky = Color(0xFFE6ECF4); // pale navy tint

  /// Light stone (#d4d3ce) and grey (#8c8c8c) from the brand palette.
  static const Color stone = Color(0xFFD4D3CE);
  static const Color silverSoft = Color(0xFFE4E4E2); // silver tint
  static const Color grey = Color(0xFF8C8C8C);

  /// Very dark navy, used for outlines and the footer.
  static const Color ink = Color(0xFF062451);

  // ─────────────────────────────────────────────
  // Metal finishes from the logo
  // ─────────────────────────────────────────────

  /// Brushed silver, like the logo plate.
  static const LinearGradient silver = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF7F7F5),
      Color(0xFFD6D6D3),
      Color(0xFFF0F0EE),
      Color(0xFFBEBEBB),
    ],
  );

  /// Soft gold, like the screws on the logo plate (#9b7a50 family).
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE9D3A0), Color(0xFFB8935C), Color(0xFF9B7A50)],
  );

  // ─────────────────────────────────────────────
  // Background / surface
  // ─────────────────────────────────────────────

  static const Color background = Color(0xFFF6F5F1);
  static const Color surface = Color(0xFFFCFBF9);

  // ─────────────────────────────────────────────
  // Text
  // ─────────────────────────────────────────────

  static const Color textPrimary = Color(0xFF101A2A);
  static const Color textSecondary = Color(0xFF525861);
  static const Color textMuted = Color(0xFF8C8C8C);

  // ─────────────────────────────────────────────
  // Borders
  // ─────────────────────────────────────────────

  static const Color border = Color(0xFFD4D3CE);

  // ─────────────────────────────────────────────
  // Main theme
  // ─────────────────────────────────────────────

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        surface: surface,
      ),
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,

      // The classic ripple is the most reliable choice inside in-app
      // browsers (Instagram, Facebook) where shader effects can misbehave.
      splashFactory: InkRipple.splashFactory,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 64,
          height: 1.02,
          fontWeight: FontWeight.w800,
          letterSpacing: -2,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 48,
          height: 1.05,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.4,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 38,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 34,
          height: 1.15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.9,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.7, color: textSecondary),
        bodyMedium: TextStyle(fontSize: 14, height: 1.6, color: textSecondary),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

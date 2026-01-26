import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Background colors
  static const Color bgDark = Color(0xFF25231F);
  static const Color bg = Color(0xFF2E2C29);
  static const Color bgLight = Color(0xFF3A3833);
  // Light mode backgrounds
  static const Color lightBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  // Text colors
  static const Color text = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFC9C6C1);
  static const Color lightText = Color(0xFF2E2C29);
  static const Color lightTextMuted = Color(0xFF6E6A64);
  // Highlight and border colors
  static const Color highlight = Color(0xFF4A4742);
  static const Color border = Color(0xFF5A5651);
  static const Color borderMuted = Color(0xFF3D3A36);
  // Semantic colors
  static const Color primary = Color(0xFF81B64C);
  static const Color secondary = Color(0xFFA4C88A);
  static const Color danger = Color(0xFFE06C5B);
  static const Color warning = Color(0xFFE3C45B);
  static const Color success = Color(0xFF86C36A);
  static const Color info = Color(0xFF6FB0D6);
}

class AppFonts {
  static final String displayFamily =
      GoogleFonts.nunito().fontFamily ?? 'Nunito';
  static final String bodyFamily =
      GoogleFonts.openSans().fontFamily ?? 'Open Sans';

  static TextStyle display({TextStyle? textStyle}) =>
      GoogleFonts.nunito(textStyle: textStyle);
  static TextStyle body({TextStyle? textStyle}) =>
      GoogleFonts.openSans(textStyle: textStyle);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppFonts.bodyFamily,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        surface: AppColors.bgLight,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.highlight,
        error: AppColors.danger,
        onSurface: AppColors.text,
        onPrimary: AppColors.bgDark,
        onSecondary: AppColors.bgDark,
        onError: AppColors.text,
        inversePrimary: AppColors.primary,
        outline: AppColors.border,
        outlineVariant: AppColors.borderMuted,
      ),

      // Scaffold background
      scaffoldBackgroundColor: AppColors.bg,

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.bgLight,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderMuted),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.bgDark,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.text),
        ),
        displayMedium: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.text),
        ),
        displaySmall: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.text),
        ),
        headlineLarge: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.text),
        ),
        headlineMedium: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.text),
        ),
        headlineSmall: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.text),
        ),
        titleLarge: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.text),
        ),
        titleMedium: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.text),
        ),
        titleSmall: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.text),
        ),
        bodyLarge: AppFonts.body(
          textStyle: const TextStyle(color: AppColors.text),
        ),
        bodyMedium: AppFonts.body(
          textStyle: const TextStyle(color: AppColors.text),
        ),
        bodySmall: AppFonts.body(
          textStyle: const TextStyle(color: AppColors.textMuted),
        ),
        labelLarge: AppFonts.body(
          textStyle: const TextStyle(color: AppColors.text),
        ),
        labelMedium: AppFonts.body(
          textStyle: const TextStyle(color: AppColors.text),
        ),
        labelSmall: AppFonts.body(
          textStyle: const TextStyle(color: AppColors.textMuted),
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: AppColors.text, size: 24),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.bgDark,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.borderMuted,
        thickness: 1,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgLight,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(color: AppColors.text),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderMuted),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppFonts.bodyFamily,
      colorScheme: const ColorScheme.light(
        surface: AppColors.lightSurface,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.highlight,
        error: AppColors.danger,
        onSurface: AppColors.lightText,
        onPrimary: AppColors.lightSurface,
        onSecondary: AppColors.lightSurface,
        onError: AppColors.lightText,
        inversePrimary: AppColors.primary,
        outline: Colors.transparent,
        outlineVariant: Colors.transparent,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightText,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.lightSurface,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        labelStyle: const TextStyle(color: AppColors.lightTextMuted),
        hintStyle: const TextStyle(color: AppColors.lightTextMuted),
      ),
      textTheme: TextTheme(
        displayLarge: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.lightText),
        ),
        displayMedium: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.lightText),
        ),
        displaySmall: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.lightText),
        ),
        headlineLarge: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.lightText),
        ),
        headlineMedium: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.lightText),
        ),
        headlineSmall: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.lightText),
        ),
        titleLarge: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.lightText),
        ),
        titleMedium: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.lightText),
        ),
        titleSmall: AppFonts.display(
          textStyle: const TextStyle(color: AppColors.lightText),
        ),
        bodyLarge: AppFonts.body(
          textStyle: const TextStyle(color: AppColors.lightText),
        ),
        bodyMedium: AppFonts.body(
          textStyle: const TextStyle(color: AppColors.lightText),
        ),
        bodySmall: AppFonts.body(
          textStyle: const TextStyle(color: AppColors.lightTextMuted),
        ),
        labelLarge: AppFonts.body(
          textStyle: const TextStyle(color: AppColors.lightText),
        ),
        labelMedium: AppFonts.body(
          textStyle: const TextStyle(color: AppColors.lightText),
        ),
        labelSmall: AppFonts.body(
          textStyle: const TextStyle(color: AppColors.lightTextMuted),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.lightText, size: 24),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.lightSurface,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightTextMuted,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(color: AppColors.lightText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
      ),
    );
  }

  // Semantic color getters for easy access
  static Color get successColor => AppColors.success;
  static Color get warningColor => AppColors.warning;
  static Color get infoColor => AppColors.info;
  static Color get dangerColor => AppColors.danger;
}

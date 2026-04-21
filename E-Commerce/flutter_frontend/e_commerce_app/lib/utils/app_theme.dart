import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF8F6F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF1A1A1A);
  static const Color accent = Color(0xFFC0A882);
  static const Color muted = Color(0xFF888888);
  static const Color border = Color(0xFFEDE8DF);
  static const Color tagSale = Color(0xFFC0392B);
  static const Color tagNew = Color(0xFF1A1A1A);
  static const Color error = Color(0xFFC0392B);
  static const Color success = Color(0xFF4CAF50);
}

class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Georgia',
    fontWeight: FontWeight.w300,
    fontSize: 36,
    letterSpacing: 2,
    color: AppColors.primary,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Georgia',
    fontWeight: FontWeight.w400,
    fontSize: 24,
    color: AppColors.primary,
  );
  static const TextStyle titleLarge = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 16,
    color: AppColors.primary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.primary,
    height: 1.6,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    letterSpacing: 2,
    color: AppColors.muted,
    fontWeight: FontWeight.w300,
  );
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      background: AppColors.background,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Georgia',
        fontWeight: FontWeight.w300,
        fontSize: 20,
        letterSpacing: 4,
        color: AppColors.primary,
      ),
      iconTheme: IconThemeData(color: AppColors.primary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
    ),
    dividerColor: AppColors.border,
    fontFamily: 'sans-serif',
  );
}

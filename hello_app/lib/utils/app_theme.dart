// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand
  static const Color primary = Color(0xFF00C9A7);
  static const Color primaryDark = Color(0xFF00A98A);
  static const Color primaryLight = Color(0xFF5EFFD8);
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentOrange = Color(0xFFFFB347);
  static const Color purple = Color(0xFF6C63FF);

  // Backgrounds
  static const Color bgDark = Color(0xFF0A0E1A);
  static const Color bgCard = Color(0xFF111827);
  static const Color bgInput = Color(0xFF1C2537);
  static const Color bgBubbleReceived = Color(0xFF1A2847);

  // Text
  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8B9DC3);
  static const Color textHint = Color(0xFF4A5568);

  // Status
  static const Color online = Color(0xFF48BB78);
  static const Color offline = Color(0xFF4A5568);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00C9A7), Color(0xFF0072FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF001F3F), Color(0xFF00C9A7), Color(0xFF0072FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  // Avatar palette
  static const List<List<Color>> avatarGradients = [
    [Color(0xFF00C9A7), Color(0xFF0072FF)],
    [Color(0xFFFF6B6B), Color(0xFFFFB347)],
    [Color(0xFF6C63FF), Color(0xFF00C9A7)],
    [Color(0xFFFF8C94), Color(0xFFA39BD2)],
    [Color(0xFF43CBFF), Color(0xFF9708CC)],
  ];

  static List<Color> avatarColor(String seed) {
    if (seed.isEmpty) return avatarGradients[0];
    return avatarGradients[seed.codeUnitAt(0) % avatarGradients.length];
  }
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark();
    return base.copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.bgCard,
        background: AppColors.bgDark,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        hintStyle: GoogleFonts.poppins(
          color: AppColors.textHint,
          fontSize: 14,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding:
          const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerColor: AppColors.bgInput,
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
    );
  }
}

class AppConstants {
  static const String appName = 'Hello Chat';
  static const String pathUsers = 'users';
  static const String pathChats = 'chats';
  static const String pathMessages = 'messages';
}
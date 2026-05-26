import 'package:flutter/material.dart';

class AppColors {
  // Core Backgrounds
  static const Color bg0 = Color(0xFF060611); // Deep Space
  static const Color bg1 = Color(0xFF0D0D1A); // Space Dark
  static const Color bg2 = Color(0xFF13132A); // Elevated Space
  static const Color bg3 = Color(0xFF1A1A35); // Space Mid

  // Accents
  static const Color primary = Color(0xFF7C3AED); // Violet Core
  static const Color primaryLight = Color(0xFFA855F7); // Violet Light
  static const Color accent = Color(0xFF06B6D4); // Cyan (MARK bot)
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color danger = Color(0xFFEF4444); // Red

  // Text
  static const Color textPrimary = Color(0xFFF8FAFC); // Snow White
  static const Color textSecondary = Color(0xFF94A3B8); // Slate
  static const Color textMuted = Color(0xFF475569);

  // Surfaces
  static const Color surface = Color(0x0AFFFFFF); // White 4%
  static const Color surfaceHover = Color(0x14FFFFFF); // White 8%
  static const Color border = Color(0x14FFFFFF); // White 8%
  static const Color borderGlow = Color(0x667C3AED); // Violet 40%

  // Gradients
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [primary, primaryLight, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientWarm = LinearGradient(
    colors: [warning, danger],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientCool = LinearGradient(
    colors: [accent, success],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientCard = LinearGradient(
    colors: [Color(0x267C3AED), Color(0x1406B6D4)], // Violet 15% to Cyan 8%
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTextStyles {
  // Space Grotesk Headings
  static const TextStyle displayXl = TextStyle(
    fontFamily: 'Space Grotesk',
    fontSize: 72,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayLg = TextStyle(
    fontFamily: 'Space Grotesk',
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: 'Space Grotesk',
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Inter Body
  static const TextStyle h2 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyXl = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.7,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 2.0,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg0,
      primaryColor: AppColors.primary,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.danger,
        surface: AppColors.bg1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.h2,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get dark {
    const background = Color(0xFF121212); // Deep Charcoal Black
    const surface = Color(0xFF1E1E1E); // Elevated Charcoal
    const primary = Color(0xFFC99B6E); // Elegant Copper / Rose Gold
    const accent = Color(0xFFE2C391); // Soft Light Gold
    const border = Color(0xFF2A2A2A); // Subtle Border

    final baseTextTheme = Typography.material2021().englishLike.merge(Typography.material2021().white);

    // Using Plus Jakarta Sans for a premium, geometric fintech feel
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(baseTextTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        surface: surface,
        primary: primary,
        secondary: accent,
        surfaceContainerHighest: surface,
        outlineVariant: border,
      ),
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
        displayMedium: textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
        displaySmall: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
        headlineLarge: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
        headlineMedium: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        headlineSmall: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

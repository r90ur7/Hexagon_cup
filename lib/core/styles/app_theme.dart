import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Cores extraídas do CSS real do hexagonsports.com.br
class HexColors {
  static const primary = Color(0xFFFF7500);
  static const primaryDark = Color(0xFFFF1600);
  static const success = Color(0xFF4CAF50); // vitória
  static const warning = Color(0xFFFF9800); // empate
  static const danger = Color(0xFFFF4B4B); // derrota / erro
  static const bg = Color(0xFF01050B); // fundo do body
  static const surface = Color(0xFF000813); // fundo de cards
  static const surfaceElevated = Color(0xFF0D1117); // cards elevados
  static const border = Color(0x26FF7500); // rgba(255,117,0,0.15)
  static const textPrimary = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFFE0E0E0);
  static const textSubtle = Color(0xFF888888);
  static const cardHighlight = Color(0x1AFF5A23); // fundo de info cards
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.montserrat().fontFamily,
    scaffoldBackgroundColor: HexColors.bg,
    colorScheme: ColorScheme.dark(
      primary: HexColors.primary,
      secondary: HexColors.primaryDark,
      surface: HexColors.surface,
      error: HexColors.danger,
      onPrimary: Colors.white,
      onSurface: HexColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: HexColors.surface,
      foregroundColor: HexColors.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: HexColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: HexColors.border),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: HexColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HexColors.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: HexColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: HexColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: HexColors.primary, width: 2),
      ),
      labelStyle: const TextStyle(color: HexColors.textMuted),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: HexColors.primary,
      unselectedLabelColor: HexColors.textSubtle,
      indicatorColor: HexColors.primary,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: HexColors.primary,
      foregroundColor: Colors.white,
    ),
    dividerTheme: const DividerThemeData(color: HexColors.border),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: HexColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: TextStyle(
        color: HexColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: TextStyle(
        color: HexColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: HexColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: HexColors.textMuted),
      bodyMedium: TextStyle(color: HexColors.textMuted),
      labelSmall: TextStyle(color: HexColors.textSubtle),
    ),
  );
}

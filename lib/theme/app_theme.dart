import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const _background = Color(0xFF0D0D0F);
  static const _surface = Color(0xFF1A1A1E);
  static const _surfaceVariant = Color(0xFF252529);
  static const _primary = Color(0xFFFF6B00);
  static const _secondary = Color(0xFF00C853);
  static const _tertiary = Color(0xFFAA00FF);
  static const _error = Color(0xFFFF1744);
  static const _onSurface = Color(0xFFFFFFFF);
  static const _onSurfaceVariant = Color(0xFF9E9E9E);

  static ThemeData get dark {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _background,
      colorScheme: const ColorScheme.dark(
        surface: _surface,
        surfaceContainerHighest: _surfaceVariant,
        primary: _primary,
        secondary: _secondary,
        tertiary: _tertiary,
        error: _error,
        onSurface: _onSurface,
        onSurfaceVariant: _onSurfaceVariant,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: _surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _surface,
        selectedItemColor: _primary,
        unselectedItemColor: _onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}

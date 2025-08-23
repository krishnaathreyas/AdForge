import 'package:flutter/material.dart';

class AppTheme {
  // Define colors for the "Samsung Tech Blue" Light Theme
  static const Color _lightPrimaryColor =
      Color(0xFF0C4DA2); // Samsung-like Blue
  static const Color _lightSecondaryColor =
      Color(0xFF5F6368); // Professional Gray
  static const Color _lightSurfaceColor = Color(0xFFF5F7F9); // Clean Off-White
  static const Color _lightErrorColor = Color(0xFFB00020);

  // Define colors for the "Samsung Tech Blue" Dark Theme
  static const Color _darkPrimaryColor =
      Color(0xFF4A90E2); // Lighter, vibrant blue for dark mode
  static const Color _darkSecondaryColor =
      Color(0xFFB0B0B0); // Light Gray for accents
  static const Color _darkSurfaceColor =
      Color(0xFF121212); // Standard dark surface
  static const Color _darkErrorColor = Color(0xFFCF6679);

  // --- LIGHT THEME ---
  static final ThemeData lightTheme =
      ThemeData.light(useMaterial3: true).copyWith(
    colorScheme: const ColorScheme.light(
      primary: _lightPrimaryColor,
      secondary: _lightSecondaryColor,
      surface: _lightSurfaceColor,
      error: _lightErrorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: _lightSurfaceColor,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: _lightPrimaryColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    // THIS IS THE CORRECTED LINE
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  // --- DARK THEME ---
  static final ThemeData darkTheme =
      ThemeData.dark(useMaterial3: true).copyWith(
    colorScheme: const ColorScheme.dark(
      primary: _darkPrimaryColor,
      secondary: _darkSecondaryColor,
      surface: _darkSurfaceColor,
      error: _darkErrorColor,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onError: Colors.black,
    ),
    scaffoldBackgroundColor: _darkSurfaceColor,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimaryColor,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    // THIS IS THE CORRECTED LINE
    cardTheme: CardThemeData(
      elevation: 2,
      color: const Color(0xFF1E1E1E), // Slightly lighter than background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}

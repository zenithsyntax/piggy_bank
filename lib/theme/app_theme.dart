import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color _primaryColor = Color(0xFF6C63FF); // Modern Indigo
  static const Color _secondaryColor = Color(0xFF03DAC5); // Teal Accent
  static const Color _backgroundColor = Color(0xFF121212); // Deep Dark Background
  static const Color _surfaceColor = Color(0xFF1E1E1E); // Card/Surface Color
  static const Color _errorColor = Color(0xFFCF6679);
  static const Color _onSurfaceColor = Color(0xFFE0E0E0);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _backgroundColor,
    primaryColor: _primaryColor,
    
    colorScheme: const ColorScheme.dark(
      primary: _primaryColor,
      secondary: _secondaryColor,
      surface: _surfaceColor,
      error: _errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: _onSurfaceColor,
      background: _backgroundColor,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: _backgroundColor, // Blend with scaffold
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: Colors.white70),
    ),

    cardTheme: CardThemeData(
      color: _surfaceColor,
      elevation: 4,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0), // Clean default margins
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surfaceColor,
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      showUnselectedLabels: true,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      hintStyle: TextStyle(color: Colors.grey[600]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _errorColor, width: 1.5),
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        elevation: 2,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _secondaryColor,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
      titleLarge: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      titleMedium: TextStyle(fontWeight: FontWeight.w500, color: Colors.white70),
      bodyLarge: TextStyle(color: _onSurfaceColor),
      bodyMedium: TextStyle(color: Colors.grey),
    ),
    
    dividerTheme: const DividerThemeData(
      color: Color(0xFF424242),
      thickness: 1,
    ),
  );
}

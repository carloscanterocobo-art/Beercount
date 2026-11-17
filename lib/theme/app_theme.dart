import 'package:flutter/material.dart';

class AppTheme {
  // Colores principales
  static const Color background = Color(0xFF0B1424);
  static const Color surface = Color(0xFF122139);
  static const Color card = Color(0xFF1A2D49);
  static const Color surfaceHighlight = Color(0xFF243B5B);

  // Colores de identidad
  static const Color primary = Color(0xFFE9A83B);
  static const Color textPrimary = Color(0xFFF4F0E8);
  static const Color textSecondary = Color(0xFFA5B2C5);

  // Colores de acciones
  static const Color success = Color(0xFF56B88A);
  static const Color danger = Color(0xFFE56868);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: background,

      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: background,
        secondary: success,
        surface: surface,
        onSurface: textPrimary,
        error: danger,
        onError: textPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
      ),

      dividerTheme: const DividerThemeData(
        color: surfaceHighlight,
        thickness: 1,
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
        bodySmall: TextStyle(color: textSecondary),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

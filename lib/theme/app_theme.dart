import 'package:flutter/material.dart';

class AppTheme {
  static const Color deepBlue = Color(0xFF0A3A66);
  static const Color cyan = Color(0xFF00BCD4);
  static const Color successGreen = Color(0xFF2EAF61);
  static const Color lightBackground = Color(0xFFF4F7FB);
  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkSurface = Color(0xFF131C2E);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: deepBlue,
      brightness: Brightness.light,
      primary: deepBlue,
      secondary: cyan,
      tertiary: successGreen,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: deepBlue),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: cyan.withValues(alpha: 0.18),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1F3A5A),
        contentTextStyle: const TextStyle(
          color: Color(0xFFF3F8FF),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: const Color(0xFFBDEEFF),
        closeIconColor: const Color(0xFFEAF4FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: cyan,
      brightness: Brightness.dark,
      primary: const Color(0xFF65D7E8),
      secondary: const Color(0xFF40C4FF),
      tertiary: const Color(0xFF56D987),
      surface: darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF233149),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(
          color: Color(0xFFEAF1FF),
          fontSize: 15,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFBDEEFF)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: darkSurface,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: cyan.withValues(alpha: 0.22),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2B4E78),
        contentTextStyle: const TextStyle(
          color: Color(0xFFF3F8FF),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: const Color(0xFFBDEEFF),
        closeIconColor: const Color(0xFFEAF4FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

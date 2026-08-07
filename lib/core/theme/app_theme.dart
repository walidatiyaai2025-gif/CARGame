import 'package:flutter/material.dart';

class AppTheme {
  static const navy = Color(0xFF102A43);
  static const navyLight = Color(0xFF243B53);
  static const blue = Color(0xFF2F80ED);
  static const orange = Color(0xFFFF9F1C);
  static const yellow = Color(0xFFFFD166);
  static const green = Color(0xFF20C997);
  static const red = Color(0xFFFF5D73);
  static const cream = Color(0xFFF4F8FC);
  static const panel = Color(0xFFFFFFFF);
  static const muted = Color(0xFF829AB1);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1F35), Color(0xFF174A7E), Color(0xFF2F80ED)],
  );

  static const orangeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFC15A), Color(0xFFFF8A00)],
  );

  static const softShadow = [
    BoxShadow(color: Color(0x1F102A43), blurRadius: 24, offset: Offset(0, 12)),
  ];

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: Brightness.light,
      primary: navy,
      secondary: orange,
      surface: panel,
      error: red,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: cream,
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -1.2,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w900,
          letterSpacing: -.5,
        ),
        titleLarge: TextStyle(fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: navy,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: navy,
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
      ),
      cardTheme: const CardThemeData(
        color: panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: panel,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        labelStyle: const TextStyle(color: navy, fontWeight: FontWeight.w900),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: orange,
          minimumSize: const Size.fromHeight(62),
          elevation: 8,
          shadowColor: const Color(0x66FF8A00),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: Color(0xFFD9E2EC), width: 1.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

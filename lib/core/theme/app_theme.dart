import 'package:flutter/material.dart';

class AppTheme {
  static const navy = Color(0xFF12233F);
  static const orange = Color(0xFFFF9F1C);
  static const cream = Color(0xFFFFF8EC);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: orange,
          primary: navy,
          secondary: orange,
          surface: cream,
        ),
        scaffoldBackgroundColor: cream,
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      );
}

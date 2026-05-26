import 'package:flutter/material.dart';

/// Global Material 3 theme for DayLinx.
class AppTheme {
  AppTheme._();

  static const Color _seedColor = Color(0xFF5C6BC0);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: brightness,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}

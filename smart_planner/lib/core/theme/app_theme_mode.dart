import 'package:flutter/material.dart';

/// Persisted theme mode codes and picker labels for the settings screen.
abstract final class AppThemeMode {
  static const String systemCode = 'system';
  static const String lightCode = 'light';
  static const String darkCode = 'dark';

  static const List<String> pickerCodes = <String>[
    systemCode,
    lightCode,
    darkCode,
  ];

  static String codeForPicker(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => systemCode,
      ThemeMode.light => lightCode,
      ThemeMode.dark => darkCode,
    };
  }

  static ThemeMode themeModeFromCode(String? code) {
    return switch (code) {
      lightCode => ThemeMode.light,
      darkCode => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// Dropdown label key (translate with [context.tr]).
  static String pickerLabelKey(String code) {
    return switch (code) {
      systemCode => 'theme_system',
      lightCode => 'theme_light',
      darkCode => 'theme_dark',
      _ => 'theme_system',
    };
  }
}

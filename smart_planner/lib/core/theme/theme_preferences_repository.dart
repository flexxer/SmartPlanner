import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_planner/core/theme/app_theme_mode.dart';

/// Persists the user's theme choice and notifies [MaterialApp] to rebuild.
class ThemePreferencesRepository {
  ThemePreferencesRepository({SharedPreferences? preferences})
      : _preferencesFuture = preferences != null
            ? Future<SharedPreferences>.value(preferences)
            : SharedPreferences.getInstance();

  static const String _keyThemeMode = 'app_theme_mode';

  final Future<SharedPreferences> _preferencesFuture;

  final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  Future<void> load() async {
    themeMode.value = await getSavedThemeMode();
  }

  Future<ThemeMode> getSavedThemeMode() async {
    final SharedPreferences prefs = await _preferencesFuture;
    return AppThemeMode.themeModeFromCode(prefs.getString(_keyThemeMode));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode.value == mode) {
      return;
    }
    themeMode.value = mode;

    final SharedPreferences prefs = await _preferencesFuture;
    await prefs.setString(_keyThemeMode, AppThemeMode.codeForPicker(mode));
  }
}

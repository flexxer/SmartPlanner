import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_planner/core/localization/app_locales.dart';

/// Persists the user's manual language choice (`null` = follow device locale).
class LocalePreferencesRepository {
  static const String _keyLanguageCode = 'app_locale_language_code';

  Future<Locale?> getSavedLocale() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? code = prefs.getString(_keyLanguageCode);
    return AppLocales.localeFromLanguageCode(code);
  }

  Future<void> saveLocale(Locale? locale) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String code = AppLocales.languageCodeForPicker(locale);
    if (code.isEmpty) {
      await prefs.remove(_keyLanguageCode);
      return;
    }
    await prefs.setString(_keyLanguageCode, code);
  }
}

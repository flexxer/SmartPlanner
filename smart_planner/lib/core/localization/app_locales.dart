import 'package:flutter/material.dart';

/// Supported application locales and display labels for the settings picker.
abstract final class AppLocales {
  static const Locale fallback = Locale('en');

  static const List<Locale> supported = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('es'),
  ];

  /// BCP-47 language code persisted in preferences (`null` = follow system).
  static const String systemLanguageCode = '';

  static String languageCodeForPicker(Locale? locale) {
    if (locale == null) {
      return systemLanguageCode;
    }
    return locale.languageCode;
  }

  static Locale? localeFromLanguageCode(String? code) {
    if (code == null || code.isEmpty || code == systemLanguageCode) {
      return null;
    }
    for (final Locale locale in supported) {
      if (locale.languageCode == code) {
        return locale;
      }
    }
    return null;
  }

  /// Dropdown label key (translate with [context.tr]).
  static String pickerLabelKey(String languageCode) {
    return switch (languageCode) {
      systemLanguageCode => 'language_system',
      'en' => 'language_en',
      'ru' => 'language_ru',
      'es' => 'language_es',
      _ => 'language_system',
    };
  }
}

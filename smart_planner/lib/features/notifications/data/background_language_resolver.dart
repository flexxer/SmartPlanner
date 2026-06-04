import 'dart:ui' show PlatformDispatcher;

import 'package:smart_planner/core/localization/app_locales.dart';
import 'package:smart_planner/core/localization/locale_preferences_repository.dart';

/// Resolves the active language code in background isolates.
abstract final class BackgroundLanguageResolver {
  BackgroundLanguageResolver._();

  static Future<String> resolve() async {
    final LocalePreferencesRepository prefs = LocalePreferencesRepository();
    final saved = await prefs.getSavedLocale();
    if (saved != null) {
      return saved.languageCode;
    }

    final String platformCode =
        PlatformDispatcher.instance.locale.languageCode;
    if (AppLocales.supported
        .any((locale) => locale.languageCode == platformCode)) {
      return platformCode;
    }
    return AppLocales.fallback.languageCode;
  }
}

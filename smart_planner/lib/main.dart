import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:smart_planner/app.dart';
import 'package:smart_planner/core/app_initializer.dart';
import 'package:smart_planner/core/localization/app_locales.dart';
import 'package:smart_planner/core/localization/locale_preferences_repository.dart';
import 'package:smart_planner/features/notifications/home_widget_background_callback.dart';
import 'package:smart_planner/features/notifications/notification_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HomeWidget.registerInteractivityCallback(homeWidgetBackgroundCallback);
  await AppInitializer.init();
  await EasyLocalization.ensureInitialized();

  final LocalePreferencesRepository localePreferences =
      LocalePreferencesRepository();
  final Locale? savedLocale = await localePreferences.getSavedLocale();

  runApp(
    EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: 'assets/translations',
      fallbackLocale: AppLocales.fallback,
      startLocale: savedLocale,
      useOnlyLangCode: true,
      child: DayLinxApp(
        localePreferences: localePreferences,
      ),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await NotificationHelper.ensureAndroidChannels();
    await AppInitializer.itemReminders.rescheduleAll();
  });
}

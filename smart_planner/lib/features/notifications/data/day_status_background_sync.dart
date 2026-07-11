import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/features/notifications/data/background_language_resolver.dart';
import 'package:smart_planner/features/notifications/data/day_status_home_widget_service.dart';
import 'package:smart_planner/features/notifications/data/day_status_today_loader.dart';
import 'package:smart_planner/features/notifications/data/notification_preferences_repository.dart';
import 'package:smart_planner/features/notifications/data/overdue_midnight_roll_service.dart';
import 'package:smart_planner/features/notifications/domain/day_status_locale_copy.dart';
import 'package:smart_planner/features/notifications/domain/day_status_notification_content.dart';
import 'package:smart_planner/features/notifications/domain/day_status_widget_payload.dart';
import 'package:smart_planner/features/notifications/notification_channels.dart';
import 'package:smart_planner/features/notifications/notification_helper.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';

/// Refreshes the day-status foreground notification and home widget from background.
abstract final class DayStatusBackgroundSync {
  DayStatusBackgroundSync._();

  static const int notificationId = 7391;

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  static Future<bool> run() async {
    if (!isSupported) {
      return true;
    }

    try {
      await IsarDatabase.init();
      await NotificationHelper.initializePlugin();

      await OverdueMidnightRollService().runIfNeeded();

      final String languageCode = await BackgroundLanguageResolver.resolve();
      final DayStatusTodayLoader loader = DayStatusTodayLoader(
        todoRepository: TodoRepository(),
      );
      final DayStatusTodaySnapshot snapshot = await loader.load();

      await _syncHomeWidget(
        DayStatusLocaleCopy.widgetPayload(
          snapshot: snapshot,
          languageCode: languageCode,
        ),
      );

      final NotificationPreferencesRepository prefs =
          NotificationPreferencesRepository();
      if (!await prefs.isDayStatusBarEnabled()) {
        return true;
      }

      await _syncForegroundNotification(
        DayStatusLocaleCopy.notificationContent(
          snapshot: snapshot,
          languageCode: languageCode,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _syncHomeWidget(DayStatusWidgetPayload payload) async {
    final Map<String, String> data = payload.toWidgetData();
    for (final MapEntry<String, String> entry in data.entries) {
      await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
    }
    await HomeWidget.updateWidget(
      qualifiedAndroidName: DayStatusHomeWidgetService.androidProviderName,
    );
  }

  static Future<void> _syncForegroundNotification(
    DayStatusNotificationContent content,
  ) async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        NotificationHelper.plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return;
    }

    await android.startForegroundService(
      notificationId,
      content.title,
      content.body,
      notificationDetails: AndroidNotificationDetails(
        NotificationChannels.dayStatusPinned,
        'Day status',
        channelDescription: 'Today plan summary',
        importance: Importance.max,
        priority: Priority.max,
        icon: 'ic_stat_smartplanner',
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch,
        category: AndroidNotificationCategory.service,
        visibility: NotificationVisibility.public,
        additionalFlags: Int32List.fromList(<int>[2]),
      ),
      foregroundServiceTypes: <AndroidServiceForegroundType>{
        AndroidServiceForegroundType.foregroundServiceTypeSpecialUse,
      },
    );
  }
}

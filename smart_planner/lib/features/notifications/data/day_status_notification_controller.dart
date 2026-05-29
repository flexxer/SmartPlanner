import 'dart:async';

import 'dart:io' show Platform;

import 'dart:typed_data';



import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:smart_planner/core/localization/l10n.dart';

import 'package:smart_planner/features/notifications/data/day_status_today_loader.dart';

import 'package:smart_planner/features/notifications/data/notification_preferences_repository.dart';

import 'package:smart_planner/features/notifications/domain/day_status_notification_builder.dart';

import 'package:smart_planner/features/notifications/domain/day_status_notification_content.dart';

import 'package:smart_planner/features/notifications/notification_channels.dart';

import 'package:smart_planner/features/notifications/notification_helper.dart';



/// Android foreground service that shows an ongoing day-status notification.

class DayStatusNotificationController {

  DayStatusNotificationController({

    required DayStatusTodayLoader todayLoader,

    required NotificationPreferencesRepository preferences,

  })  : _todayLoader = todayLoader,

        _preferences = preferences;



  static const int notificationId = 7391;



  final DayStatusTodayLoader _todayLoader;

  final NotificationPreferencesRepository _preferences;


  AndroidFlutterLocalNotificationsPlugin? get _android =>

      NotificationHelper.plugin.resolvePlatformSpecificImplementation<

          AndroidFlutterLocalNotificationsPlugin>();



  bool get _supportsForegroundService =>

      !kIsWeb && !Platform.isIOS && Platform.isAndroid;



  /// Starts the foreground service when the user has enabled the feature.

  Future<void> ensureStartedIfEnabled() async {

    if (!_supportsForegroundService) {

      return;

    }

    if (!await _preferences.isDayStatusBarEnabled()) {

      return;

    }

    await syncTodayStatus();

  }



  Future<void> setDayStatusBarEnabled(bool enabled) async {

    await _preferences.setDayStatusBarEnabled(enabled);

    if (!_supportsForegroundService) {

      return;

    }

    if (enabled) {

      await syncTodayStatus();

    } else {

      await stop();

    }

  }



  Future<void> setDayStatusBarPinned(bool pinned) async {
    // Pinned mode is enforced by product requirement and no longer toggled.
    await _preferences.setDayStatusBarPinned(true);
    if (_supportsForegroundService && await _preferences.isDayStatusBarEnabled()) {
      await syncTodayStatus();
    }

  }



  Future<void> syncTodayStatus() async {

    if (!_supportsForegroundService) {

      return;

    }

    if (!await _preferences.isDayStatusBarEnabled()) {

      return;

    }



    final AndroidFlutterLocalNotificationsPlugin? android = _android;

    if (android == null) {

      return;

    }



    try {

      final DayStatusNotificationContent content = await _loadTodayContent();

      await _preferences.setDayStatusBarPinned(true);
      final AndroidNotificationDetails details = _notificationDetails();



      await android.startForegroundService(

        notificationId,

        content.title,

        content.body,

        notificationDetails: details,

        foregroundServiceTypes: <AndroidServiceForegroundType>{

          AndroidServiceForegroundType.foregroundServiceTypeSpecialUse,

        },

      );

    } catch (_) {
    }

  }



  Future<void> stop() async {

    if (!_supportsForegroundService) {

      return;

    }

    await _android?.stopForegroundService();
  }



  Future<DayStatusNotificationContent> _loadTodayContent() async {

    final DayStatusTodaySnapshot snapshot = await _todayLoader.load();

    return DayStatusNotificationBuilder.build(

      activeTasks: snapshot.activeTasks,

      completedTasks: snapshot.completedTasks,

      backlogTasks: snapshot.backlogTasks,

      calendarEvents: snapshot.calendarEvents,

      now: snapshot.now,

    );

  }



  AndroidNotificationDetails _notificationDetails() {
    return AndroidNotificationDetails(

      NotificationChannels.dayStatusPinned,

      L10n.tr('notification_day_status_pinned_channel'),

      channelDescription: L10n.tr('notification_day_status_pinned_channel_desc'),

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

      actions: <AndroidNotificationAction>[

        AndroidNotificationAction(

          'open_app',

          L10n.tr('day_status_notification_action_open'),

          showsUserInterface: true,

          cancelNotification: false,

        ),

      ],

    );

  }

}



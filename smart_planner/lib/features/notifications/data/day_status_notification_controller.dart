import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/services/calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/recurrence_evaluator.dart';
import 'package:smart_planner/features/notifications/data/notification_preferences_repository.dart';
import 'package:smart_planner/features/notifications/domain/day_status_notification_builder.dart';
import 'package:smart_planner/features/notifications/domain/day_status_notification_content.dart';
import 'package:smart_planner/features/notifications/notification_channels.dart';
import 'package:smart_planner/features/notifications/notification_helper.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Android foreground service that shows an ongoing day-status notification.
class DayStatusNotificationController {
  DayStatusNotificationController({
    required TodoRepository todoRepository,
    required CalendarService calendarService,
    required NotificationPreferencesRepository preferences,
    CalendarPreferencesRepository? calendarPreferences,
    LocalCalendarEventRepository? localCalendarEvents,
  })  : _todoRepository = todoRepository,
        _calendarService = calendarService,
        _preferences = preferences,
        _calendarPreferences =
            calendarPreferences ?? CalendarPreferencesRepository(),
        _localCalendarEvents =
            localCalendarEvents ?? LocalCalendarEventRepository();

  static const int notificationId = 7391;

  final TodoRepository _todoRepository;
  final CalendarService _calendarService;
  final NotificationPreferencesRepository _preferences;
  final CalendarPreferencesRepository _calendarPreferences;
  final LocalCalendarEventRepository _localCalendarEvents;

  bool _serviceRunning = false;

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
      final AndroidNotificationDetails details = _notificationDetails();

      if (_serviceRunning) {
        await NotificationHelper.plugin.show(
          notificationId,
          content.title,
          content.body,
          NotificationDetails(android: details),
        );
        return;
      }

      await android.startForegroundService(
        notificationId,
        content.title,
        content.body,
        notificationDetails: details,
        foregroundServiceTypes: <AndroidServiceForegroundType>{
          AndroidServiceForegroundType.foregroundServiceTypeSpecialUse,
        },
      );
      _serviceRunning = true;
    } catch (_) {
      _serviceRunning = false;
    }
  }

  Future<void> stop() async {
    if (!_supportsForegroundService) {
      return;
    }
    await _android?.stopForegroundService();
    _serviceRunning = false;
  }

  Future<DayStatusNotificationContent> _loadTodayContent() async {
    final DateTime today = AppDateUtils.startOfDay(DateTime.now());

    final List<Object> parallel = await Future.wait<Object>(
      <Future<Object>>[
        _todoRepository.getUncompletedTasksForDate(today),
        _todoRepository.getCompletedTasksForDate(today),
        _loadTodayCalendarEvents(today),
      ],
    );

    return DayStatusNotificationBuilder.build(
      activeTasks: parallel[0] as List<Task>,
      completedTasks: parallel[1] as List<Task>,
      calendarEvents: parallel[2] as List<CalendarEvent>,
      now: DateTime.now(),
    );
  }

  Future<List<CalendarEvent>> _loadTodayCalendarEvents(DateTime today) async {
    final List<String>? saved =
        await _calendarPreferences.getSelectedCalendarIds();
    if (saved == null || saved.isEmpty) {
      return const <CalendarEvent>[];
    }

    try {
      final List<CalendarEvent> deviceEvents =
          await _calendarService.getEventsForDay(
        calendarIds: saved,
        day: today,
      );
      await _localCalendarEvents.upsertDeviceEvents(deviceEvents);
    } catch (_) {
      // Keep local Isar events when device fetch fails.
    }

    final List<CalendarEvent> allStored = await _localCalendarEvents.getAll();
    final List<CalendarEvent> visible = allStored
        .where(
          (CalendarEvent event) =>
              RecurrenceEvaluator.shouldShowEventOnDate(event, today),
        )
        .toList(growable: false)
      ..sort(
        (CalendarEvent a, CalendarEvent b) => a.start.compareTo(b.start),
      );
    return visible;
  }

  AndroidNotificationDetails _notificationDetails() {
    return AndroidNotificationDetails(
      NotificationChannels.dayStatus,
      L10n.tr('notification_day_status_channel'),
      channelDescription: L10n.tr('notification_day_status_channel_desc'),
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: false,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
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

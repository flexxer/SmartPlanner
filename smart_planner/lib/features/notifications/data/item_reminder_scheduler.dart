import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:isar/isar.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/notifications/domain/reminder_notification_ids.dart';
import 'package:smart_planner/features/notifications/domain/reminder_schedule_time.dart';
import 'package:smart_planner/features/notifications/notification_channels.dart';
import 'package:smart_planner/features/notifications/notification_helper.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:timezone/timezone.dart' as tz;

/// Schedules and cancels one-shot reminders for tasks and local calendar events.
class ItemReminderScheduler {
  ItemReminderScheduler();

  Future<void> syncTask(Task task) async {
    if (kIsWeb) {
      return;
    }
    await NotificationHelper.cancel(ReminderNotificationIds.forTask(task.id));
    final DateTime? fireAt = ReminderScheduleTime.fireAtForTask(task);
    if (fireAt == null) {
      return;
    }
    await _schedule(
      id: ReminderNotificationIds.forTask(task.id),
      title: _localizedReminderTitle(),
      body: _localizedTaskBody(task.title),
      fireAt: fireAt,
    );
  }

  Future<void> syncEvent(CalendarEvent event) async {
    if (kIsWeb) {
      return;
    }
    await NotificationHelper.cancel(ReminderNotificationIds.forEvent(event.id));
    final DateTime? fireAt = ReminderScheduleTime.fireAtForEvent(event);
    if (fireAt == null) {
      return;
    }
    await _schedule(
      id: ReminderNotificationIds.forEvent(event.id),
      title: _localizedReminderTitle(),
      body: _localizedEventBody(
        title: event.title,
        time: _formatClockTime(event.start),
      ),
      fireAt: fireAt,
    );
  }

  Future<void> cancelTask(int taskId) async {
    if (kIsWeb) {
      return;
    }
    await NotificationHelper.cancel(ReminderNotificationIds.forTask(taskId));
  }

  Future<void> cancelEvent(int eventId) async {
    if (kIsWeb) {
      return;
    }
    await NotificationHelper.cancel(ReminderNotificationIds.forEvent(eventId));
  }

  /// Re-registers all upcoming reminders after app start or timezone change.
  Future<void> rescheduleAll() async {
    if (kIsWeb) {
      return;
    }
    try {
      final isar = IsarDatabase.instance;
      final List<Task> tasks = await isar.tasks.where().findAll();
      for (final Task task in tasks) {
        await syncTask(task);
      }
      final List<CalendarEvent> events =
          await isar.calendarEvents.where().findAll();
      for (final CalendarEvent event in events) {
        await syncEvent(event);
      }
    } on Object {
      // Best-effort; must not block app startup.
    }
  }

  static String _formatClockTime(DateTime dateTime) {
    final String h = dateTime.hour.toString().padLeft(2, '0');
    final String m = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _localizedReminderTitle() {
    final String localized = L10n.tr('reminder_notification_title');
    if (localized != 'reminder_notification_title') {
      return localized;
    }
    return _languageCode() == 'ru' ? 'Напоминание' : 'Reminder';
  }

  static String _localizedTaskBody(String title) {
    final String localized = L10n.tr(
      'reminder_task_body',
      namedArgs: <String, String>{'title': title},
    );
    if (localized != 'reminder_task_body') {
      return localized;
    }
    return switch (_languageCode()) {
      'ru' => 'Задача: $title',
      'es' => 'Tarea: $title',
      _ => 'Task: $title',
    };
  }

  static String _localizedEventBody({
    required String title,
    required String time,
  }) {
    final String localized = L10n.tr(
      'reminder_event_body',
      namedArgs: <String, String>{'title': title, 'time': time},
    );
    if (localized != 'reminder_event_body') {
      return localized;
    }
    return switch (_languageCode()) {
      'ru' => 'Событие в $time: $title',
      'es' => 'Evento a las $time: $title',
      _ => 'Event at $time: $title',
    };
  }

  static String _languageCode() => L10n.activeLocale().languageCode;

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
  }) async {
    final DateTime now = DateTime.now();
    if (!fireAt.isAfter(now)) {
      return;
    }
    await NotificationHelper.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      channelId: NotificationChannels.meetings,
    );
  }
}

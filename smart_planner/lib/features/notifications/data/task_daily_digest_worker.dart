import 'package:flutter/foundation.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/notifications/background_service.dart';
import 'package:smart_planner/features/notifications/data/notification_preferences_repository.dart';
import 'package:smart_planner/features/notifications/notification_channels.dart';
import 'package:smart_planner/features/notifications/notification_helper.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';

/// Morning (08:00) and evening (19:00) task overview notifications.
abstract final class TaskDailyDigestWorker {
  TaskDailyDigestWorker._();

  static const int morningNotificationId = 77010;
  static const int eveningNotificationId = 77011;

  static Future<bool> runMorning() => _run(
        slot: _DigestSlot.morning,
        notificationId: morningNotificationId,
      );

  static Future<bool> runEvening() => _run(
        slot: _DigestSlot.evening,
        notificationId: eveningNotificationId,
      );

  static Future<bool> _run({
    required _DigestSlot slot,
    required int notificationId,
  }) async {
    try {
      await IsarDatabase.init();
      await NotificationHelper.initializePlugin();

      final NotificationPreferencesRepository prefs =
          NotificationPreferencesRepository();
      final bool enabled = slot == _DigestSlot.morning
          ? await prefs.isMorningDigestEnabled()
          : await prefs.isEveningDigestEnabled();
      if (!enabled) {
        await NotificationHelper.cancel(notificationId);
        return true;
      }

      final DateTime today = AppDateUtils.startOfDay(DateTime.now());
      final TodoRepository repository = TodoRepository();
      final List<Task> dueToday =
          await repository.getUncompletedTasksForDate(today);
      final List<Task> rootDue =
          dueToday.where(TaskHierarchy.isRoot).toList(growable: false);

      if (rootDue.isEmpty) {
        await NotificationHelper.cancel(notificationId);
        return true;
      }

      final ({String title, String body}) copy = _copyFor(slot, rootDue.length);
      await NotificationHelper.showNotification(
        id: notificationId,
        title: copy.title,
        body: copy.body,
        channelId: NotificationChannels.taskDigest,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static ({String title, String body}) _copyFor(_DigestSlot slot, int count) {
    final String languageCode = PlatformDispatcher.instance.locale.languageCode;
    return switch (languageCode) {
      'ru' => slot == _DigestSlot.morning
          ? (
              title: 'Утренний обзор',
              body: count == 1
                  ? 'На сегодня 1 задача.'
                  : 'На сегодня $count задач.',
            )
          : (
              title: 'Вечерний обзор',
              body: count == 1
                  ? 'Осталась 1 задача на сегодня.'
                  : 'Осталось $count задач на сегодня.',
            ),
      'es' => slot == _DigestSlot.morning
          ? (
              title: 'Resumen matutino',
              body: count == 1
                  ? '1 tarea para hoy.'
                  : '$count tareas para hoy.',
            )
          : (
              title: 'Resumen vespertino',
              body: count == 1
                  ? 'Queda 1 tarea para hoy.'
                  : 'Quedan $count tareas para hoy.',
            ),
      _ => slot == _DigestSlot.morning
          ? (
              title: 'Morning overview',
              body: count == 1 ? '1 task for today.' : '$count tasks for today.',
            )
          : (
              title: 'Evening overview',
              body: count == 1
                  ? '1 task left for today.'
                  : '$count tasks left for today.',
            ),
    };
  }
}

enum _DigestSlot { morning, evening }

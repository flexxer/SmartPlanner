import 'package:flutter/foundation.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/notifications/background_service.dart';
import 'package:smart_planner/features/notifications/data/overdue_midnight_roll_service.dart';
import 'package:smart_planner/features/notifications/notification_channels.dart';
import 'package:smart_planner/features/notifications/notification_helper.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Workmanager handler: overdue digest notification.
abstract final class OverdueBackgroundWorker {
  OverdueBackgroundWorker._();

  static Future<bool> run() async {
    try {
      await IsarDatabase.init();
      await NotificationHelper.initializePlugin();

      await OverdueMidnightRollService().runIfNeeded();

      final TodoRepository todoRepository = TodoRepository();
      final List<Task> overdueTasks =
          await todoRepository.getOverdueUncompletedTasks(
        referenceDay: AppDateUtils.startOfDay(DateTime.now()),
      );

      if (overdueTasks.isEmpty) {
        await NotificationHelper.cancel(
          BackgroundTaskService.overdueDigestNotificationId,
        );
        return true;
      }

      await NotificationHelper.showNotification(
        id: BackgroundTaskService.overdueDigestNotificationId,
        title: _overdueTitle(overdueTasks.length),
        body: _overdueBody(overdueTasks.length),
        channelId: NotificationChannels.overdueTasks,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _overdueTitle(int count) {
    final String languageCode = PlatformDispatcher.instance.locale.languageCode;
    return switch (languageCode) {
      'ru' => 'Просроченные задачи: $count',
      'es' => 'Tareas atrasadas: $count',
      _ => 'Overdue tasks: $count',
    };
  }

  static String _overdueBody(int count) {
    final String languageCode = PlatformDispatcher.instance.locale.languageCode;
    return switch (languageCode) {
      'ru' => count == 1
          ? 'Одна задача требует внимания.'
          : '$count задач требуют внимания.',
      'es' => count == 1
          ? 'Una tarea requiere atención.'
          : '$count tareas requieren atención.',
      _ => count == 1
          ? 'One task needs attention.'
          : '$count tasks need attention.',
    };
  }
}

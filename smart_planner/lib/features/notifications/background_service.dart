import 'package:flutter/foundation.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:workmanager/workmanager.dart';

/// Фоновая проверка просроченных задач (Workmanager, PRD §3.3).
class BackgroundTaskService {
  BackgroundTaskService._();

  static const String taskCheckOverdue = 'check_overdue_tasks';
  static const String uniqueName = 'smart_planner_background';

  static Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      uniqueName,
      taskCheckOverdue,
      frequency: const Duration(hours: 12),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
    );
  }

  static Future<void> cancel() async {
    await Workmanager().cancelByUniqueName(uniqueName);
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((String taskName, Map<String, dynamic>? inputData) async {
    if (taskName != BackgroundTaskService.taskCheckOverdue) {
      return Future<bool>.value(false);
    }
    try {
      await IsarDatabase.init();
      // TODO: перенос просроченных задач + уведомление через NotificationHelper
      return Future<bool>.value(true);
    } catch (_) {
      return Future<bool>.value(false);
    }
  });
}

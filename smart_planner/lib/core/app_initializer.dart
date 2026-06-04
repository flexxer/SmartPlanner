import 'package:flutter/widgets.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/core/timezone/timezone_monitor.dart';
import 'package:smart_planner/features/notifications/background_service.dart';
import 'package:smart_planner/features/notifications/data/item_reminder_scheduler.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/data/task_bootstrap.dart';
import 'package:smart_planner/features/notifications/notification_helper.dart';
import 'package:timezone/data/latest_all.dart' as tz;

/// Единая точка инициализации инфраструктуры перед [runApp].
class AppInitializer {
  AppInitializer._();

  /// Shared scheduler instance (also provided via [RepositoryProvider] in [DayLinxApp]).
  static ItemReminderScheduler? _itemReminders;

  static ItemReminderScheduler get itemReminders =>
      _itemReminders ??= ItemReminderScheduler();

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    tz.initializeTimeZones();
    final bool timezoneChanged = await TimezoneMonitor.applyIfChanged();
    await IsarDatabase.init();
    await TaskBootstrap.seedIfNeeded(TodoRepository());
    await NotificationHelper.initializePlugin();
    _itemReminders = ItemReminderScheduler();
    if (timezoneChanged) {
      await itemReminders.rescheduleAll();
    }
    await BackgroundTaskService.initialize();
  }
}

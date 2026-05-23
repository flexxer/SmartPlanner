import 'package:flutter/widgets.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/features/notifications/background_service.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/data/task_bootstrap.dart';
import 'package:smart_planner/features/notifications/notification_helper.dart';
import 'package:timezone/data/latest_all.dart' as tz;

/// Единая точка инициализации инфраструктуры перед [runApp].
class AppInitializer {
  AppInitializer._();

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    tz.initializeTimeZones();
    await IsarDatabase.init();
    await TaskBootstrap.seedIfNeeded(TodoRepository());
    await NotificationHelper.initialize();
    await BackgroundTaskService.initialize();
  }
}

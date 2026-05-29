import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:smart_planner/core/database/isar_database.dart';
import 'package:smart_planner/features/notifications/background_service.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/data/task_bootstrap.dart';
import 'package:smart_planner/features/notifications/notification_helper.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Единая точка инициализации инфраструктуры перед [runApp].
class AppInitializer {
  AppInitializer._();

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    tz.initializeTimeZones();
    await _configureLocalTimezone();
    await IsarDatabase.init();
    await TaskBootstrap.seedIfNeeded(TodoRepository());
    await NotificationHelper.initializePlugin();
    await BackgroundTaskService.initialize();
  }

  static Future<void> _configureLocalTimezone() async {
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }
  }
}

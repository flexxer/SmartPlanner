import 'package:flutter/material.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/notifications/data/notification_preferences_repository.dart';

/// Builds default [Task.reminderAt] for new tasks from settings + optional due day.
abstract final class TaskReminderDefaults {
  TaskReminderDefaults._();

  static Future<DateTime> defaultReminderAt({
    NotificationPreferencesRepository? preferences,
    DateTime? dueDate,
    DateTime? reference,
  }) async {
    final NotificationPreferencesRepository prefs =
        preferences ?? NotificationPreferencesRepository();
    final TimeOfDay time = await prefs.getDefaultTaskReminderTime();
    final DateTime baseDay = AppDateUtils.startOfDay(
      dueDate ?? reference ?? DateTime.now(),
    );
    return DateTime(
      baseDay.year,
      baseDay.month,
      baseDay.day,
      time.hour,
      time.minute,
    );
  }
}

import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Computes when a local notification should fire.
abstract final class ReminderScheduleTime {
  ReminderScheduleTime._();

  static DateTime? fireAtForTask(Task task) {
    if (task.isCompleted) {
      return null;
    }
    return task.reminderAt;
  }

  static DateTime? fireAtForEvent(CalendarEvent event) {
    final int? minutes = event.reminderMinutesBefore;
    if (minutes == null) {
      return null;
    }
    return event.start.subtract(Duration(minutes: minutes));
  }
}

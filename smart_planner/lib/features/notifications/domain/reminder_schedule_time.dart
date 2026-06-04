import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/recurrence_evaluator.dart';
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
    final DateTime now = DateTime.now();
    final DateTime occurrenceStart = _nextOccurrenceStart(
      event: event,
      now: now,
    );
    return occurrenceStart.subtract(Duration(minutes: minutes));
  }

  static DateTime _nextOccurrenceStart({
    required CalendarEvent event,
    required DateTime now,
  }) {
    if (event.recurrenceRuleJson == null || event.recurrenceRuleJson!.isEmpty) {
      return event.start;
    }

    final DateTime startDay = AppDateUtils.startOfDay(now);
    for (int offset = 0; offset <= 366; offset++) {
      final DateTime day = startDay.add(Duration(days: offset));
      if (!RecurrenceEvaluator.shouldShowEventOnDate(event, day)) {
        continue;
      }
      final DateTime candidate = DateTime(
        day.year,
        day.month,
        day.day,
        event.start.hour,
        event.start.minute,
        event.start.second,
        event.start.millisecond,
        event.start.microsecond,
      );
      if (!candidate.isBefore(now)) {
        return candidate;
      }
    }
    return event.start;
  }
}

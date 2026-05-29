import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/recurrence_evaluator.dart';
import 'package:smart_planner/features/dashboard/domain/day_activity_marker.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/task_date_visibility.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';

/// Builds per-day markers from tasks and calendar events.
class DashboardDayMarkersBuilder {
  DashboardDayMarkersBuilder._();

  static Map<int, DayActivityMarker> build({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required List<Task> tasks,
    required List<CalendarEvent> events,
  }) {
    final Map<int, DayActivityMarker> markers = <int, DayActivityMarker>{};
    final DateTime start = AppDateUtils.startOfDay(rangeStart);
    final DateTime end = AppDateUtils.startOfDay(rangeEnd);
    final Set<int> taskDayKeys =
        TaskDateVisibility.taskDayKeysWithVisibleTasksInRange(
      tasks: tasks,
      rangeStart: start,
      rangeEnd: end,
    );

    for (
      DateTime day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      final int key = AppDateUtils.dayKeyMs(day);
      final int eventCount = _eventCountOnDay(events, day);
      final int timedTaskCount = _timedTaskCountOnDay(tasks, day);
      final CalendarEvent? firstEvent =
          eventCount > 0 ? _firstEventOnDay(events, day) : null;

      markers[key] = DayActivityMarker(
        hasLocalTasks: taskDayKeys.contains(key),
        hasCalendarEvents: eventCount > 0,
        calendarColorValue: firstEvent?.colorValue,
        eventCount: eventCount,
        timedTaskCount: timedTaskCount,
      );
    }

    return markers;
  }

  static int _eventCountOnDay(List<CalendarEvent> events, DateTime day) {
    int count = 0;
    for (final CalendarEvent event in events) {
      if (_eventOccursOnCalendarDay(event, day)) {
        count++;
      }
    }
    return count;
  }

  /// Same visibility as dashboard / month grid: recurrence expansion or interval overlap.
  static bool _eventOccursOnCalendarDay(CalendarEvent event, DateTime day) {
    final String? json = event.recurrenceRuleJson;
    if (json != null && json.trim().isNotEmpty) {
      return RecurrenceEvaluator.shouldShowEventOnDate(event, day);
    }
    final DateTime dayStart = AppDateUtils.startOfDay(day);
    final DateTime dayEnd = dayStart.add(const Duration(days: 1));
    return event.start.isBefore(dayEnd) && event.end.isAfter(dayStart);
  }

  /// Tasks anchored to this calendar day (due or reminder), not overdue spillover.
  static int _timedTaskCountOnDay(List<Task> tasks, DateTime day) {
    int count = 0;
    for (final Task task in tasks) {
      if (!TaskHierarchy.isRoot(task) || task.isCompleted) {
        continue;
      }

      final DateTime? due = task.dueDate;
      if (due != null && AppDateUtils.isSameCalendarDay(due, day)) {
        count++;
        continue;
      }

      final DateTime? reminder = task.reminderAt;
      if (reminder != null && AppDateUtils.isSameCalendarDay(reminder, day)) {
        count++;
      }
    }
    return count;
  }

  static CalendarEvent? _firstEventOnDay(
    List<CalendarEvent> events,
    DateTime day,
  ) {
    for (final CalendarEvent event in events) {
      if (_eventOccursOnCalendarDay(event, day)) {
        return event;
      }
    }
    return null;
  }
}

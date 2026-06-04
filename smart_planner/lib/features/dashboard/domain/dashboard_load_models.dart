import 'package:isar/isar.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/dashboard/domain/day_activity_marker.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';

/// Task lists and related maps for one dashboard refresh.
class DashboardTaskSnapshot {
  const DashboardTaskSnapshot({
    required this.tasks,
    required this.completedTasks,
    required this.overdueTasks,
    required this.undatedTasks,
    required this.childTasksByParentId,
    required this.attachmentsByTaskId,
    required this.dayMarkers,
  });

  final List<Task> tasks;
  final List<Task> completedTasks;
  final List<Task> overdueTasks;
  final List<Task> undatedTasks;
  final Map<Id, ChildTasksBundle> childTasksByParentId;
  final Map<Id, List<TaskAttachment>> attachmentsByTaskId;
  final Map<int, DayActivityMarker> dayMarkers;
}

/// Local Isar calendar events for one day (no device fetch).
class DashboardLocalCalendarSlice {
  const DashboardLocalCalendarSlice({
    required this.visibleOnSelectedDay,
    required this.localCalendarEventById,
  });

  final List<CalendarEvent> visibleOnSelectedDay;
  final Map<Id, CalendarEvent> localCalendarEventById;
}

/// Device + local calendar slice for the selected day.
class DashboardCalendarSnapshot {
  const DashboardCalendarSnapshot({
    required this.deviceEvents,
    required this.visibleCalendarEvents,
    required this.localCalendarEventById,
    this.calendarMessage,
  });

  final List<CalendarEvent> deviceEvents;
  final List<CalendarEvent> visibleCalendarEvents;
  final Map<Id, CalendarEvent> localCalendarEventById;
  final String? calendarMessage;
}

/// Full payload assembled on initial load or date change.
class DashboardLoadPayload {
  const DashboardLoadPayload({
    required this.tasks,
    required this.calendar,
    required this.linkedCalendarsById,
    required this.selectedDate,
    required this.selectedCalendarIds,
  });

  final DashboardTaskSnapshot tasks;
  final DashboardCalendarSnapshot calendar;
  final Map<String, DeviceCalendarInfo> linkedCalendarsById;
  final DateTime selectedDate;
  final List<String> selectedCalendarIds;
}

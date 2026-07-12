import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/categories/domain/entities/category.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/dashboard/domain/day_activity_marker.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';

sealed class DashboardState {
  const DashboardState();
}

final class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

final class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.tasks,
    this.completedTasks = const <Task>[],
    required this.calendarEvents,
    required this.selectedDate,
    this.overdueTasks = const <Task>[],
    this.undatedTasks = const <Task>[],
    this.selectedCalendarIds = const <String>[],
    this.selectedCategoryIds = const <Id>[],
    this.categoriesByTaskId = const <Id, List<Category>>{},
    this.calendarMessage,
    this.localCalendarEventById = const <Id, CalendarEvent>{},
    this.childTasksByParentId = const <Id, ChildTasksBundle>{},
    this.attachmentsByTaskId = const <Id, List<TaskAttachment>>{},
    this.dayMarkers = const <int, DayActivityMarker>{},
    this.expandedTaskId,
    this.linkedCalendarsById = const <String, DeviceCalendarInfo>{},
  });

  /// Active (uncompleted) root tasks for [selectedDate].
  final List<Task> tasks;

  /// Completed root tasks for [selectedDate], shown below [tasks] on the dashboard.
  final List<Task> completedTasks;

  /// Uncompleted tasks due before today; non-empty only when [selectedDate] is today.
  final List<Task> overdueTasks;

  /// Root uncompleted tasks with no due date (always loaded for the dashboard).
  final List<Task> undatedTasks;
  /// Merged device + local-only events for [selectedDate] (dashboard strip).
  final List<CalendarEvent> calendarEvents;

  final DateTime selectedDate;
  final List<String> selectedCalendarIds;
  final List<Id> selectedCategoryIds;
  final Map<Id, List<Category>> categoriesByTaskId;

  /// Linked child tasks keyed by parent [Task.id].
  final Map<Id, ChildTasksBundle> childTasksByParentId;

  final Map<Id, List<TaskAttachment>> attachmentsByTaskId;

  /// Per-day strip indicators keyed by [AppDateUtils.dayKeyMs].
  final Map<int, DayActivityMarker> dayMarkers;

  List<TaskAttachment> attachmentsFor(Id taskId) =>
      attachmentsByTaskId[taskId] ?? const <TaskAttachment>[];

  /// All persisted local events keyed by Isar id (linking UI).
  final Map<Id, CalendarEvent> localCalendarEventById;

  /// Предупреждение, если календарь недоступен (нет разрешения и т.п.).
  final String? calendarMessage;

  /// When set, the matching [TaskExpandableTile] opens in expanded state.
  final Id? expandedTaskId;

  /// Device calendars enabled in settings, keyed by calendar id (task context badges).
  final Map<String, DeviceCalendarInfo> linkedCalendarsById;

  DeviceCalendarInfo? contextCalendarFor(Task task) =>
      linkedCalendarsById[task.calendarId];

  CalendarEvent? localEventFor(Id? eventId) =>
      eventId == null ? null : localCalendarEventById[eventId];

  ChildTasksBundle childBundleFor(Id parentId) =>
      childTasksByParentId[parentId] ?? const ChildTasksBundle(
        activeChildren: <Task>[],
        completedCount: 0,
        totalCount: 0,
      );

  DashboardLoaded copyWith({
    List<Task>? tasks,
    List<Task>? completedTasks,
    List<Task>? overdueTasks,
    List<Task>? undatedTasks,
    List<CalendarEvent>? calendarEvents,
    Map<Id, CalendarEvent>? localCalendarEventById,
    DateTime? selectedDate,
    List<String>? selectedCalendarIds,
    List<Id>? selectedCategoryIds,
    Map<Id, List<Category>>? categoriesByTaskId,
    String? calendarMessage,
    Map<Id, ChildTasksBundle>? childTasksByParentId,
    Map<Id, List<TaskAttachment>>? attachmentsByTaskId,
    Map<int, DayActivityMarker>? dayMarkers,
    Id? expandedTaskId,
    Map<String, DeviceCalendarInfo>? linkedCalendarsById,
    bool clearExpandedTaskId = false,
  }) {
    return DashboardLoaded(
      tasks: tasks ?? this.tasks,
      completedTasks: completedTasks ?? this.completedTasks,
      overdueTasks: overdueTasks ?? this.overdueTasks,
      undatedTasks: undatedTasks ?? this.undatedTasks,
      calendarEvents: calendarEvents ?? this.calendarEvents,
      localCalendarEventById:
          localCalendarEventById ?? this.localCalendarEventById,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedCalendarIds: selectedCalendarIds ?? this.selectedCalendarIds,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      categoriesByTaskId: categoriesByTaskId ?? this.categoriesByTaskId,
      calendarMessage: calendarMessage ?? this.calendarMessage,
      childTasksByParentId:
          childTasksByParentId ?? this.childTasksByParentId,
      attachmentsByTaskId:
          attachmentsByTaskId ?? this.attachmentsByTaskId,
      dayMarkers: dayMarkers ?? this.dayMarkers,
      expandedTaskId: clearExpandedTaskId
          ? null
          : (expandedTaskId ?? this.expandedTaskId),
      linkedCalendarsById:
          linkedCalendarsById ?? this.linkedCalendarsById,
    );
  }
}

final class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;
}

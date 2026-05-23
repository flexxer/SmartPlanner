import 'package:isar/isar.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
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
    required this.events,
    required this.selectedDate,
    this.overdueTasks = const <Task>[],
    this.selectedCalendarIds = const <String>[],
    this.calendarMessage,
    this.childTasksByParentId = const <Id, ChildTasksBundle>{},
    this.attachmentsByTaskId = const <Id, List<TaskAttachment>>{},
    this.dayMarkers = const <int, DayActivityMarker>{},
  });

  final List<Task> tasks;

  /// Uncompleted tasks due before today; non-empty only when [selectedDate] is today.
  final List<Task> overdueTasks;
  final List<CalendarEvent> events;
  final DateTime selectedDate;
  final List<String> selectedCalendarIds;

  /// Linked child tasks keyed by parent [Task.id].
  final Map<Id, ChildTasksBundle> childTasksByParentId;

  final Map<Id, List<TaskAttachment>> attachmentsByTaskId;

  /// Per-day strip indicators keyed by [AppDateUtils.dayKeyMs].
  final Map<int, DayActivityMarker> dayMarkers;

  List<TaskAttachment> attachmentsFor(Id taskId) =>
      attachmentsByTaskId[taskId] ?? const <TaskAttachment>[];

  /// Предупреждение, если календарь недоступен (нет разрешения и т.п.).
  final String? calendarMessage;

  ChildTasksBundle childBundleFor(Id parentId) =>
      childTasksByParentId[parentId] ?? const ChildTasksBundle(
        activeChildren: <Task>[],
        completedCount: 0,
        totalCount: 0,
      );

  DashboardLoaded copyWith({
    List<Task>? tasks,
    List<Task>? overdueTasks,
    List<CalendarEvent>? events,
    DateTime? selectedDate,
    List<String>? selectedCalendarIds,
    String? calendarMessage,
    Map<Id, ChildTasksBundle>? childTasksByParentId,
    Map<Id, List<TaskAttachment>>? attachmentsByTaskId,
    Map<int, DayActivityMarker>? dayMarkers,
  }) {
    return DashboardLoaded(
      tasks: tasks ?? this.tasks,
      overdueTasks: overdueTasks ?? this.overdueTasks,
      events: events ?? this.events,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedCalendarIds: selectedCalendarIds ?? this.selectedCalendarIds,
      calendarMessage: calendarMessage ?? this.calendarMessage,
      childTasksByParentId:
          childTasksByParentId ?? this.childTasksByParentId,
      attachmentsByTaskId:
          attachmentsByTaskId ?? this.attachmentsByTaskId,
      dayMarkers: dayMarkers ?? this.dayMarkers,
    );
  }
}

final class DashboardError extends DashboardState {
  const DashboardError(this.message);

  final String message;
}

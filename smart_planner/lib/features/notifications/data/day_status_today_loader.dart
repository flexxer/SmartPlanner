import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/dashboard/domain/visible_calendar_events_merger.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Tasks and calendar events for today (notification + home widget).
class DayStatusTodaySnapshot {
  const DayStatusTodaySnapshot({
    required this.activeTasks,
    required this.completedTasks,
    required this.backlogTasks,
    required this.overdueTasks,
    required this.calendarEvents,
    required this.now,
  });

  final List<Task> activeTasks;
  final List<Task> completedTasks;
  final List<Task> backlogTasks;
  final List<Task> overdueTasks;
  final List<CalendarEvent> calendarEvents;
  final DateTime now;
}

/// Loads today's dashboard data for status notification and home widget.
class DayStatusTodayLoader {
  DayStatusTodayLoader({
    required this.todoRepository,
    LocalCalendarEventRepository? localCalendarEvents,
  }) : _localCalendarEvents =
            localCalendarEvents ?? LocalCalendarEventRepository();

  final TodoRepository todoRepository;
  final LocalCalendarEventRepository _localCalendarEvents;

  Future<DayStatusTodaySnapshot> load({DateTime? now}) async {
    final DateTime clock = now ?? DateTime.now();
    final DateTime today = AppDateUtils.startOfDay(clock);

    final List<Task> activeTasks = (await todoRepository
            .getUncompletedTasksForDate(today))
        .getOrElse((_) => <Task>[])
      ..sort(TodoRepository.compareTasksByPriority);
    final List<Task> completedTasks =
        (await todoRepository.getCompletedTasksForDate(today))
            .getOrElse((_) => <Task>[]);
    final List<Task> backlogTasks =
        (await todoRepository.getUndatedTasks()).getOrElse((_) => <Task>[]);
    final List<Task> overdueTasks = (await todoRepository
            .getOverdueUncompletedTasks(referenceDay: today))
        .getOrElse((_) => <Task>[]);
    final List<CalendarEvent> calendarEvents =
        await _loadTodayCalendarEvents(today);

    return DayStatusTodaySnapshot(
      activeTasks: activeTasks,
      completedTasks: completedTasks,
      backlogTasks: backlogTasks,
      overdueTasks: overdueTasks,
      calendarEvents: calendarEvents,
      now: clock,
    );
  }

  Future<List<CalendarEvent>> _loadTodayCalendarEvents(DateTime today) async {
    final List<CalendarEvent> allStored =
        (await _localCalendarEvents.getAll()).getOrElse((_) => <CalendarEvent>[]);
    return VisibleCalendarEventsMerger.fromStored(
      selectedDay: today,
      allStored: allStored,
    );
  }
}

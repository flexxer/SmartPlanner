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
    required TodoRepository todoRepository,
    LocalCalendarEventRepository? localCalendarEvents,
  })  : _todoRepository = todoRepository,
        _localCalendarEvents =
            localCalendarEvents ?? LocalCalendarEventRepository();

  final TodoRepository _todoRepository;
  final LocalCalendarEventRepository _localCalendarEvents;

  Future<DayStatusTodaySnapshot> load({DateTime? now}) async {
    final DateTime clock = now ?? DateTime.now();
    final DateTime today = AppDateUtils.startOfDay(clock);

    final List<Object> parallel = await Future.wait<Object>(
      <Future<Object>>[
        _todoRepository.getUncompletedTasksForDate(today),
        _todoRepository.getCompletedTasksForDate(today),
        _todoRepository.getUndatedTasks(),
        _todoRepository.getOverdueUncompletedTasks(referenceDay: today),
        _loadTodayCalendarEvents(today),
      ],
    );

    final List<Task> activeTasks = parallel[0] as List<Task>
      ..sort(TodoRepository.compareTasksByPriority);

    return DayStatusTodaySnapshot(
      activeTasks: activeTasks,
      completedTasks: parallel[1] as List<Task>,
      backlogTasks: parallel[2] as List<Task>,
      overdueTasks: parallel[3] as List<Task>,
      calendarEvents: parallel[4] as List<CalendarEvent>,
      now: clock,
    );
  }

  Future<List<CalendarEvent>> _loadTodayCalendarEvents(DateTime today) async {
    final List<CalendarEvent> allStored = await _localCalendarEvents.getAll();
    return VisibleCalendarEventsMerger.fromStored(
      selectedDay: today,
      allStored: allStored,
    );
  }
}

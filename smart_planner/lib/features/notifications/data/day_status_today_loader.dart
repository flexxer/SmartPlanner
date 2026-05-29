import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/services/calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/recurrence_evaluator.dart';
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
    required CalendarService calendarService,
    CalendarPreferencesRepository? calendarPreferences,
    LocalCalendarEventRepository? localCalendarEvents,
  })  : _todoRepository = todoRepository,
        _calendarService = calendarService,
        _calendarPreferences =
            calendarPreferences ?? CalendarPreferencesRepository(),
        _localCalendarEvents =
            localCalendarEvents ?? LocalCalendarEventRepository();

  final TodoRepository _todoRepository;
  final CalendarService _calendarService;
  final CalendarPreferencesRepository _calendarPreferences;
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

    return DayStatusTodaySnapshot(
      activeTasks: parallel[0] as List<Task>,
      completedTasks: parallel[1] as List<Task>,
      backlogTasks: parallel[2] as List<Task>,
      overdueTasks: parallel[3] as List<Task>,
      calendarEvents: parallel[4] as List<CalendarEvent>,
      now: clock,
    );
  }

  Future<List<CalendarEvent>> _loadTodayCalendarEvents(DateTime today) async {
    final List<String>? saved =
        await _calendarPreferences.getSelectedCalendarIds();
    if (saved == null || saved.isEmpty) {
      return const <CalendarEvent>[];
    }

    try {
      final List<CalendarEvent> deviceEvents =
          await _calendarService.getEventsForDay(
        calendarIds: saved,
        day: today,
      );
      await _localCalendarEvents.upsertDeviceEvents(deviceEvents);
    } catch (_) {
      // Keep local Isar events when device fetch fails.
    }

    final List<CalendarEvent> allStored = await _localCalendarEvents.getAll();
    final List<CalendarEvent> visible = allStored
        .where(
          (CalendarEvent event) =>
              RecurrenceEvaluator.shouldShowEventOnDate(event, today),
        )
        .toList(growable: false)
      ..sort(
        (CalendarEvent a, CalendarEvent b) => a.start.compareTo(b.start),
      );
    return visible;
  }
}

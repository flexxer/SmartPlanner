import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/services/calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/exceptions/calendar_exceptions.dart';
import 'package:smart_planner/features/dashboard/domain/dashboard_day_markers_builder.dart';
import 'package:smart_planner/features/dashboard/domain/day_activity_marker.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/task_date_visibility.dart';

/// Cached week-range markers for the dashboard date strip (one DB + one calendar fetch).
class DashboardDayMarkersRepository {
  DashboardDayMarkersRepository({
    required TodoRepository todoRepository,
    required CalendarService calendarService,
  })  : _todoRepository = todoRepository,
        _calendarService = calendarService;

  final TodoRepository _todoRepository;
  final CalendarService _calendarService;

  String? _cacheKey;
  Map<int, DayActivityMarker>? _cachedMarkers;

  void invalidate() {
    _cacheKey = null;
    _cachedMarkers = null;
  }

  /// Inclusive calendar-day range [rangeStart] … [rangeEnd].
  Future<Map<int, DayActivityMarker>> loadForRange({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required List<String> calendarIds,
  }) async {
    final DateTime start = AppDateUtils.startOfDay(rangeStart);
    final DateTime end = AppDateUtils.startOfDay(rangeEnd);
    final String key =
        '${calendarIds.join('|')}|${start.millisecondsSinceEpoch}|'
        '${end.millisecondsSinceEpoch}';

    if (_cacheKey == key && _cachedMarkers != null) {
      return _cachedMarkers!;
    }

    final Set<int> taskDayKeys = await _loadTaskDayKeys(start, end);
    final List<CalendarEvent> events = await _loadCalendarEvents(
      calendarIds: calendarIds,
      rangeStart: start,
      rangeEnd: end,
    );

    final Map<int, DayActivityMarker> markers = DashboardDayMarkersBuilder.build(
      rangeStart: start,
      rangeEnd: end,
      taskDayKeys: taskDayKeys,
      events: events,
    );

    _cacheKey = key;
    _cachedMarkers = markers;
    return markers;
  }

  Future<Set<int>> _loadTaskDayKeys(DateTime start, DateTime end) async {
    final List<Task> tasks = await _todoRepository.getUncompletedTasks();
    return TaskDateVisibility.taskDayKeysWithVisibleTasksInRange(
      tasks: tasks,
      rangeStart: start,
      rangeEnd: end,
    );
  }

  Future<List<CalendarEvent>> _loadCalendarEvents({
    required List<String> calendarIds,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    if (calendarIds.isEmpty) {
      return <CalendarEvent>[];
    }

    try {
      return await _calendarService.getEvents(
        calendarIds: calendarIds,
        from: rangeStart.subtract(const Duration(days: 1)),
        to: rangeEnd.add(const Duration(days: 2)),
      );
    } on CalendarPermissionDeniedException {
      return <CalendarEvent>[];
    } on CalendarServiceException {
      return <CalendarEvent>[];
    }
  }
}

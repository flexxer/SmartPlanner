import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/dashboard/domain/dashboard_day_markers_builder.dart';
import 'package:smart_planner/features/dashboard/domain/visible_calendar_events_merger.dart';
import 'package:smart_planner/features/dashboard/domain/day_activity_marker.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Cached week-range markers for the dashboard date strip (Isar events only).
class DashboardDayMarkersRepository {
  DashboardDayMarkersRepository({
    required TodoRepository todoRepository,
    required LocalCalendarEventRepository localCalendarEventRepository,
  })  : _todoRepository = todoRepository,
        _localCalendarEventRepository = localCalendarEventRepository;

  final TodoRepository _todoRepository;
  final LocalCalendarEventRepository _localCalendarEventRepository;

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
        '${start.millisecondsSinceEpoch}|${end.millisecondsSinceEpoch}';

    if (_cacheKey == key && _cachedMarkers != null) {
      return _cachedMarkers!;
    }

    final List<Task> tasks = await _todoRepository.getUncompletedTasks();
    final List<CalendarEvent> events = await _loadStoredEventsForMarkers(
      rangeStart: start,
      rangeEnd: end,
    );

    final Map<int, DayActivityMarker> markers = DashboardDayMarkersBuilder.build(
      rangeStart: start,
      rangeEnd: end,
      tasks: tasks,
      events: events,
    );

    _cacheKey = key;
    _cachedMarkers = markers;
    return markers;
  }

  Future<List<CalendarEvent>> _loadStoredEventsForMarkers({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final List<CalendarEvent> allStored =
        await _localCalendarEventRepository.getAll();
    return VisibleCalendarEventsMerger.fromStoredForRange(
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      allStored: allStored,
    );
  }
}

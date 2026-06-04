import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/services/calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/exceptions/calendar_exceptions.dart';
import 'package:smart_planner/features/dashboard/domain/dashboard_day_markers_builder.dart';
import 'package:smart_planner/features/dashboard/domain/visible_calendar_events_merger.dart';
import 'package:smart_planner/features/dashboard/domain/day_activity_marker.dart';
import 'package:smart_planner/features/todo_list/data/repositories/todo_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Cached week-range markers for the dashboard date strip (one DB + one calendar fetch).
class DashboardDayMarkersRepository {
  DashboardDayMarkersRepository({
    required TodoRepository todoRepository,
    required CalendarService calendarService,
    required LocalCalendarEventRepository localCalendarEventRepository,
  })  : _todoRepository = todoRepository,
        _calendarService = calendarService,
        _localCalendarEventRepository = localCalendarEventRepository;

  final TodoRepository _todoRepository;
  final CalendarService _calendarService;
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
        '${calendarIds.join('|')}|${start.millisecondsSinceEpoch}|'
        '${end.millisecondsSinceEpoch}';

    if (_cacheKey == key && _cachedMarkers != null) {
      return _cachedMarkers!;
    }

    final List<Task> tasks = await _todoRepository.getUncompletedTasks();
    final List<CalendarEvent> events = await _loadMergedEventsForMarkers(
      calendarIds: calendarIds,
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

  /// Isar rows (local + last synced device) merged with fresh device fetch.
  ///
  /// The dashboard strip lists events from Isar after recurrence handling; marking
  /// only from raw [getEvents] misses local-only rows and recurrence metadata.
  Future<List<CalendarEvent>> _loadMergedEventsForMarkers({
    required List<String> calendarIds,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    List<CalendarEvent> fromDevice = const <CalendarEvent>[];
    var deviceFetchSucceeded = false;

    if (calendarIds.isNotEmpty) {
      try {
        fromDevice = await _calendarService.getEvents(
          calendarIds: calendarIds,
          from: rangeStart.subtract(const Duration(days: 1)),
          to: rangeEnd.add(const Duration(days: 2)),
        );
        deviceFetchSucceeded = true;
      } on CalendarPermissionDeniedException {
        fromDevice = const <CalendarEvent>[];
      } on CalendarServiceException {
        fromDevice = const <CalendarEvent>[];
      }
    }

    if (deviceFetchSucceeded) {
      if (fromDevice.isNotEmpty) {
        await _localCalendarEventRepository.upsertDeviceEvents(fromDevice);
      }
      await _localCalendarEventRepository.purgeStaleDeviceEvents(
        fetchedInWindow: fromDevice,
        windowStart: AppDateUtils.startOfDay(rangeStart),
        windowEndExclusive:
            AppDateUtils.startOfDay(rangeEnd).add(const Duration(days: 1)),
        syncedCalendarIds: calendarIds.toSet(),
      );
    }

    final List<CalendarEvent> fromIsarAfterSync =
        await _localCalendarEventRepository.getAll();

    final Set<String> allowedCalendarIds = calendarIds.toSet();
    return VisibleCalendarEventsMerger.mergeForRange(
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      deviceEventsInRange: fromDevice,
      allStored: fromIsarAfterSync,
    ).where(
      (CalendarEvent event) =>
          allowedCalendarIds.isEmpty ||
          allowedCalendarIds.contains(event.calendarId),
    ).toList(growable: false);
  }
}

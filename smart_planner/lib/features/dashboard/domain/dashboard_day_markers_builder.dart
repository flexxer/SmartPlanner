import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/dashboard/domain/day_activity_marker.dart';

/// Builds per-day markers from pre-fetched tasks keys and calendar events.
class DashboardDayMarkersBuilder {
  DashboardDayMarkersBuilder._();

  static Map<int, DayActivityMarker> build({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required Set<int> taskDayKeys,
    required List<CalendarEvent> events,
  }) {
    final Map<int, DayActivityMarker> markers = <int, DayActivityMarker>{};
    final DateTime start = AppDateUtils.startOfDay(rangeStart);
    final DateTime end = AppDateUtils.startOfDay(rangeEnd);

    for (
      DateTime day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      final int key = AppDateUtils.dayKeyMs(day);
      final bool hasTasks = taskDayKeys.contains(key);
      final CalendarEvent? firstEvent = _firstEventOnDay(events, day);

      markers[key] = DayActivityMarker(
        hasLocalTasks: hasTasks,
        hasCalendarEvents: firstEvent != null,
        calendarColorValue: firstEvent?.colorValue,
      );
    }

    return markers;
  }

  static CalendarEvent? _firstEventOnDay(
    List<CalendarEvent> events,
    DateTime day,
  ) {
    final DateTime dayStart = AppDateUtils.startOfDay(day);
    final DateTime dayEnd = dayStart.add(const Duration(days: 1));

    for (final CalendarEvent event in events) {
      if (event.start.isBefore(dayEnd) && event.end.isAfter(dayStart)) {
        return event;
      }
    }
    return null;
  }
}

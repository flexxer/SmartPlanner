import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';

/// Decides which persisted device rows are stale after a successful device fetch.
abstract final class DeviceCalendarStalePurge {
  DeviceCalendarStalePurge._();

  /// [windowStart] inclusive, [windowEndExclusive] exclusive (calendar-day window).
  static List<CalendarEvent> rowsToRemove({
    required List<CalendarEvent> allStored,
    required List<CalendarEvent> fetchedInWindow,
    required DateTime windowStart,
    required DateTime windowEndExclusive,
    required Set<String> syncedCalendarIds,
  }) {
    if (syncedCalendarIds.isEmpty) {
      return const <CalendarEvent>[];
    }

    final Set<String> fetchedIds = <String>{
      for (final CalendarEvent event in fetchedInWindow) event.deviceEventId,
    };
    final Set<String> calendarIds = syncedCalendarIds
        .map((String id) => id.trim())
        .where((String id) => id.isNotEmpty)
        .toSet();

    return allStored
        .where(
          (CalendarEvent stored) => _shouldRemove(
            stored: stored,
            fetchedIds: fetchedIds,
            calendarIds: calendarIds,
            windowStart: windowStart,
            windowEndExclusive: windowEndExclusive,
          ),
        )
        .toList(growable: false);
  }

  static bool _shouldRemove({
    required CalendarEvent stored,
    required Set<String> fetchedIds,
    required Set<String> calendarIds,
    required DateTime windowStart,
    required DateTime windowEndExclusive,
  }) {
    if (stored.isLocalOnly) {
      return false;
    }
    if (_hasRecurrence(stored)) {
      return false;
    }
    if (!calendarIds.contains(stored.calendarId.trim())) {
      return false;
    }
    if (!_overlapsWindow(
      stored,
      windowStart: windowStart,
      windowEndExclusive: windowEndExclusive,
    )) {
      return false;
    }
    if (fetchedIds.contains(stored.deviceEventId)) {
      return false;
    }
    return true;
  }

  static bool _hasRecurrence(CalendarEvent event) {
    final String? json = event.recurrenceRuleJson;
    return json != null && json.isNotEmpty;
  }

  static bool _overlapsWindow(
    CalendarEvent event, {
    required DateTime windowStart,
    required DateTime windowEndExclusive,
  }) {
    if (event.start.isBefore(windowEndExclusive) &&
        event.end.isAfter(windowStart)) {
      return true;
    }
    return AppDateUtils.isSameCalendarDay(event.start, windowStart) ||
        AppDateUtils.isSameCalendarDay(event.end, windowStart);
  }
}

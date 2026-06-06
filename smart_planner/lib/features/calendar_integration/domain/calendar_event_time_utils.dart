import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';

/// Time-shape helpers for calendar events (all-day, cross-midnight).
abstract final class CalendarEventTimeUtils {
  CalendarEventTimeUtils._();

  static bool _atMidnight(DateTime value) =>
      value.hour == 0 && value.minute == 0 && value.second == 0;

  /// True when [event] is an all-day block (device or app convention).
  static bool isAllDay(CalendarEvent event) {
    final DateTime start = event.start;
    final DateTime end = event.end;
    final Duration span = end.difference(start);
    if (span.inMinutes < 24 * 60 - 1) {
      return false;
    }

    if (_atMidnight(start) && _atMidnight(end)) {
      return true;
    }

    // Some providers store all-day end as 23:59 on the last day.
    if (_atMidnight(start) &&
        end.hour == 23 &&
        end.minute == 59 &&
        span.inHours >= 23) {
      return true;
    }

    return false;
  }

  /// Normalizes all-day [start]/[end] to midnight boundaries for persistence.
  static ({DateTime start, DateTime end}) normalizeAllDayRange({
    required DateTime startDay,
    required DateTime endDayInclusive,
  }) {
    final DateTime start = AppDateUtils.startOfDay(startDay);
    final DateTime end =
        AppDateUtils.startOfDay(endDayInclusive).add(const Duration(days: 1));
    return (start: start, end: end);
  }

  /// Whether [event] intersects the calendar day [day] (any time shape).
  static bool overlapsCalendarDay(CalendarEvent event, DateTime day) {
    final DateTime dayStart = AppDateUtils.startOfDay(day);
    final DateTime dayEnd = dayStart.add(const Duration(days: 1));
    return event.start.isBefore(dayEnd) && event.end.isAfter(dayStart);
  }

  /// Clip [event] to [selectedDay] for display labels.
  static ({
    DateTime displayStart,
    DateTime displayEnd,
    bool continuesFromPrevious,
    bool continuesToNext,
    bool spansFullDay,
  }) displayBoundsOnDay(CalendarEvent event, DateTime selectedDay) {
    final DateTime dayStart = AppDateUtils.startOfDay(selectedDay);
    final DateTime dayEnd = dayStart.add(const Duration(days: 1));

    final DateTime displayStart =
        event.start.isBefore(dayStart) ? dayStart : event.start;
    final DateTime displayEnd =
        event.end.isAfter(dayEnd) ? dayEnd : event.end;

    return (
      displayStart: displayStart,
      displayEnd: displayEnd,
      continuesFromPrevious: event.start.isBefore(dayStart),
      continuesToNext: event.end.isAfter(dayEnd),
      spansFullDay: displayStart == dayStart && displayEnd == dayEnd,
    );
  }

  /// Validates timed event bounds (allows end on the next calendar day).
  static bool isValidTimedRange(DateTime start, DateTime end) {
    return end.isAfter(start);
  }
}

/// Timed portion of an event on one calendar day (excludes all-day rows).
final class CalendarEventDayBounds {
  const CalendarEventDayBounds({
    required this.event,
    required this.start,
    required this.end,
    required this.continuesFromPreviousDay,
    required this.continuesToNextDay,
  });

  final CalendarEvent event;
  final DateTime start;
  final DateTime end;
  final bool continuesFromPreviousDay;
  final bool continuesToNextDay;

  bool overlaps(CalendarEventDayBounds other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }
}

import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_time_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/recurrence_evaluator.dart';

/// Start/end of a [CalendarEvent] occurrence on a specific calendar day.
class CalendarEventOccurrence {
  CalendarEventOccurrence._();

  /// Returns timed bounds on [day], or `null` if not visible or all-day.
  static CalendarEventDayBounds? timedBoundsOnDay(
    CalendarEvent event,
    DateTime day,
  ) {
    if (CalendarEventTimeUtils.isAllDay(event)) {
      return null;
    }
    if (!_isVisibleOnDay(event, day)) {
      return null;
    }

    final ({DateTime start, DateTime end})? interval =
        _occurrenceInterval(event, day);
    if (interval == null) {
      return null;
    }

    final DateTime dayStart = AppDateUtils.startOfDay(day);
    final DateTime dayEnd = dayStart.add(const Duration(days: 1));

    final DateTime start =
        interval.start.isBefore(dayStart) ? dayStart : interval.start;
    final DateTime end =
        interval.end.isAfter(dayEnd) ? dayEnd : interval.end;

    if (!end.isAfter(start)) {
      return null;
    }

    return CalendarEventDayBounds(
      event: event,
      start: start,
      end: end,
      continuesFromPreviousDay: interval.start.isBefore(dayStart),
      continuesToNextDay: interval.end.isAfter(dayEnd),
    );
  }

  /// All-day events visible on [day].
  static List<CalendarEvent> allDayEventsOnDay(
    List<CalendarEvent> events,
    DateTime day,
  ) {
    return events
        .where(
          (CalendarEvent event) =>
              CalendarEventTimeUtils.isAllDay(event) &&
              _isVisibleOnDay(event, day) &&
              CalendarEventTimeUtils.overlapsCalendarDay(event, day),
        )
        .toList()
      ..sort(
        (CalendarEvent a, CalendarEvent b) => a.title.compareTo(b.title),
      );
  }

  /// @deprecated Use [timedBoundsOnDay].
  static ({DateTime start, DateTime end})? boundsOnDay(
    CalendarEvent event,
    DateTime day,
  ) {
    final CalendarEventDayBounds? bounds = timedBoundsOnDay(event, day);
    if (bounds == null) {
      return null;
    }
    return (start: bounds.start, end: bounds.end);
  }

  static ({DateTime start, DateTime end})? _occurrenceInterval(
    CalendarEvent event,
    DateTime day,
  ) {
    final String? recurrenceJson = event.recurrenceRuleJson;
    if (recurrenceJson == null || recurrenceJson.isEmpty) {
      if (!CalendarEventTimeUtils.overlapsCalendarDay(event, day)) {
        return null;
      }
      return (start: event.start, end: event.end);
    }

    final Duration length = event.end.difference(event.start);
    final DateTime start = DateTime(
      day.year,
      day.month,
      day.day,
      event.start.hour,
      event.start.minute,
      event.start.second,
      event.start.millisecond,
      event.start.microsecond,
    );
    return (start: start, end: start.add(length));
  }

  static bool _isVisibleOnDay(CalendarEvent event, DateTime day) {
    final String? recurrenceJson = event.recurrenceRuleJson;
    if (recurrenceJson == null || recurrenceJson.isEmpty) {
      return CalendarEventTimeUtils.overlapsCalendarDay(event, day);
    }
    return RecurrenceEvaluator.shouldShowEventOnDate(event, day);
  }
}

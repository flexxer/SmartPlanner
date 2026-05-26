import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/recurrence_evaluator.dart';

/// Start/end of a [CalendarEvent] occurrence on a specific calendar day.
class CalendarEventOccurrence {
  CalendarEventOccurrence._();

  /// Returns occurrence bounds on [day], or `null` if the event is not visible that day.
  static ({DateTime start, DateTime end})? boundsOnDay(
    CalendarEvent event,
    DateTime day,
  ) {
    if (!RecurrenceEvaluator.shouldShowEventOnDate(event, day)) {
      return null;
    }

    final DateTime dayStart = AppDateUtils.startOfDay(day);
    final DateTime anchorStart = event.start;
    final DateTime start = DateTime(
      dayStart.year,
      dayStart.month,
      dayStart.day,
      anchorStart.hour,
      anchorStart.minute,
      anchorStart.second,
      anchorStart.millisecond,
      anchorStart.microsecond,
    );

    final Duration duration = event.end.difference(event.start);
    DateTime end = start.add(duration);

    final DateTime dayEnd = dayStart.add(const Duration(days: 1));
    if (!end.isAfter(start)) {
      end = start.add(const Duration(minutes: 30));
    }
    if (end.isAfter(dayEnd)) {
      end = dayEnd.subtract(const Duration(minutes: 1));
    }

    return (start: start, end: end);
  }
}

import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';

/// Visual timeline bucket for a calendar event on the dashboard strip.
enum EventTimeStatus {
  past,
  current,
  future,
  neutral,
}

/// Maps [event] to [EventTimeStatus] for [selectedDay] vs device [now].
class EventTimeStatusResolver {
  EventTimeStatusResolver._();

  static EventTimeStatus resolve({
    required CalendarEvent event,
    required DateTime selectedDay,
    required DateTime now,
  }) {
    if (!AppDateUtils.isSameCalendarDay(selectedDay, now)) {
      return EventTimeStatus.neutral;
    }

    if (event.end.isBefore(now)) {
      return EventTimeStatus.past;
    }
    if (!event.start.isAfter(now) && !event.end.isBefore(now)) {
      return EventTimeStatus.current;
    }
    if (event.start.isAfter(now)) {
      return EventTimeStatus.future;
    }

    return EventTimeStatus.neutral;
  }

  /// Fraction of the calendar day (0..1) for [now] on [selectedDay].
  static double dayProgressFraction(DateTime selectedDay, DateTime now) {
    if (!AppDateUtils.isSameCalendarDay(selectedDay, now)) {
      return 0;
    }
    final DateTime dayStart = AppDateUtils.startOfDay(selectedDay);
    final int minutes = now.difference(dayStart).inMinutes;
    return (minutes / (24 * 60)).clamp(0.0, 1.0);
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_time_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';

/// Formats event start/end for dashboard cards (cross-midnight aware).
abstract final class EventTimeRangeLabel {
  EventTimeRangeLabel._();

  static String format({
    required CalendarEvent event,
    required DateTime selectedDay,
    required DateFormat timeFormat,
  }) {
    if (CalendarEventTimeUtils.isAllDay(event)) {
      return _allDayLabel(event, selectedDay);
    }

    final ({
      DateTime displayStart,
      DateTime displayEnd,
      bool continuesFromPrevious,
      bool continuesToNext,
      bool spansFullDay,
    }) bounds = CalendarEventTimeUtils.displayBoundsOnDay(
      event,
      selectedDay,
    );

    if (bounds.spansFullDay) {
      return 'events_all_day_on_day'.tr();
    }
    if (bounds.continuesFromPrevious && bounds.continuesToNext) {
      return 'events_all_day_on_day'.tr();
    }
    if (bounds.continuesFromPrevious) {
      return 'events_continues_until'
          .tr(namedArgs: <String, String>{
        'time': timeFormat.format(event.end),
      });
    }
    if (bounds.continuesToNext) {
      return 'events_continues_from'
          .tr(namedArgs: <String, String>{
        'time': timeFormat.format(event.start),
      });
    }

    return '${timeFormat.format(bounds.displayStart)} – '
        '${timeFormat.format(bounds.displayEnd)}';
  }

  static String _allDayLabel(CalendarEvent event, DateTime selectedDay) {
    final DateTime dayStart = AppDateUtils.startOfDay(selectedDay);
    final DateTime eventStartDay = AppDateUtils.startOfDay(event.start);
    final DateTime eventEndDay =
        AppDateUtils.startOfDay(event.end.subtract(const Duration(minutes: 1)));

    if (eventStartDay.isBefore(dayStart) && eventEndDay.isAfter(dayStart)) {
      return 'events_all_day_on_day'.tr();
    }
    if (eventStartDay.isBefore(dayStart)) {
      return 'events_continues_from_previous'.tr();
    }
    if (eventEndDay.isAfter(dayStart)) {
      return 'events_continues_to_next'.tr();
    }
    return 'events_all_day'.tr();
  }
}

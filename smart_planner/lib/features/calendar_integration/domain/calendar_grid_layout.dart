import 'package:smart_planner/core/utils/app_date_utils.dart';

/// Layout math for the week time grid (00:00–23:59).
class CalendarGridLayout {
  CalendarGridLayout._();

  static const int hoursPerDay = 24;
  static const double defaultHourHeight = 56;
  static const Duration defaultSlotDuration = Duration(hours: 1);
  static const Duration minEventDuration = Duration(minutes: 15);

  static double dayTimelineHeight(double hourHeight) =>
      hourHeight * hoursPerDay;

  static double topOffsetForTime(DateTime time, double hourHeight) {
    final double minutesFromMidnight =
        time.hour * 60 + time.minute + time.second / 60;
    return (minutesFromMidnight / (hoursPerDay * 60)) *
        dayTimelineHeight(hourHeight);
  }

  static double heightForInterval({
    required DateTime start,
    required DateTime end,
    required double hourHeight,
  }) {
    final Duration raw = end.difference(start);
    final Duration duration = raw < minEventDuration ? minEventDuration : raw;
    return (duration.inMinutes / (hoursPerDay * 60)) *
        dayTimelineHeight(hourHeight);
  }

  /// Maps a vertical tap on the day column to a one-hour slot.
  static ({DateTime start, DateTime end}) slotFromLocalY({
    required DateTime day,
    required double localY,
    required double hourHeight,
    Duration slotDuration = defaultSlotDuration,
  }) {
    final double totalHeight = dayTimelineHeight(hourHeight);
    final double fraction = (localY / totalHeight).clamp(0.0, 0.999);
    final int totalMinutes = (fraction * hoursPerDay * 60).floor();
    final int hour = totalMinutes ~/ 60;
    final int minute = totalMinutes % 60;

    final DateTime start = DateTime(day.year, day.month, day.day, hour, minute);
    DateTime end = start.add(slotDuration);

    final DateTime dayEnd =
        AppDateUtils.startOfDay(day).add(const Duration(days: 1));
    if (!end.isBefore(dayEnd) && end != dayEnd) {
      end = dayEnd.subtract(const Duration(minutes: 1));
      if (!end.isAfter(start)) {
        end = start.add(const Duration(minutes: 30));
      }
    }

    return (start: start, end: end);
  }
}

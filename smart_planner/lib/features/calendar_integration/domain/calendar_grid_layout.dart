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

  /// Scroll offset so [time] sits near the top of the viewport ([viewportLeadFraction]).
  static double scrollOffsetForTime({
    required DateTime time,
    required double hourHeight,
    required double viewportHeight,
    double viewportLeadFraction = 0.25,
  }) {
    final double timeTop = topOffsetForTime(time, hourHeight);
    final double maxScroll =
        (dayTimelineHeight(hourHeight) - viewportHeight).clamp(0.0, double.infinity);
    return (timeTop - viewportHeight * viewportLeadFraction).clamp(0.0, maxScroll);
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

  static const Duration slotSnapStep = Duration(minutes: 15);

  /// Maps a vertical tap on the day column to a one-hour slot aligned to the hour.
  static ({DateTime start, DateTime end}) slotFromLocalY({
    required DateTime day,
    required double localY,
    required double hourHeight,
    Duration slotDuration = defaultSlotDuration,
  }) {
    final DateTime start = snapSlotStart(
      day: day,
      localY: localY,
      hourHeight: hourHeight,
    );
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

  /// Hour-aligned slot start for long-press create (e.g. 16:00, not 16:38).
  static DateTime snapSlotStart({
    required DateTime day,
    required double localY,
    required double hourHeight,
  }) {
    final double totalHeight = dayTimelineHeight(hourHeight);
    final double fraction = (localY / totalHeight).clamp(0.0, 0.999);
    final int hour = (fraction * hoursPerDay).floor().clamp(0, hoursPerDay - 1);
    return DateTime(day.year, day.month, day.day, hour);
  }

  /// End time while dragging after long-press; snapped to [slotSnapStep].
  static DateTime snapSelectionEnd({
    required DateTime day,
    required DateTime start,
    required double localY,
    required double hourHeight,
  }) {
    final double totalHeight = dayTimelineHeight(hourHeight);
    final double fraction = (localY / totalHeight).clamp(0.0, 1.0);
    final int rawMinutes = (fraction * hoursPerDay * 60).round();
    final int snappedMinutes =
        ((rawMinutes + slotSnapStep.inMinutes - 1) ~/ slotSnapStep.inMinutes) *
            slotSnapStep.inMinutes;
    final DateTime dayStart = AppDateUtils.startOfDay(day);
    final DateTime dayEnd = dayStart.add(const Duration(days: 1));

    DateTime end = dayStart.add(Duration(minutes: snappedMinutes));
    if (end.isAfter(dayEnd)) {
      end = dayEnd;
    }
    if (!end.isAfter(start)) {
      end = start.add(slotSnapStep);
    }
    return end;
  }
}

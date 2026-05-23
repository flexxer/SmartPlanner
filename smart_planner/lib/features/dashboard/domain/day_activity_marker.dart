/// Activity indicators for one day on the dashboard date strip.
class DayActivityMarker {
  const DayActivityMarker({
    this.hasCalendarEvents = false,
    this.hasLocalTasks = false,
    this.calendarColorValue,
  });

  const DayActivityMarker.empty()
      : hasCalendarEvents = false,
        hasLocalTasks = false,
        calendarColorValue = null;

  final bool hasCalendarEvents;
  final bool hasLocalTasks;

  /// Device calendar color for the dot; UI falls back to [ColorScheme.primary].
  final int? calendarColorValue;

  bool get hasAnyIndicator => hasCalendarEvents || hasLocalTasks;
}

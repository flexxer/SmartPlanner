/// Activity indicators for one day on the dashboard date strip.
class DayActivityMarker {
  const DayActivityMarker({
    this.hasCalendarEvents = false,
    this.hasLocalTasks = false,
    this.calendarColorValue,
    this.eventCount = 0,
    this.timedTaskCount = 0,
  });

  const DayActivityMarker.empty()
      : hasCalendarEvents = false,
        hasLocalTasks = false,
        calendarColorValue = null,
        eventCount = 0,
        timedTaskCount = 0;

  final bool hasCalendarEvents;
  final bool hasLocalTasks;

  /// Device calendar color for month-grid dots; UI falls back to [ColorScheme.primary].
  final int? calendarColorValue;

  /// Calendar events overlapping this calendar day.
  final int eventCount;

  /// Root tasks due or reminded on this day (not overdue carry-over days).
  final int timedTaskCount;

  bool get hasAnyIndicator => hasCalendarEvents || hasLocalTasks;

  /// Compact `events+tasks` label for the date-strip badge.
  String get stripBadgeLabel {
    if (eventCount > 0 && timedTaskCount > 0) {
      return '$eventCount+$timedTaskCount';
    }
    if (eventCount > 0) {
      return '$eventCount';
    }
    if (timedTaskCount > 0) {
      return '$timedTaskCount';
    }
    return '';
  }

  bool get hasStripBadge => stripBadgeLabel.isNotEmpty;
}

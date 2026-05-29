/// Preset offsets for item reminders (minutes before due/start time).
abstract final class ReminderOptions {
  ReminderOptions._();

  /// UI sentinel for “no reminder”; persisted as [null] on [Task]/[CalendarEvent].
  static const int noneSentinel = -1;

  static const int defaultMinutes = 30;

  /// Minutes before the anchor time; `0` = at anchor time.
  static const List<int> selectableMinutes = <int>[
    0,
    5,
    15,
    30,
    60,
    120,
    1440,
  ];

  static bool isValid(int? minutes) {
    if (minutes == null) {
      return true;
    }
    return selectableMinutes.contains(minutes);
  }
}

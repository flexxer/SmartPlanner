/// Утилиты для работы с датами (перенос задач, просрочка).
class AppDateUtils {
  AppDateUtils._();

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Календарные дни между двумя датами (без учёта времени суток).
  static int calendarDaysBetween(DateTime from, DateTime to) {
    final int diff =
        startOfDay(to).difference(startOfDay(from)).inDays;
    return diff > 0 ? diff : 0;
  }

  static bool isSameCalendarDay(DateTime a, DateTime b) {
    final DateTime dayA = startOfDay(a);
    final DateTime dayB = startOfDay(b);
    return dayA.year == dayB.year &&
        dayA.month == dayB.month &&
        dayA.day == dayB.day;
  }

  static bool isToday(DateTime date) =>
      isSameCalendarDay(date, DateTime.now());

  /// Monday-based start of the ISO week containing [date].
  static DateTime startOfWeek(DateTime date) {
    final DateTime day = startOfDay(date);
    final int daysFromMonday = day.weekday - DateTime.monday;
    return day.subtract(Duration(days: daysFromMonday));
  }

  /// Stable map key for a calendar day (local midnight epoch ms).
  static int dayKeyMs(DateTime date) => startOfDay(date).millisecondsSinceEpoch;

  /// Inclusive range for date-strip markers around [selectedDate] (3 weeks).
  static ({DateTime start, DateTime end}) dateStripMarkerRange(
    DateTime selectedDate,
  ) {
    final DateTime weekStart = startOfWeek(selectedDate);
    final DateTime start = weekStart.subtract(const Duration(days: 7));
    final DateTime end = weekStart.add(const Duration(days: 20));
    return (start: start, end: end);
  }

  /// Days shown on the horizontal strip (21 days, previous + current + next week).
  static List<DateTime> dateStripDays(DateTime selectedDate) {
    final DateTime stripStart =
        startOfWeek(selectedDate).subtract(const Duration(days: 7));
    return List<DateTime>.generate(
      21,
      (int index) => stripStart.add(Duration(days: index)),
    );
  }
}

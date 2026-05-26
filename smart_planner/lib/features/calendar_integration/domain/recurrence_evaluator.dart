import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_frequency.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';

/// Decides whether a recurring [CalendarEvent] has a virtual occurrence on [targetDate].
class RecurrenceEvaluator {
  RecurrenceEvaluator._();

  /// Returns `true` when [event] should appear on the calendar day [targetDate].
  static bool shouldShowEventOnDate(CalendarEvent event, DateTime targetDate) {
    final DateTime target = AppDateUtils.startOfDay(targetDate);
    final DateTime anchor = AppDateUtils.startOfDay(event.start);

    if (target.isBefore(anchor)) {
      return false;
    }

    final String? json = event.recurrenceRuleJson;
    if (json == null || json.isEmpty) {
      return AppDateUtils.isSameCalendarDay(target, anchor);
    }

    final RecurrenceRule rule = RecurrenceRule.fromJsonString(json);

    final DateTime? until = rule.until;
    if (until != null && target.isAfter(AppDateUtils.startOfDay(until))) {
      return false;
    }

    if (rule.frequency == RecurrenceFrequency.none) {
      return AppDateUtils.isSameCalendarDay(target, anchor);
    }

    return _matchesRule(rule: rule, anchor: anchor, target: target);
  }

  static bool _matchesRule({
    required RecurrenceRule rule,
    required DateTime anchor,
    required DateTime target,
  }) {
    return switch (rule.frequency) {
      RecurrenceFrequency.none =>
        AppDateUtils.isSameCalendarDay(target, anchor),
      RecurrenceFrequency.daily => _matchesDaily(rule, anchor, target),
      RecurrenceFrequency.weekly => _matchesWeekly(rule, anchor, target),
      RecurrenceFrequency.monthly => _matchesMonthly(rule, anchor, target),
      RecurrenceFrequency.yearly => _matchesYearly(rule, anchor, target),
    };
  }

  static bool _matchesDaily(
    RecurrenceRule rule,
    DateTime anchor,
    DateTime target,
  ) {
    final int interval = _positiveInterval(rule.interval);
    final int daysBetween = AppDateUtils.calendarDaysBetween(anchor, target);
    return daysBetween % interval == 0;
  }

  static bool _matchesWeekly(
    RecurrenceRule rule,
    DateTime anchor,
    DateTime target,
  ) {
    final List<int> weekdays = rule.daysOfWeek ?? <int>[anchor.weekday];
    if (!weekdays.contains(target.weekday)) {
      return false;
    }

    final int interval = _positiveInterval(rule.interval);
    final int weeksBetween = _weeksBetweenMondayBased(anchor, target);
    return weeksBetween % interval == 0;
  }

  static bool _matchesMonthly(
    RecurrenceRule rule,
    DateTime anchor,
    DateTime target,
  ) {
    final int interval = _positiveInterval(rule.interval);
    final int monthsBetween = _monthsBetween(anchor, target);
    if (monthsBetween < 0 || monthsBetween % interval != 0) {
      return false;
    }

    final int? dayOfMonth = rule.dayOfMonth;
    if (dayOfMonth != null) {
      return target.day == dayOfMonth;
    }

    final int? weekOfMonth = rule.weekOfMonth;
    if (weekOfMonth == 1 && rule.onlyWorkingDays) {
      final DateTime? firstWorking =
          _firstWorkingDayOfMonth(target.year, target.month);
      return firstWorking != null &&
          AppDateUtils.isSameCalendarDay(target, firstWorking);
    }

    final List<int>? daysOfWeek = rule.daysOfWeek;
    if (weekOfMonth != null && daysOfWeek != null && daysOfWeek.isNotEmpty) {
      return daysOfWeek.any(
        (int weekday) =>
            _isNthWeekdayOfMonth(target, weekOfMonth, weekday),
      );
    }

    return AppDateUtils.isSameCalendarDay(target, anchor);
  }

  static bool _matchesYearly(
    RecurrenceRule rule,
    DateTime anchor,
    DateTime target,
  ) {
    if (target.month != anchor.month || target.day != anchor.day) {
      return false;
    }

    final int interval = _positiveInterval(rule.interval);
    final int yearsBetween = target.year - anchor.year;
    return yearsBetween >= 0 && yearsBetween % interval == 0;
  }

  static bool _isNthWeekdayOfMonth(
    DateTime date,
    int weekOfMonth,
    int weekday,
  ) {
    if (weekOfMonth > 0) {
      final DateTime first =
          _firstWeekdayInMonth(date.year, date.month, weekday);
      final DateTime candidate =
          first.add(Duration(days: 7 * (weekOfMonth - 1)));
      return candidate.month == date.month &&
          AppDateUtils.isSameCalendarDay(candidate, date);
    }

    if (weekOfMonth == -1) {
      final DateTime last =
          _lastWeekdayInMonth(date.year, date.month, weekday);
      return AppDateUtils.isSameCalendarDay(last, date);
    }

    return false;
  }

  static DateTime _firstWeekdayInMonth(int year, int month, int weekday) {
    DateTime cursor = DateTime(year, month, 1);
    while (cursor.weekday != weekday) {
      cursor = cursor.add(const Duration(days: 1));
    }
    return cursor;
  }

  static DateTime _lastWeekdayInMonth(int year, int month, int weekday) {
    DateTime cursor = DateTime(year, month + 1, 0);
    while (cursor.weekday != weekday) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return cursor;
  }

  /// First Monday–Friday on or after the 1st of [month] in [year].
  static DateTime? _firstWorkingDayOfMonth(int year, int month) {
    DateTime cursor = DateTime(year, month, 1);
    final int lastDay = DateTime(year, month + 1, 0).day;
    while (cursor.day <= lastDay) {
      if (_isWorkingDay(cursor)) {
        return cursor;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return null;
  }

  static bool _isWorkingDay(DateTime date) {
    return date.weekday >= DateTime.monday &&
        date.weekday <= DateTime.friday;
  }

  static int _weeksBetweenMondayBased(DateTime anchor, DateTime target) {
    final DateTime anchorWeek = AppDateUtils.startOfWeek(anchor);
    final DateTime targetWeek = AppDateUtils.startOfWeek(target);
    return targetWeek.difference(anchorWeek).inDays ~/ 7;
  }

  static int _monthsBetween(DateTime anchor, DateTime target) {
    return (target.year - anchor.year) * 12 + (target.month - anchor.month);
  }

  static int _positiveInterval(int interval) {
    return interval < 1 ? 1 : interval;
  }
}

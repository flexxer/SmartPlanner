import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/recurrence_evaluator.dart';

/// Builds visible calendar event lists from Isar rows (no device import).
abstract final class VisibleCalendarEventsMerger {
  VisibleCalendarEventsMerger._();

  /// Events visible on [selectedDay] from [allStored] Isar rows.
  static List<CalendarEvent> merge({
    required DateTime selectedDay,
    required List<CalendarEvent> deviceEventsForDay,
    required List<CalendarEvent> allStored,
  }) {
    return fromStored(
      selectedDay: selectedDay,
      allStored: allStored,
    );
  }

  /// Week/month grid: events in [rangeStart]…[rangeEnd] from Isar only.
  static List<CalendarEvent> mergeForRange({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required List<CalendarEvent> deviceEventsInRange,
    required List<CalendarEvent> allStored,
  }) {
    return fromStoredForRange(
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      allStored: allStored,
    );
  }

  static List<CalendarEvent> fromStored({
    required DateTime selectedDay,
    required List<CalendarEvent> allStored,
  }) {
    final List<CalendarEvent> visible = <CalendarEvent>[];
    final Set<int> addedIds = <int>{};

    for (final CalendarEvent stored in allStored) {
      if (_hasRecurrence(stored)) {
        continue;
      }
      if (!RecurrenceEvaluator.shouldShowEventOnDate(stored, selectedDay)) {
        continue;
      }
      if (addedIds.add(stored.id)) {
        visible.add(stored);
      }
    }

    _appendRecurringStoredOccurrences(
      visible: visible,
      selectedDay: selectedDay,
      allStored: allStored,
    );

    visible.sort(
      (CalendarEvent a, CalendarEvent b) => a.start.compareTo(b.start),
    );
    return visible;
  }

  static List<CalendarEvent> fromStoredForRange({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required List<CalendarEvent> allStored,
  }) {
    final DateTime rangeDayStart = AppDateUtils.startOfDay(rangeStart);
    final DateTime rangeDayEndExclusive =
        AppDateUtils.startOfDay(rangeEnd).add(const Duration(days: 1));

    final List<CalendarEvent> visible = <CalendarEvent>[];
    final Set<int> addedIds = <int>{};

    for (final CalendarEvent stored in allStored) {
      if (_hasRecurrence(stored)) {
        continue;
      }
      if (!_isVisibleInRange(
        stored,
        rangeDayStart: rangeDayStart,
        rangeDayEndExclusive: rangeDayEndExclusive,
      )) {
        continue;
      }
      if (addedIds.add(stored.id)) {
        visible.add(stored);
      }
    }

    _appendRecurringStoredOccurrencesForRange(
      visible: visible,
      rangeDayStart: rangeDayStart,
      rangeDayEndExclusive: rangeDayEndExclusive,
      allStored: allStored,
    );

    visible.sort(
      (CalendarEvent a, CalendarEvent b) => a.start.compareTo(b.start),
    );
    return visible;
  }

  static bool _isVisibleInRange(
    CalendarEvent event, {
    required DateTime rangeDayStart,
    required DateTime rangeDayEndExclusive,
  }) {
    for (DateTime day = rangeDayStart;
        day.isBefore(rangeDayEndExclusive);
        day = day.add(const Duration(days: 1))) {
      if (RecurrenceEvaluator.shouldShowEventOnDate(event, day)) {
        return true;
      }
    }
    return false;
  }

  static void _appendRecurringStoredOccurrences({
    required List<CalendarEvent> visible,
    required DateTime selectedDay,
    required List<CalendarEvent> allStored,
  }) {
    for (final CalendarEvent stored in allStored) {
      if (!_hasRecurrence(stored)) {
        continue;
      }
      if (!RecurrenceEvaluator.shouldShowEventOnDate(stored, selectedDay)) {
        continue;
      }
      if (_visibleCoversCalendarDay(visible, stored, selectedDay)) {
        continue;
      }
      visible.add(_occurrenceOnDay(stored, selectedDay));
    }
  }

  static void _appendRecurringStoredOccurrencesForRange({
    required List<CalendarEvent> visible,
    required DateTime rangeDayStart,
    required DateTime rangeDayEndExclusive,
    required List<CalendarEvent> allStored,
  }) {
    for (DateTime day = rangeDayStart;
        day.isBefore(rangeDayEndExclusive);
        day = day.add(const Duration(days: 1))) {
      _appendRecurringStoredOccurrences(
        visible: visible,
        selectedDay: day,
        allStored: allStored,
      );
    }
  }

  static bool _hasRecurrence(CalendarEvent event) {
    final String? json = event.recurrenceRuleJson;
    return json != null && json.trim().isNotEmpty;
  }

  static bool _visibleCoversCalendarDay(
    List<CalendarEvent> visible,
    CalendarEvent stored,
    DateTime day,
  ) {
    for (final CalendarEvent event in visible) {
      if (event.id != stored.id) {
        continue;
      }
      if (_overlapsCalendarDay(event, day)) {
        return true;
      }
    }
    return false;
  }

  static bool _overlapsCalendarDay(CalendarEvent event, DateTime day) {
    final DateTime dayStart = AppDateUtils.startOfDay(day);
    final DateTime dayEnd = dayStart.add(const Duration(days: 1));
    return event.start.isBefore(dayEnd) && event.end.isAfter(dayStart);
  }

  static CalendarEvent _occurrenceOnDay(CalendarEvent master, DateTime day) {
    if (AppDateUtils.isSameCalendarDay(master.start, day)) {
      return master;
    }

    final Duration length = master.end.difference(master.start);
    final DateTime start = DateTime(
      day.year,
      day.month,
      day.day,
      master.start.hour,
      master.start.minute,
      master.start.second,
      master.start.millisecond,
      master.start.microsecond,
    );
    final DateTime end = start.add(length);

    return CalendarEvent.fromDevice(
      deviceEventId: master.deviceEventId,
      title: master.title,
      start: start,
      end: end,
      calendarId: master.calendarId,
      colorValue: master.colorValue,
      googleEventId: master.googleEventId,
      recurrenceRule: master.recurrenceRule,
      linkedTaskIds: List<int>.from(master.linkedTaskIds),
      source: master.source,
    )..id = master.id
      ..reminderMinutesBefore = master.reminderMinutesBefore
      ..recurrenceRuleJson = master.recurrenceRuleJson
      ..syncedDeviceEventIdsJson = master.syncedDeviceEventIdsJson
      ..updatedAt = master.updatedAt;
  }
}

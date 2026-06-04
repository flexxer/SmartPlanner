import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_source.dart';
import 'package:smart_planner/features/calendar_integration/domain/recurrence_evaluator.dart';

/// Builds the dashboard event strip: device fetch is authoritative for times.
abstract final class VisibleCalendarEventsMerger {
  VisibleCalendarEventsMerger._();

  /// [deviceEventsForDay] — fresh rows from [DeviceCalendarService.getEventsForDay].
  /// [allStored] — Isar rows (after [upsertDeviceEvents]).
  static List<CalendarEvent> merge({
    required DateTime selectedDay,
    required List<CalendarEvent> deviceEventsForDay,
    required List<CalendarEvent> allStored,
  }) {
    final Map<String, CalendarEvent> storedByDeviceId =
        <String, CalendarEvent>{
      for (final CalendarEvent event in allStored) event.deviceEventId: event,
    };

    final Set<String> deviceIdsOnDay = <String>{
      for (final CalendarEvent event in deviceEventsForDay) event.deviceEventId,
    };

    final List<CalendarEvent> visible = <CalendarEvent>[];

    for (final CalendarEvent fresh in deviceEventsForDay) {
      final CalendarEvent? stored = storedByDeviceId[fresh.deviceEventId];
      if (stored != null) {
        visible.add(_withStoredMetadata(fresh, stored));
      } else {
        visible.add(fresh);
      }
    }

    for (final CalendarEvent stored in allStored) {
      if (!stored.isLocalOnly) {
        continue;
      }
      if (_isShadowedByDeviceOnDay(
        local: stored,
        deviceEvents: deviceEventsForDay,
        day: selectedDay,
      )) {
        continue;
      }
      if (!RecurrenceEvaluator.shouldShowEventOnDate(stored, selectedDay)) {
        continue;
      }
      if (deviceIdsOnDay.contains(stored.deviceEventId)) {
        continue;
      }
      visible.add(stored);
    }

    _appendRecurringStoredOccurrences(
      visible: visible,
      selectedDay: selectedDay,
      allStored: allStored,
      deviceEventsForDay: deviceEventsForDay,
    );

    visible.sort(
      (CalendarEvent a, CalendarEvent b) => a.start.compareTo(b.start),
    );
    return visible;
  }

  /// Week/month grid: fresh device rows for [rangeStart]…[rangeEnd] plus local-only.
  static List<CalendarEvent> mergeForRange({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required List<CalendarEvent> deviceEventsInRange,
    required List<CalendarEvent> allStored,
  }) {
    final DateTime rangeDayStart = AppDateUtils.startOfDay(rangeStart);
    final DateTime rangeDayEndExclusive =
        AppDateUtils.startOfDay(rangeEnd).add(const Duration(days: 1));

    final Map<String, CalendarEvent> storedByDeviceId =
        <String, CalendarEvent>{
      for (final CalendarEvent event in allStored) event.deviceEventId: event,
    };

    final Set<String> deviceIdsInRange = <String>{
      for (final CalendarEvent event in deviceEventsInRange)
        event.deviceEventId,
    };

    final List<CalendarEvent> visible = <CalendarEvent>[];

    for (final CalendarEvent fresh in deviceEventsInRange) {
      final CalendarEvent? stored = storedByDeviceId[fresh.deviceEventId];
      if (stored != null) {
        visible.add(_withStoredMetadata(fresh, stored));
      } else {
        visible.add(fresh);
      }
    }

    for (final CalendarEvent stored in allStored) {
      if (!stored.isLocalOnly) {
        continue;
      }
      if (deviceIdsInRange.contains(stored.deviceEventId)) {
        continue;
      }
      if (_isShadowedByDeviceInRange(
        local: stored,
        deviceEvents: deviceEventsInRange,
        rangeDayStart: rangeDayStart,
        rangeDayEndExclusive: rangeDayEndExclusive,
      )) {
        continue;
      }
      if (!_isVisibleInRange(
        stored,
        rangeDayStart: rangeDayStart,
        rangeDayEndExclusive: rangeDayEndExclusive,
      )) {
        continue;
      }
      visible.add(stored);
    }

    _appendRecurringStoredOccurrencesForRange(
      visible: visible,
      rangeDayStart: rangeDayStart,
      rangeDayEndExclusive: rangeDayEndExclusive,
      allStored: allStored,
      deviceEventsInRange: deviceEventsInRange,
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

  static bool _isShadowedByDeviceOnDay({
    required CalendarEvent local,
    required List<CalendarEvent> deviceEvents,
    required DateTime day,
  }) {
    if (!local.isLocalOnly) {
      return false;
    }
    final String titleKey = local.title.trim().toLowerCase();
    for (final CalendarEvent device in deviceEvents) {
      if (device.title.trim().toLowerCase() != titleKey) {
        continue;
      }
      if (AppDateUtils.isSameCalendarDay(device.start, day)) {
        return true;
      }
    }
    return false;
  }

  static bool _isShadowedByDeviceInRange({
    required CalendarEvent local,
    required List<CalendarEvent> deviceEvents,
    required DateTime rangeDayStart,
    required DateTime rangeDayEndExclusive,
  }) {
    for (DateTime day = rangeDayStart;
        day.isBefore(rangeDayEndExclusive);
        day = day.add(const Duration(days: 1))) {
      if (_isShadowedByDeviceOnDay(
        local: local,
        deviceEvents: deviceEvents,
        day: day,
      )) {
        return true;
      }
    }
    return false;
  }

  /// Device fields from [fresh]; Isar id / links from [stored].
  static CalendarEvent _withStoredMetadata(
    CalendarEvent fresh,
    CalendarEvent stored,
  ) {
    _applyDeviceFields(stored, fresh);
    return CalendarEvent.fromDevice(
      deviceEventId: fresh.deviceEventId,
      title: fresh.title,
      start: fresh.start,
      end: fresh.end,
      calendarId: fresh.calendarId,
      colorValue: fresh.colorValue,
      googleEventId: stored.googleEventId,
      recurrenceRule: stored.recurrenceRule,
      linkedTaskIds: List<int>.from(stored.linkedTaskIds),
    )..id = stored.id
      ..reminderMinutesBefore = stored.reminderMinutesBefore
      ..recurrenceRuleJson = stored.recurrenceRuleJson
      ..updatedAt = stored.updatedAt;
  }

  static void _applyDeviceFields(CalendarEvent target, CalendarEvent fresh) {
    target
      ..title = fresh.title
      ..start = fresh.start
      ..end = fresh.end
      ..calendarId = fresh.calendarId
      ..colorValue = fresh.colorValue
      ..source = EventSource.device;
  }

  static void _appendRecurringStoredOccurrences({
    required List<CalendarEvent> visible,
    required DateTime selectedDay,
    required List<CalendarEvent> allStored,
    required List<CalendarEvent> deviceEventsForDay,
  }) {
    for (final CalendarEvent stored in allStored) {
      if (!_hasRecurrence(stored)) {
        continue;
      }
      if (!RecurrenceEvaluator.shouldShowEventOnDate(stored, selectedDay)) {
        continue;
      }
      if (_deviceCoversCalendarDay(
        stored: stored,
        deviceEvents: deviceEventsForDay,
        day: selectedDay,
      )) {
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
    required List<CalendarEvent> deviceEventsInRange,
  }) {
    for (DateTime day = rangeDayStart;
        day.isBefore(rangeDayEndExclusive);
        day = day.add(const Duration(days: 1))) {
      _appendRecurringStoredOccurrences(
        visible: visible,
        selectedDay: day,
        allStored: allStored,
        deviceEventsForDay: deviceEventsInRange,
      );
    }
  }

  static bool _hasRecurrence(CalendarEvent event) {
    final String? json = event.recurrenceRuleJson;
    return json != null && json.trim().isNotEmpty;
  }

  static bool _deviceCoversCalendarDay({
    required CalendarEvent stored,
    required List<CalendarEvent> deviceEvents,
    required DateTime day,
  }) {
    for (final CalendarEvent device in deviceEvents) {
      if (device.deviceEventId != stored.deviceEventId) {
        continue;
      }
      if (_overlapsCalendarDay(device, day)) {
        return true;
      }
    }
    return false;
  }

  static bool _visibleCoversCalendarDay(
    List<CalendarEvent> visible,
    CalendarEvent stored,
    DateTime day,
  ) {
    for (final CalendarEvent event in visible) {
      if (event.deviceEventId != stored.deviceEventId) {
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
    )..id = master.id
      ..reminderMinutesBefore = master.reminderMinutesBefore
      ..recurrenceRuleJson = master.recurrenceRuleJson
      ..updatedAt = master.updatedAt;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/calendar_integration/domain/device_calendar_stale_purge.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_source.dart';

void main() {
  group('DeviceCalendarStalePurge', () {
    final DateTime dayStart = DateTime(2026, 6, 3);
    final DateTime dayEnd = dayStart.add(const Duration(days: 1));
    const Set<String> calendars = <String>{'cal-1'};

    test('removes device row on day missing from fetch', () {
      final CalendarEvent stale = CalendarEvent()
        ..deviceEventId = 'old-dev'
        ..calendarId = 'cal-1'
        ..title = 'Moved away'
        ..start = DateTime(2026, 6, 3, 10)
        ..end = DateTime(2026, 6, 3, 11)
        ..source = EventSource.device;

      final List<CalendarEvent> remove = DeviceCalendarStalePurge.rowsToRemove(
        allStored: <CalendarEvent>[stale],
        fetchedInWindow: const <CalendarEvent>[],
        windowStart: dayStart,
        windowEndExclusive: dayEnd,
        syncedCalendarIds: calendars,
      );

      expect(remove, <CalendarEvent>[stale]);
    });

    test('keeps device row returned in fetch', () {
      final CalendarEvent fresh = CalendarEvent()
        ..deviceEventId = 'dev-1'
        ..calendarId = 'cal-1'
        ..title = 'Mega Event'
        ..start = DateTime(2026, 6, 3, 19)
        ..end = DateTime(2026, 6, 3, 20)
        ..source = EventSource.device;

      final List<CalendarEvent> remove = DeviceCalendarStalePurge.rowsToRemove(
        allStored: <CalendarEvent>[fresh],
        fetchedInWindow: <CalendarEvent>[fresh],
        windowStart: dayStart,
        windowEndExclusive: dayEnd,
        syncedCalendarIds: calendars,
      );

      expect(remove, isEmpty);
    });

    test('never removes local-only rows', () {
      final CalendarEvent local = CalendarEvent()
        ..deviceEventId = 'local_1'
        ..calendarId = 'cal-1'
        ..title = 'App block'
        ..start = DateTime(2026, 6, 3, 12)
        ..end = DateTime(2026, 6, 3, 13)
        ..source = EventSource.local;

      final List<CalendarEvent> remove = DeviceCalendarStalePurge.rowsToRemove(
        allStored: <CalendarEvent>[local],
        fetchedInWindow: const <CalendarEvent>[],
        windowStart: dayStart,
        windowEndExclusive: dayEnd,
        syncedCalendarIds: calendars,
      );

      expect(remove, isEmpty);
    });

    test('skips recurring device rows', () {
      final CalendarEvent recurring = CalendarEvent()
        ..deviceEventId = 'rec-1'
        ..calendarId = 'cal-1'
        ..title = 'Weekly'
        ..start = DateTime(2026, 6, 3, 9)
        ..end = DateTime(2026, 6, 3, 10)
        ..source = EventSource.device
        ..recurrenceRuleJson = '{"frequency":"weekly"}';

      final List<CalendarEvent> remove = DeviceCalendarStalePurge.rowsToRemove(
        allStored: <CalendarEvent>[recurring],
        fetchedInWindow: const <CalendarEvent>[],
        windowStart: dayStart,
        windowEndExclusive: dayEnd,
        syncedCalendarIds: calendars,
      );

      expect(remove, isEmpty);
    });

    test('ignores rows outside sync window', () {
      final CalendarEvent otherDay = CalendarEvent()
        ..deviceEventId = 'other'
        ..calendarId = 'cal-1'
        ..title = 'Tomorrow'
        ..start = DateTime(2026, 6, 4, 10)
        ..end = DateTime(2026, 6, 4, 11)
        ..source = EventSource.device;

      final List<CalendarEvent> remove = DeviceCalendarStalePurge.rowsToRemove(
        allStored: <CalendarEvent>[otherDay],
        fetchedInWindow: const <CalendarEvent>[],
        windowStart: dayStart,
        windowEndExclusive: dayEnd,
        syncedCalendarIds: calendars,
      );

      expect(remove, isEmpty);
    });
  });
}

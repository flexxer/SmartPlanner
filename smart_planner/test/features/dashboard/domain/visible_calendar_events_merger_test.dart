import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_source.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_frequency.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';
import 'package:smart_planner/features/dashboard/domain/visible_calendar_events_merger.dart';

void main() {
  group('VisibleCalendarEventsMerger', () {
    test('uses fresh device times over stale Isar row', () {
      final DateTime day = DateTime(2026, 6, 2);
      final CalendarEvent stored = CalendarEvent()
        ..deviceEventId = 'dev-1'
        ..calendarId = 'cal-1'
        ..title = 'Old title'
        ..start = DateTime(2026, 6, 2, 9)
        ..end = DateTime(2026, 6, 2, 10)
        ..source = EventSource.device;

      final CalendarEvent fresh = CalendarEvent()
        ..deviceEventId = 'dev-1'
        ..calendarId = 'cal-1'
        ..title = 'New title'
        ..start = DateTime(2026, 6, 2, 14)
        ..end = DateTime(2026, 6, 2, 15)
        ..source = EventSource.device;

      final List<CalendarEvent> visible = VisibleCalendarEventsMerger.merge(
        selectedDay: day,
        deviceEventsForDay: <CalendarEvent>[fresh],
        allStored: <CalendarEvent>[stored],
      );

      expect(visible, hasLength(1));
      expect(visible.single.title, 'New title');
      expect(visible.single.start, DateTime(2026, 6, 2, 14));
      expect(stored.title, 'New title');
      expect(stored.start, DateTime(2026, 6, 2, 14));
    });

    test('omits device row not returned for day', () {
      final DateTime day = DateTime(2026, 6, 2);
      final CalendarEvent staleOnIsar = CalendarEvent()
        ..deviceEventId = 'dev-moved'
        ..title = 'Moved away'
        ..start = DateTime(2026, 6, 2, 9)
        ..end = DateTime(2026, 6, 2, 10)
        ..source = EventSource.device;

      final List<CalendarEvent> visible = VisibleCalendarEventsMerger.merge(
        selectedDay: day,
        deviceEventsForDay: const <CalendarEvent>[],
        allStored: <CalendarEvent>[staleOnIsar],
      );

      expect(visible, isEmpty);
    });

    test('includes local-only events for selected day', () {
      final DateTime day = DateTime(2026, 6, 2);
      final CalendarEvent local = CalendarEvent()
        ..deviceEventId = 'local_abc'
        ..title = 'App task block'
        ..start = DateTime(2026, 6, 2, 11)
        ..end = DateTime(2026, 6, 2, 12)
        ..source = EventSource.local;

      final List<CalendarEvent> visible = VisibleCalendarEventsMerger.merge(
        selectedDay: day,
        deviceEventsForDay: const <CalendarEvent>[],
        allStored: <CalendarEvent>[local],
      );

      expect(visible, hasLength(1));
      expect(visible.single.title, 'App task block');
    });

    test('hides local duplicate when device row exists for same title/day', () {
      final DateTime day = DateTime(2026, 6, 3);
      final CalendarEvent local = CalendarEvent()
        ..deviceEventId = 'local_old'
        ..calendarId = 'cal-1'
        ..title = 'Mega Event'
        ..start = DateTime(2026, 6, 3, 19)
        ..end = DateTime(2026, 6, 3, 20)
        ..source = EventSource.local;
      final CalendarEvent device = CalendarEvent()
        ..deviceEventId = 'dev-new'
        ..calendarId = 'cal-1'
        ..title = 'Mega Event'
        ..start = DateTime(2026, 6, 3, 19)
        ..end = DateTime(2026, 6, 3, 20)
        ..source = EventSource.device;

      final List<CalendarEvent> visible = VisibleCalendarEventsMerger.merge(
        selectedDay: day,
        deviceEventsForDay: <CalendarEvent>[device],
        allStored: <CalendarEvent>[local, device],
      );

      expect(visible, hasLength(1));
      expect(visible.single.deviceEventId, 'dev-new');
    });

    test('expands recurring stored event onto another day', () {
      final DateTime monday = DateTime(2026, 6, 1);
      final DateTime tuesday = monday.add(const Duration(days: 1));
      final CalendarEvent series = CalendarEvent.fromDevice(
        deviceEventId: 'rec-1',
        title: 'Daily standup',
        start: DateTime(2026, 6, 1, 9),
        end: DateTime(2026, 6, 1, 9, 30),
        calendarId: 'cal-1',
        colorValue: 0xFF5C6BC0,
        recurrenceRule: const RecurrenceRule(
          frequency: RecurrenceFrequency.daily,
        ),
      )..id = 42;

      final List<CalendarEvent> visible = VisibleCalendarEventsMerger.merge(
        selectedDay: tuesday,
        deviceEventsForDay: const <CalendarEvent>[],
        allStored: <CalendarEvent>[series],
      );

      expect(visible, hasLength(1));
      expect(visible.single.start, DateTime(2026, 6, 2, 9));
      expect(
        AppDateUtils.isSameCalendarDay(visible.single.start, tuesday),
        isTrue,
      );
    });
  });
}

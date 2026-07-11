import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_source.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_frequency.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';
import 'package:smart_planner/features/dashboard/domain/visible_calendar_events_merger.dart';

void main() {
  group('VisibleCalendarEventsMerger', () {
    test('includes stored events for selected day from Isar', () {
      final DateTime day = DateTime(2026, 6, 2);
      final CalendarEvent stored = CalendarEvent()
        ..id = 1
        ..deviceEventId = 'dev-1'
        ..calendarId = 'cal-1'
        ..title = 'Meeting'
        ..start = DateTime(2026, 6, 2, 14)
        ..end = DateTime(2026, 6, 2, 15)
        ..source = EventSource.device;

      final List<CalendarEvent> visible =
          VisibleCalendarEventsMerger.fromStored(
        selectedDay: day,
        allStored: <CalendarEvent>[stored],
      );

      expect(visible, hasLength(1));
      expect(visible.single.title, 'Meeting');
    });

    test('includes local-only events for selected day', () {
      final DateTime day = DateTime(2026, 6, 2);
      final CalendarEvent local = CalendarEvent()
        ..deviceEventId = 'local_abc'
        ..title = 'App task block'
        ..start = DateTime(2026, 6, 2, 11)
        ..end = DateTime(2026, 6, 2, 12)
        ..source = EventSource.local;

      final List<CalendarEvent> visible =
          VisibleCalendarEventsMerger.fromStored(
        selectedDay: day,
        allStored: <CalendarEvent>[local],
      );

      expect(visible, hasLength(1));
      expect(visible.single.title, 'App task block');
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

      final List<CalendarEvent> visible =
          VisibleCalendarEventsMerger.fromStored(
        selectedDay: tuesday,
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

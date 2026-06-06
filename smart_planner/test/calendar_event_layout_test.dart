import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_occurrence.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_overlap_layout.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_time_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_grid_layout.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';

void main() {
  group('CalendarEventTimeUtils', () {
    test('detects device all-day events', () {
      final DateTime day = DateTime(2026, 6, 6);
      final CalendarEvent event = _event(
        start: day,
        end: day.add(const Duration(days: 1)),
      );
      expect(CalendarEventTimeUtils.isAllDay(event), isTrue);
    });

    test('detects all-day end at 23:59', () {
      final DateTime day = DateTime(2026, 6, 6);
      final CalendarEvent event = _event(
        start: day,
        end: DateTime(2026, 6, 6, 23, 59),
      );
      expect(CalendarEventTimeUtils.isAllDay(event), isTrue);
    });

    test('normalizeAllDayRange uses exclusive end midnight', () {
      final DateTime day = DateTime(2026, 6, 6);
      final ({DateTime start, DateTime end}) range =
          CalendarEventTimeUtils.normalizeAllDayRange(
        startDay: day,
        endDayInclusive: day.add(const Duration(days: 2)),
      );
      expect(range.start, day);
      expect(range.end, day.add(const Duration(days: 3)));
    });

    test('forGrid handles narrow week columns without throwing', () {
      final ({double left, double width, double backgroundOpacity}) geo =
          StackedOverlapGeometry.forGrid(
        columnMaxWidth: 40,
        columnIndex: 1,
        columnCount: 3,
      );
      expect(geo.width, greaterThan(0));
      expect(
        geo.left,
        greaterThanOrEqualTo(StackedOverlapGeometry.gridEdgePadding),
      );
    });
  });

  group('CalendarEventOccurrence', () {
    test('clips cross-midnight event on first day', () {
      final DateTime day = DateTime(2026, 6, 6);
      final CalendarEvent event = _event(
        start: day.add(const Duration(hours: 23)),
        end: DateTime(2026, 6, 7, 1),
      );

      final bounds = CalendarEventOccurrence.timedBoundsOnDay(event, day)!;
      expect(bounds.start.hour, 23);
      expect(bounds.end.day, 7);
      expect(bounds.end.hour, 0);
      expect(bounds.continuesToNextDay, isTrue);
      expect(bounds.continuesFromPreviousDay, isFalse);
    });

    test('clips cross-midnight event on second day', () {
      final DateTime day = DateTime(2026, 6, 7);
      final CalendarEvent event = _event(
        start: DateTime(2026, 6, 6, 23),
        end: day.add(const Duration(hours: 1)),
      );

      final bounds = CalendarEventOccurrence.timedBoundsOnDay(event, day)!;
      expect(bounds.start.hour, 0);
      expect(bounds.end.hour, 1);
      expect(bounds.continuesFromPreviousDay, isTrue);
      expect(bounds.continuesToNextDay, isFalse);
    });

    test('returns all-day events separately', () {
      final DateTime day = DateTime(2026, 6, 6);
      final CalendarEvent allDay = _event(
        title: 'Holiday',
        start: day,
        end: day.add(const Duration(days: 1)),
      );
      final CalendarEvent timed = _event(
        title: 'Meet',
        start: day.add(const Duration(hours: 10)),
        end: day.add(const Duration(hours: 11)),
      );

      expect(
        CalendarEventOccurrence.timedBoundsOnDay(allDay, day),
        isNull,
      );
      expect(
        CalendarEventOccurrence.allDayEventsOnDay(
          <CalendarEvent>[allDay, timed],
          day,
        ),
        hasLength(1),
      );
    });
  });

  group('CalendarEventOverlapLayout', () {
    test('places overlapping events in separate columns', () {
      final DateTime day = DateTime(2026, 6, 6);
      final CalendarEvent a = _event(
        title: 'A',
        start: day.add(const Duration(hours: 10)),
        end: day.add(const Duration(hours: 11)),
      );
      final CalendarEvent b = _event(
        title: 'B',
        start: day.add(const Duration(hours: 10, minutes: 30)),
        end: day.add(const Duration(hours: 11, minutes: 30)),
      );

      final List<PlacedTimedEvent> placed =
          CalendarEventOverlapLayout.layoutDay(
        events: <CalendarEvent>[a, b],
        day: day,
      );

      expect(placed, hasLength(2));
      expect(placed[0].columnCount, 2);
      expect(placed[1].columnCount, 2);
      expect(placed[0].columnIndex, isNot(equals(placed[1].columnIndex)));
    });
  });

  group('CalendarGridLayout slot snapping', () {
    test('snapSlotStart aligns to hour boundary', () {
      final DateTime day = DateTime(2026, 5, 25);
      final DateTime start = CalendarGridLayout.snapSlotStart(
        day: day,
        localY: CalendarGridLayout.defaultHourHeight * 16.6,
        hourHeight: CalendarGridLayout.defaultHourHeight,
      );
      expect(start.hour, 16);
      expect(start.minute, 0);
    });

    test('snapSelectionEnd rounds to 15 minutes', () {
      final DateTime day = DateTime(2026, 5, 25);
      final DateTime start = DateTime(2026, 5, 25, 16);
      final DateTime end = CalendarGridLayout.snapSelectionEnd(
        day: day,
        start: start,
        localY: CalendarGridLayout.defaultHourHeight * 16.75,
        hourHeight: CalendarGridLayout.defaultHourHeight,
      );
      expect(end.difference(start).inMinutes, 45);
    });
  });
}

CalendarEvent _event({
  String title = 'Test',
  required DateTime start,
  required DateTime end,
}) {
  return CalendarEvent.fromDevice(
    deviceEventId: 'test_${start.millisecondsSinceEpoch}',
    title: title,
    start: start,
    end: end,
    calendarId: 'cal',
    colorValue: 0xFF5C6BC0,
  );
}

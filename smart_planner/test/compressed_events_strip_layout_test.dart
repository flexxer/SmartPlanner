import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/dashboard/domain/compressed_events_strip_layout.dart';

void main() {
  test('collapses long gap between events into a compact marker', () {
    final DateTime day = DateTime(2026, 5, 23);
    final CalendarEvent morning = _event(
      title: 'Morning',
      start: day.add(const Duration(hours: 10)),
      end: day.add(const Duration(hours: 11)),
    );
    final CalendarEvent evening = _event(
      title: 'Evening',
      start: day.add(const Duration(hours: 18)),
      end: day.add(const Duration(hours: 19)),
    );

    final CompressedEventsStripLayout layout =
        CompressedEventsStripLayout.build(
      events: <CalendarEvent>[morning, evening],
      selectedDate: day,
      now: day.add(const Duration(hours: 14)),
      isToday: true,
    );

    expect(layout.segments.length, 3);
    expect(layout.segments[0], isA<CompressedEventSegment>());
    expect(layout.segments[1], isA<CompressedGapSegment>());
    expect(layout.segments[2], isA<CompressedEventSegment>());

  final CompressedGapSegment gap = layout.segments[1] as CompressedGapSegment;
    expect(gap.width, CompressedEventsStripLayout.gapMarkerWidth);
    expect(CompressedEventsStripLayout.gapLabel(gap.duration), '7 ч');

    // Cards are adjacent with only the narrow gap marker between them.
    expect(
      layout.totalWidth,
      CompressedEventsStripLayout.cardWidth * 2 +
          CompressedEventsStripLayout.gapMarkerWidth,
    );

    expect(layout.nowIndicatorLeft, isNotNull);
    expect(layout.focusScrollLeft, isNotNull);
  });

  test('hides now indicator before the first event starts', () {
    final DateTime day = DateTime(2026, 5, 23);
    final CalendarEvent evening = _event(
      title: 'Evening',
      start: day.add(const Duration(hours: 18)),
      end: day.add(const Duration(hours: 19)),
    );

    final CompressedEventsStripLayout layout =
        CompressedEventsStripLayout.build(
      events: <CalendarEvent>[evening],
      selectedDate: day,
      now: day.add(const Duration(hours: 12)),
      isToday: true,
    );

    expect(layout.nowIndicatorLeft, isNull);
  });

  test('keeps short gaps as a small fixed spacing only', () {
    final DateTime day = DateTime(2026, 5, 23);
    final CalendarEvent first = _event(
      title: 'First',
      start: day.add(const Duration(hours: 10)),
      end: day.add(const Duration(hours: 10, minutes: 30)),
    );
    final CalendarEvent second = _event(
      title: 'Second',
      start: day.add(const Duration(hours: 11)),
      end: day.add(const Duration(hours: 12)),
    );

    final CompressedEventsStripLayout layout =
        CompressedEventsStripLayout.build(
      events: <CalendarEvent>[first, second],
      selectedDate: day,
      now: day.add(const Duration(hours: 9)),
      isToday: false,
    );

    expect(layout.segments.whereType<CompressedGapSegment>(), isEmpty);
    expect(
      layout.totalWidth,
      CompressedEventsStripLayout.cardWidth * 2 +
          CompressedEventsStripLayout.cardGap,
    );
  });
}

CalendarEvent _event({
  required String title,
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

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_overlap_layout.dart';
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
    final double hourSlot = StackedOverlapGeometry.stripMinSpanWidth;
    expect(
      layout.totalWidth,
      hourSlot * 2 + CompressedEventsStripLayout.gapMarkerWidth,
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
    final double hourSlot = StackedOverlapGeometry.stripMinSpanWidth;
    expect(
      layout.totalWidth,
      hourSlot * 2 + CompressedEventsStripLayout.cardGap,
    );
  });

  test('overlapping events use separate rows with later events shifted right', () {
    final DateTime day = DateTime(2026, 5, 23);
    final CalendarEvent first = _event(
      title: 'First',
      start: day.add(const Duration(hours: 10)),
      end: day.add(const Duration(hours: 11)),
    );
    final CalendarEvent second = _event(
      title: 'Second',
      start: day.add(const Duration(hours: 10, minutes: 30)),
      end: day.add(const Duration(hours: 11, minutes: 30)),
    );

    final CompressedEventsStripLayout layout =
        CompressedEventsStripLayout.build(
      events: <CalendarEvent>[first, second],
      selectedDate: day,
      now: day.add(const Duration(hours: 9)),
      isToday: false,
    );

    final List<CompressedEventSegment> cards =
        layout.segments.whereType<CompressedEventSegment>().toList();
    expect(cards, hasLength(2));
    expect(cards[0].left, cards[1].left);
    expect(cards[0].layerCount, 2);
    expect(cards[0].layerIndex, 0);
    expect(cards[1].layerIndex, 1);
    expect(cards[0].event.start.isBefore(cards[1].event.start), isTrue);
    expect(
      StackedOverlapGeometry.forStrip(layerIndex: 0, layerCount: 2).left,
      0,
    );
    expect(
      StackedOverlapGeometry.forStrip(layerIndex: 1, layerCount: 2).left,
      StackedOverlapGeometry.stripLayerOffsetX,
    );
    expect(
      StackedOverlapGeometry.forStrip(layerIndex: 1, layerCount: 2).top,
      StackedOverlapGeometry.stripRowStep(2),
    );
    expect(
      StackedOverlapGeometry.forStrip(layerIndex: 1, layerCount: 2).height,
      StackedOverlapGeometry.stripCardHeight(2),
    );
    const Duration clusterDuration = Duration(hours: 1, minutes: 30);
    final double slotWidth = StackedOverlapGeometry.stripSlotWidth(
      clusterDuration: clusterDuration,
      columnCount: 2,
    );
    expect(layout.totalWidth, slotWidth);
    // 90 min × (50 px/h) + right-shift for the second overlap row.
    expect(slotWidth, 99);
    expect(StackedOverlapGeometry.stripSlotHeight(2), 132);
    expect(StackedOverlapGeometry.stripCardHeight(2), 64);
  });

  test('non-overlapping sequential events share the same row', () {
    final DateTime day = DateTime(2026, 6, 6);
    final CalendarEvent blade = _event(
      title: 'Blade',
      start: day.add(const Duration(hours: 20)),
      end: day.add(const Duration(hours: 22)),
    );
    final CalendarEvent overlay = _event(
      title: 'Overlay',
      start: day.add(const Duration(hours: 21, minutes: 30)),
      end: day.add(const Duration(hours: 23, minutes: 55)),
    );
    final CalendarEvent overlay2 = _event(
      title: 'Overlay 2',
      start: day.add(const Duration(hours: 22)),
      end: day.add(const Duration(hours: 23)),
    );

    final CompressedEventsStripLayout layout =
        CompressedEventsStripLayout.build(
      events: <CalendarEvent>[blade, overlay, overlay2],
      selectedDate: day,
      now: day.add(const Duration(hours: 12)),
      isToday: false,
    );

    final List<CompressedEventSegment> cards =
        layout.segments.whereType<CompressedEventSegment>().toList();
    expect(cards, hasLength(3));

    final CompressedEventSegment bladeCard =
        cards.firstWhere((CompressedEventSegment c) => c.event.title == 'Blade');
    final CompressedEventSegment overlayCard =
        cards.firstWhere((CompressedEventSegment c) => c.event.title == 'Overlay');
    final CompressedEventSegment overlay2Card =
        cards.firstWhere((CompressedEventSegment c) => c.event.title == 'Overlay 2');

    expect(bladeCard.layerIndex, 0);
    expect(overlay2Card.layerIndex, 0);
    expect(overlayCard.layerIndex, 1);
    expect(bladeCard.layerIndex, overlay2Card.layerIndex);
    expect(overlay2Card.offsetInGroup, greaterThan(bladeCard.offsetInGroup));
  });

  test('longer events render wider than shorter ones in the same cluster', () {
    final DateTime day = DateTime(2026, 6, 6);
    final CalendarEvent longer = _event(
      title: 'Longer',
      start: day.add(const Duration(hours: 21, minutes: 30)),
      end: day.add(const Duration(hours: 23, minutes: 55)),
    );
    final CalendarEvent shorter = _event(
      title: 'Shorter',
      start: day.add(const Duration(hours: 22)),
      end: day.add(const Duration(hours: 23)),
    );

    final CompressedEventsStripLayout layout =
        CompressedEventsStripLayout.build(
      events: <CalendarEvent>[longer, shorter],
      selectedDate: day,
      now: day.add(const Duration(hours: 12)),
      isToday: false,
    );

    final List<CompressedEventSegment> cards =
        layout.segments.whereType<CompressedEventSegment>().toList();
    final CompressedEventSegment longerCard =
        cards.firstWhere((CompressedEventSegment c) => c.event.title == 'Longer');
    final CompressedEventSegment shorterCard =
        cards.firstWhere((CompressedEventSegment c) => c.event.title == 'Shorter');

    expect(longerCard.width, greaterThan(shorterCard.width));
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

import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/dashboard/domain/event_time_status.dart';

/// One visual block in the compressed horizontal events strip.
sealed class CompressedStripSegment {
  const CompressedStripSegment({
    required this.left,
    required this.width,
  });

  final double left;
  final double width;
}

/// Event card at [left] with fixed [width].
final class CompressedEventSegment extends CompressedStripSegment {
  const CompressedEventSegment({
    required this.event,
    required super.left,
    required super.width,
  });

  final CalendarEvent event;
}

/// Collapsed time jump between two events (shows duration label).
final class CompressedGapSegment extends CompressedStripSegment {
  const CompressedGapSegment({
    required this.from,
    required this.to,
    required super.left,
    required super.width,
  });

  final DateTime from;
  final DateTime to;

  Duration get duration => to.difference(from);

  bool contains(DateTime time) =>
      !time.isBefore(from) && time.isBefore(to);
}

/// Builds a compact strip layout: cards stay adjacent, long idle gaps collapse.
class CompressedEventsStripLayout {
  CompressedEventsStripLayout._({
    required this.segments,
    required this.totalWidth,
    this.nowIndicatorLeft,
    this.focusScrollLeft,
  });

  static const double cardWidth = 200;
  static const double cardGap = 10;
  static const double gapMarkerWidth = 56;

  /// Gaps longer than this become a compact duration marker.
  static const int compressThresholdMinutes = 90;

  final List<CompressedStripSegment> segments;
  final double totalWidth;

  /// X position of the live "now" line (today only).
  final double? nowIndicatorLeft;

  /// Preferred horizontal scroll offset for the anchor event / now.
  final double? focusScrollLeft;

  static CompressedEventsStripLayout build({
    required List<CalendarEvent> events,
    required DateTime selectedDate,
    required DateTime now,
    required bool isToday,
  }) {
    final List<CalendarEvent> sorted = List<CalendarEvent>.from(events)
      ..sort(
        (CalendarEvent a, CalendarEvent b) => a.start.compareTo(b.start),
      );

    if (sorted.isEmpty) {
      return CompressedEventsStripLayout._(
        segments: const <CompressedStripSegment>[],
        totalWidth: 0,
      );
    }

    final List<CompressedStripSegment> segments = <CompressedStripSegment>[];
    double x = 0;

    for (int i = 0; i < sorted.length; i++) {
      final CalendarEvent event = sorted[i];

      if (i > 0) {
        final CalendarEvent previous = sorted[i - 1];
        final DateTime gapStart =
            previous.end.isAfter(previous.start) ? previous.end : previous.start;
        x += _appendGapIfNeeded(
          segments: segments,
          x: x,
          gapStart: gapStart,
          gapEnd: event.start,
        );
      }

      segments.add(
        CompressedEventSegment(
          event: event,
          left: x,
          width: cardWidth,
        ),
      );
      x += cardWidth;
    }

    double? nowLeft;
    double? focusLeft;

    if (isToday) {
      nowLeft = _resolveNowLeft(
        segments: segments,
        sortedEvents: sorted,
        now: now,
      );
      focusLeft = _resolveFocusLeft(
        segments: segments,
        sortedEvents: sorted,
        selectedDate: selectedDate,
        now: now,
        nowLeft: nowLeft,
      );
    } else {
      focusLeft = segments.first.left;
    }

    return CompressedEventsStripLayout._(
      segments: segments,
      totalWidth: x,
      nowIndicatorLeft: nowLeft,
      focusScrollLeft: focusLeft,
    );
  }

  static double _appendGapIfNeeded({
    required List<CompressedStripSegment> segments,
    required double x,
    required DateTime gapStart,
    required DateTime gapEnd,
  }) {
    if (!gapEnd.isAfter(gapStart)) {
      return cardGap;
    }

    final int gapMinutes = gapEnd.difference(gapStart).inMinutes;
    if (gapMinutes <= compressThresholdMinutes) {
      return cardGap;
    }

    segments.add(
      CompressedGapSegment(
        from: gapStart,
        to: gapEnd,
        left: x,
        width: gapMarkerWidth,
      ),
    );
    return gapMarkerWidth;
  }

  static double? _resolveNowLeft({
    required List<CompressedStripSegment> segments,
    required List<CalendarEvent> sortedEvents,
    required DateTime now,
  }) {
    for (final CompressedStripSegment segment in segments) {
      switch (segment) {
        case CompressedGapSegment(:final from, :final to, :final left, :final width):
          if (!now.isBefore(from) && now.isBefore(to)) {
            return left + width / 2;
          }
        case CompressedEventSegment(:final event, :final left, :final width):
          if (!now.isBefore(event.start) && !now.isAfter(event.end)) {
            return left + width / 2;
          }
      }
    }

    final CalendarEvent first = sortedEvents.first;
    final CalendarEvent last = sortedEvents.last;
    if (now.isBefore(first.start)) {
      return null;
    }
    if (now.isAfter(last.end)) {
      final CompressedEventSegment? lastSegment = segments
          .whereType<CompressedEventSegment>()
          .lastOrNull;
      if (lastSegment != null) {
        return lastSegment.left + cardWidth;
      }
    }

    return null;
  }

  static double? _resolveFocusLeft({
    required List<CompressedStripSegment> segments,
    required List<CalendarEvent> sortedEvents,
    required DateTime selectedDate,
    required DateTime now,
    required double? nowLeft,
  }) {
    for (final CalendarEvent event in sortedEvents) {
      final EventTimeStatus status = EventTimeStatusResolver.resolve(
        event: event,
        selectedDay: selectedDate,
        now: now,
      );
      if (status == EventTimeStatus.current ||
          status == EventTimeStatus.future) {
        for (final CompressedStripSegment segment in segments) {
          if (segment is CompressedEventSegment &&
              segment.event.id == event.id) {
            return segment.left;
          }
        }
      }
    }

    return nowLeft;
  }

  /// Human-readable gap label, e.g. "8 ч", "45 мин".
  static String gapLabel(Duration gap) {
    final int totalMinutes = gap.inMinutes;
    if (totalMinutes < 60) {
      return '$totalMinutes мин';
    }

    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '$hours ч';
    }
    return '$hours ч $minutes мин';
  }
}

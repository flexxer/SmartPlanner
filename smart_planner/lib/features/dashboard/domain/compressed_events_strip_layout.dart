import 'dart:math' as math;

import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_occurrence.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_overlap_layout.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_time_utils.dart';
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

/// Event card at [left] with time-scaled [width] inside its overlap group.
final class CompressedEventSegment extends CompressedStripSegment {
  const CompressedEventSegment({
    required this.event,
    required super.left,
    required super.width,
    this.offsetInGroup = 0,
    this.columnIndex = 0,
    this.columnCount = 1,
    this.layerIndex = 0,
    this.layerCount = 1,
  });

  final CalendarEvent event;
  /// Horizontal offset within the group slot (time-proportional).
  final double offsetInGroup;
  final int columnIndex;
  final int columnCount;
  /// Overlap row index — non-overlapping events share the same row.
  final int layerIndex;
  final int layerCount;

  double get cardLeft => left + offsetInGroup;
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

  static const double cardGap = 10;
  static const double gapMarkerWidth = 56;
  static const double stripMinEventWidth = 56;

  /// Gaps longer than this become a compact duration marker.
  static const int compressThresholdMinutes = 90;

  final List<CompressedStripSegment> segments;
  final double totalWidth;

  /// X position of the live "now" line (today only).
  final double? nowIndicatorLeft;

  /// Preferred horizontal scroll offset for the anchor event / now.
  final double? focusScrollLeft;

  static List<CalendarEvent> timedEventsForDay(
    List<CalendarEvent> events,
    DateTime selectedDate,
  ) {
    return events
        .where(
          (CalendarEvent event) =>
              !CalendarEventTimeUtils.isAllDay(event) &&
              CalendarEventTimeUtils.overlapsCalendarDay(event, selectedDate),
        )
        .toList();
  }

  static CompressedEventsStripLayout build({
    required List<CalendarEvent> events,
    required DateTime selectedDate,
    required DateTime now,
    required bool isToday,
  }) {
    final List<CalendarEvent> sorted =
        List<CalendarEvent>.from(timedEventsForDay(events, selectedDate))
          ..sort(
            (CalendarEvent a, CalendarEvent b) => a.start.compareTo(b.start),
          );

    if (sorted.isEmpty) {
      return CompressedEventsStripLayout._(
        segments: const <CompressedStripSegment>[],
        totalWidth: 0,
      );
    }

    final List<_OverlapGroup> groups =
        _buildOverlapGroups(sorted, selectedDate);
    final List<CompressedStripSegment> segments = <CompressedStripSegment>[];
    double x = 0;

    for (int i = 0; i < groups.length; i++) {
      final _OverlapGroup group = groups[i];
      if (i > 0) {
        final _OverlapGroup previous = groups[i - 1];
        x += _appendGapIfNeeded(
          segments: segments,
          x: x,
          gapStart: previous.clusterEnd,
          gapEnd: group.clusterStart,
        );
      }

      final Duration clusterDuration =
          group.clusterEnd.difference(group.clusterStart);
      final double timeSpanWidth = _timeSpanWidth(clusterDuration);
      for (final _GroupedEvent grouped in group.events) {
        final CalendarEventDayBounds bounds = grouped.bounds;
        segments.add(
          CompressedEventSegment(
            event: grouped.event,
            left: x,
            width: _eventWidth(
              start: bounds.start,
              end: bounds.end,
              clusterDuration: clusterDuration,
              timeSpanWidth: timeSpanWidth,
            ),
            offsetInGroup: _eventOffset(
              start: bounds.start,
              clusterStart: group.clusterStart,
              clusterDuration: clusterDuration,
              timeSpanWidth: timeSpanWidth,
            ),
            columnIndex: grouped.columnIndex,
            columnCount: group.columnCount,
            layerIndex: grouped.columnIndex,
            layerCount: group.columnCount,
          ),
        );
      }
      x += StackedOverlapGeometry.stripSlotWidth(
        clusterDuration: clusterDuration,
        columnCount: group.columnCount,
      );
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

  static List<_OverlapGroup> _buildOverlapGroups(
    List<CalendarEvent> sorted,
    DateTime day,
  ) {
    final List<_OverlapGroup> groups = <_OverlapGroup>[];
    List<CalendarEvent>? currentEvents;

    for (final CalendarEvent event in sorted) {
      if (currentEvents == null) {
        currentEvents = <CalendarEvent>[event];
        continue;
      }

      final DateTime clusterEnd = currentEvents
          .map(
            (CalendarEvent e) =>
                CalendarEventOccurrence.timedBoundsOnDay(e, day)!.end,
          )
          .reduce((DateTime a, DateTime b) => a.isAfter(b) ? a : b);

      final DateTime eventStart =
          CalendarEventOccurrence.timedBoundsOnDay(event, day)!.start;

      if (eventStart.isBefore(clusterEnd)) {
        currentEvents.add(event);
      } else {
        groups.add(_OverlapGroup.fromEvents(currentEvents, day));
        currentEvents = <CalendarEvent>[event];
      }
    }

    if (currentEvents != null) {
      groups.add(_OverlapGroup.fromEvents(currentEvents, day));
    }
    return groups;
  }

  static double _timeSpanWidth(Duration clusterDuration) {
    return math.max(
      StackedOverlapGeometry.stripMinSpanWidth,
      clusterDuration.inMinutes * StackedOverlapGeometry.stripPixelsPerMinute,
    );
  }

  static double _eventOffset({
    required DateTime start,
    required DateTime clusterStart,
    required Duration clusterDuration,
    required double timeSpanWidth,
  }) {
    final int clusterMinutes = clusterDuration.inMinutes;
    if (clusterMinutes <= 0) {
      return 0;
    }
    final Duration offset =
        start.isBefore(clusterStart) ? Duration.zero : start.difference(clusterStart);
    return offset.inMinutes / clusterMinutes * timeSpanWidth;
  }

  static double _eventWidth({
    required DateTime start,
    required DateTime end,
    required Duration clusterDuration,
    required double timeSpanWidth,
  }) {
    final int clusterMinutes = clusterDuration.inMinutes;
    if (clusterMinutes <= 0) {
      return stripMinEventWidth;
    }
    final double proportional =
        end.difference(start).inMinutes / clusterMinutes * timeSpanWidth;
    return math.max(stripMinEventWidth, proportional);
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
        case CompressedEventSegment(
          :final event,
          :final left,
          :final width,
          :final offsetInGroup,
        ):
          if (!now.isBefore(event.start) && !now.isAfter(event.end)) {
            return left + offsetInGroup + width / 2;
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
        return lastSegment.left + lastSegment.offsetInGroup + lastSegment.width;
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
            return segment.left + segment.offsetInGroup;
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

final class _OverlapGroup {
  _OverlapGroup({
    required this.events,
    required this.clusterStart,
    required this.clusterEnd,
    required this.columnCount,
  });

  factory _OverlapGroup.fromEvents(List<CalendarEvent> events, DateTime day) {
    final Map<CalendarEvent, CalendarEventDayBounds> boundsByEvent =
        <CalendarEvent, CalendarEventDayBounds>{
      for (final CalendarEvent event in events)
        event: CalendarEventOccurrence.timedBoundsOnDay(event, day)!,
    };

    events.sort(
      (CalendarEvent a, CalendarEvent b) =>
          boundsByEvent[a]!.start.compareTo(boundsByEvent[b]!.start),
    );

    final List<List<CalendarEvent>> columns = <List<CalendarEvent>>[];
    final Map<CalendarEvent, int> columnIndex = <CalendarEvent, int>{};

    for (final CalendarEvent event in events) {
      final CalendarEventDayBounds bounds = boundsByEvent[event]!;
      bool placed = false;
      for (int i = 0; i < columns.length; i++) {
        final CalendarEventDayBounds lastBounds = boundsByEvent[columns[i].last]!;
        if (!lastBounds.end.isAfter(bounds.start)) {
          columns[i].add(event);
          columnIndex[event] = i;
          placed = true;
          break;
        }
      }
      if (!placed) {
        columnIndex[event] = columns.length;
        columns.add(<CalendarEvent>[event]);
      }
    }

    int columnCount = 1;
    for (final CalendarEvent event in events) {
      for (final CalendarEvent other in events) {
        if (boundsByEvent[event]!.overlaps(boundsByEvent[other]!)) {
          columnCount = math.max(columnCount, columnIndex[other]! + 1);
        }
      }
    }

    final DateTime clusterStart = boundsByEvent[events.first]!.start;
    final DateTime clusterEnd = events
        .map((CalendarEvent e) => boundsByEvent[e]!.end)
        .reduce((DateTime a, DateTime b) => a.isAfter(b) ? a : b);

    return _OverlapGroup(
      events: events
          .map(
            (CalendarEvent event) => _GroupedEvent(
              event: event,
              bounds: boundsByEvent[event]!,
              columnIndex: columnIndex[event]!,
            ),
          )
          .toList(),
      clusterStart: clusterStart,
      clusterEnd: clusterEnd,
      columnCount: columnCount,
    );
  }

  final List<_GroupedEvent> events;
  final DateTime clusterStart;
  final DateTime clusterEnd;
  final int columnCount;
}

final class _GroupedEvent {
  const _GroupedEvent({
    required this.event,
    required this.bounds,
    required this.columnIndex,
  });

  final CalendarEvent event;
  final CalendarEventDayBounds bounds;
  final int columnIndex;
}

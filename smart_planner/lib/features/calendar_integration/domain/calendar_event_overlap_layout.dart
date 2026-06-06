import 'dart:math' as math;

import 'package:smart_planner/features/calendar_integration/domain/calendar_event_occurrence.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_time_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';

/// Column layout for overlapping timed events on one day.
final class CalendarEventOverlapLayout {
  CalendarEventOverlapLayout._();

  static List<PlacedTimedEvent> layoutDay({
    required List<CalendarEvent> events,
    required DateTime day,
  }) {
    final List<CalendarEventDayBounds> bounds = <CalendarEventDayBounds>[];
    for (final CalendarEvent event in events) {
      final CalendarEventDayBounds? b =
          CalendarEventOccurrence.timedBoundsOnDay(event, day);
      if (b != null) {
        bounds.add(b);
      }
    }

    if (bounds.isEmpty) {
      return const <PlacedTimedEvent>[];
    }

    bounds.sort(
      (CalendarEventDayBounds a, CalendarEventDayBounds b) {
        final int byStart = a.start.compareTo(b.start);
        if (byStart != 0) {
          return byStart;
        }
        return b.end.compareTo(a.end);
      },
    );

    final List<List<CalendarEventDayBounds>> columns =
        <List<CalendarEventDayBounds>>[];
    final Map<CalendarEventDayBounds, int> columnIndex =
        <CalendarEventDayBounds, int>{};

    for (final CalendarEventDayBounds item in bounds) {
      int? assignedColumn;
      for (int i = 0; i < columns.length; i++) {
        final CalendarEventDayBounds last = columns[i].last;
        if (!last.end.isAfter(item.start)) {
          columns[i].add(item);
          columnIndex[item] = i;
          assignedColumn = i;
          break;
        }
      }
      if (assignedColumn == null) {
        columnIndex[item] = columns.length;
        columns.add(<CalendarEventDayBounds>[item]);
      }
    }

    final List<PlacedTimedEvent> placed = <PlacedTimedEvent>[];
    for (final CalendarEventDayBounds item in bounds) {
      final int index = columnIndex[item]!;
      int columnCount = 1;
      for (final CalendarEventDayBounds other in bounds) {
        if (item.overlaps(other)) {
          columnCount = math.max(columnCount, columnIndex[other]! + 1);
        }
      }
      placed.add(
        PlacedTimedEvent(
          bounds: item,
          columnIndex: index,
          columnCount: columnCount,
        ),
      );
    }

    placed.sort(
      (PlacedTimedEvent a, PlacedTimedEvent b) {
        final int byLayer = a.columnIndex.compareTo(b.columnIndex);
        if (byLayer != 0) {
          return byLayer;
        }
        return a.bounds.start.compareTo(b.bounds.start);
      },
    );
    return placed;
  }
}

/// One timed event block with stacked overlap placement.
final class PlacedTimedEvent {
  const PlacedTimedEvent({
    required this.bounds,
    required this.columnIndex,
    required this.columnCount,
  });

  final CalendarEventDayBounds bounds;
  final int columnIndex;
  final int columnCount;

  CalendarEvent get event => bounds.event;
  DateTime get start => bounds.start;
  DateTime get end => bounds.end;
  bool get continuesFromPreviousDay => bounds.continuesFromPreviousDay;
  bool get continuesToNextDay => bounds.continuesToNextDay;
}

/// Shared stacked-overlap geometry (translucent layers, readable titles).
abstract final class StackedOverlapGeometry {
  StackedOverlapGeometry._();

  static const double gridInsetPerLayer = 10;
  static const double gridEdgePadding = 2;
  static const double minGridBlockWidth = 4;

  static const double stripCardWidth = 200;
  /// Later overlapping events shift right (toward later time / midnight).
  static const double stripLayerOffsetX = 24;
  /// Gap between non-overlapping rows in a multi-event slot.
  static const double stripRowGap = 4;
  static const double stripBaseHeight = 116;
  static const double stripMinCardHeight = 44;
  /// Extra height budget per additional overlapping event (sublinear growth).
  static const double stripOverlapHeightStep = 16;
  static const double stripOverlapMaxExtraHeight = 44;

  static double stripOverlapBudget(int layerCount) {
    if (layerCount <= 1) {
      return stripBaseHeight;
    }
    final double extra = math.min(
      (layerCount - 1) * stripOverlapHeightStep,
      stripOverlapMaxExtraHeight,
    );
    return stripBaseHeight + extra;
  }

  static double stripCardHeight(int layerCount) {
    if (layerCount <= 1) {
      return stripBaseHeight;
    }
    final double gaps = (layerCount - 1) * stripRowGap;
    final double budget = stripOverlapBudget(layerCount);
    return math.max(
      stripMinCardHeight,
      (budget - gaps) / layerCount,
    );
  }

  static double stripRowStep(int layerCount) =>
      stripCardHeight(layerCount) + stripRowGap;

  static double _layerOpacity({
    required int columnIndex,
    required int columnCount,
  }) {
    if (columnCount <= 1) {
      return 0.94;
    }
    return 0.78 +
        (columnIndex / math.max(1, columnCount - 1)) * 0.16;
  }

  static ({double left, double width, double backgroundOpacity}) forGrid({
    required double columnMaxWidth,
    required int columnIndex,
    required int columnCount,
  }) {
    final double innerMax = math.max(
      minGridBlockWidth,
      columnMaxWidth - gridEdgePadding * 2,
    );

    if (columnCount <= 1) {
      return (
        left: gridEdgePadding,
        width: innerMax,
        backgroundOpacity: 0.94,
      );
    }

    final int layers = columnCount - 1;
    final double desiredInset = layers * gridInsetPerLayer;
    final double totalInset = math.min(desiredInset, innerMax * 0.5);
    final double step = totalInset / layers;
    final double width = math.max(minGridBlockWidth, innerMax - totalInset);
    final double left = gridEdgePadding + columnIndex * step;

    return (
      left: left,
      width: width,
      backgroundOpacity: _layerOpacity(
        columnIndex: columnIndex,
        columnCount: columnCount,
      ),
    );
  }

  /// Non-overlapping rows: earliest top-left, later events below + shifted right.
  static ({
    double left,
    double top,
    double width,
    double height,
    double backgroundOpacity,
  }) forStrip({
    required int layerIndex,
    required int layerCount,
  }) {
    final double cardHeight = stripCardHeight(layerCount);
    return (
      left: layerIndex * stripLayerOffsetX,
      top: layerIndex * stripRowStep(layerCount),
      width: stripCardWidth,
      height: cardHeight,
      backgroundOpacity: 0.94,
    );
  }

  static double stripSlotWidth(int layerCount) {
    if (layerCount <= 1) {
      return stripCardWidth;
    }
    return stripCardWidth + (layerCount - 1) * stripLayerOffsetX;
  }

  static double stripSlotHeight(int layerCount) {
    if (layerCount <= 1) {
      return stripBaseHeight;
    }
    return layerCount * stripCardHeight(layerCount) +
        (layerCount - 1) * stripRowGap;
  }

  static int maxColumnCount(Iterable<int> counts) {
    int max = 1;
    for (final int count in counts) {
      if (count > max) {
        max = count;
      }
    }
    return max;
  }
}

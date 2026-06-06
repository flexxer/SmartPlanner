import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/core/theme/app_color_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_context_colors.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_occurrence.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_overlap_layout.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_grid_layout.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';

/// Multi-day columns with an hourly timeline, all-day row, and positioned event blocks.
class CalendarGridWeekView extends StatefulWidget {
  const CalendarGridWeekView({
    required this.rangeStart,
    required this.dayCount,
    required this.events,
    required this.onEmptySlotLongPress,
    required this.onEventTap,
    required this.onEventLongPress,
    this.hourHeight = CalendarGridLayout.defaultHourHeight,
    super.key,
  });

  final DateTime rangeStart;
  final int dayCount;
  final List<CalendarEvent> events;
  final void Function(DateTime day, DateTime start, DateTime end) onEmptySlotLongPress;
  final void Function(CalendarEvent event, DateTime day) onEventTap;
  final void Function(CalendarEvent event) onEventLongPress;
  final double hourHeight;

  @override
  State<CalendarGridWeekView> createState() => _CalendarGridWeekViewState();
}

class _CalendarGridWeekViewState extends State<CalendarGridWeekView> {
  final ScrollController _scrollController = ScrollController();

  static final DateFormat _weekdayFormat = DateFormat('E');
  static final DateFormat _hourFormat = DateFormat('HH:mm');

  List<DateTime> get _days => List<DateTime>.generate(
        widget.dayCount,
        (int i) => AppDateUtils.startOfDay(
          widget.rangeStart.add(Duration(days: i)),
        ),
      );

  bool get _rangeContainsToday {
    final DateTime today = AppDateUtils.startOfDay(DateTime.now());
    return _days.any(
      (DateTime day) => AppDateUtils.isSameCalendarDay(day, today),
    );
  }

  int get _maxAllDayRows {
    int maxRows = 0;
    for (final DateTime day in _days) {
      final int count =
          CalendarEventOccurrence.allDayEventsOnDay(widget.events, day).length;
      if (count > maxRows) {
        maxRows = count;
      }
    }
    return maxRows;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentTime());
  }

  @override
  void didUpdateWidget(CalendarGridWeekView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rangeStart != widget.rangeStart ||
        oldWidget.dayCount != widget.dayCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentTime());
    }
  }

  void _scrollToCurrentTime() {
    if (!_rangeContainsToday || !_scrollController.hasClients) {
      return;
    }

    final double viewportHeight =
        _scrollController.position.viewportDimension;
    final double target = CalendarGridLayout.scrollOffsetForTime(
      time: DateTime.now(),
      hourHeight: widget.hourHeight,
      viewportHeight: viewportHeight,
    );

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double timelineHeight =
        CalendarGridLayout.dayTimelineHeight(widget.hourHeight);
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int allDayRows = _maxAllDayRows;

    return Column(
      children: <Widget>[
        _DayHeaderRow(
          days: _days,
          weekdayFormat: _weekdayFormat,
          allDayRows: allDayRows,
          events: widget.events,
          onEventTap: widget.onEventTap,
          onEventLongPress: widget.onEventLongPress,
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: SizedBox(
              height: timelineHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _HourLabelsColumn(
                    hourHeight: widget.hourHeight,
                    hourFormat: _hourFormat,
                  ),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        for (final DateTime day in _days)
                          Expanded(
                            child: _DayColumn(
                              day: day,
                              events: widget.events,
                              hourHeight: widget.hourHeight,
                              timelineHeight: timelineHeight,
                              colors: colors,
                              onEmptySlotLongPress: widget.onEmptySlotLongPress,
                              onEventTap: widget.onEventTap,
                              onEventLongPress: widget.onEventLongPress,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayHeaderRow extends StatelessWidget {
  const _DayHeaderRow({
    required this.days,
    required this.weekdayFormat,
    required this.allDayRows,
    required this.events,
    required this.onEventTap,
    required this.onEventLongPress,
  });

  final List<DateTime> days;
  final DateFormat weekdayFormat;
  final int allDayRows;
  final List<CalendarEvent> events;
  final void Function(CalendarEvent event, DateTime day) onEventTap;
  final void Function(CalendarEvent event) onEventLongPress;

  static const double _allDayRowHeight = 22;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final double allDayBandHeight =
        allDayRows > 0 ? 8 + allDayRows * _allDayRowHeight : 0;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 44, right: 4, bottom: 4),
          child: Row(
            children: <Widget>[
              for (final DateTime day in days)
                Expanded(
                  child: _DayHeaderCell(
                    day: day,
                    weekdayLabel: weekdayFormat.format(day),
                    colors: colors,
                  ),
                ),
            ],
          ),
        ),
        if (allDayRows > 0)
          Padding(
            padding: const EdgeInsets.only(left: 44, right: 4, bottom: 4),
            child: SizedBox(
              height: allDayBandHeight,
              child: Row(
                children: <Widget>[
                  for (final DateTime day in days)
                    Expanded(
                      child: _AllDayColumn(
                        day: day,
                        events: CalendarEventOccurrence.allDayEventsOnDay(
                          events,
                          day,
                        ),
                        rowHeight: _allDayRowHeight,
                        colors: colors,
                        onEventTap: (CalendarEvent event) =>
                            onEventTap(event, day),
                        onEventLongPress: onEventLongPress,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AllDayColumn extends StatelessWidget {
  const _AllDayColumn({
    required this.day,
    required this.events,
    required this.rowHeight,
    required this.colors,
    required this.onEventTap,
    required this.onEventLongPress,
  });

  final DateTime day;
  final List<CalendarEvent> events;
  final double rowHeight;
  final ColorScheme colors;
  final void Function(CalendarEvent event) onEventTap;
  final void Function(CalendarEvent event) onEventLongPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: <Widget>[
          for (final CalendarEvent event in events)
            SizedBox(
              height: rowHeight,
              child: _AllDayChip(
                event: event,
                colors: colors,
                onTap: () => onEventTap(event),
                onLongPress: () => onEventLongPress(event),
              ),
            ),
        ],
      ),
    );
  }
}

class _AllDayChip extends StatelessWidget {
  const _AllDayChip({
    required this.event,
    required this.colors,
    required this.onTap,
    required this.onLongPress,
  });

  final CalendarEvent event;
  final ColorScheme colors;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final Color accent = CalendarContextColors.accentFor(
      context,
      calendarId: event.calendarId,
      fallbackColorValue: event.colorValue,
    );
    final ({Color background, Color foreground}) chipColors =
        AppColorUtils.chipFromAccent(accent, colors);

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 1, 2, 1),
      child: Material(
        color: chipColors.background,
        borderRadius: BorderRadius.circular(4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: accent, width: 3),
              ),
            ),
            child: Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: chipColors.foreground,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayHeaderCell extends StatelessWidget {
  const _DayHeaderCell({
    required this.day,
    required this.weekdayLabel,
    required this.colors,
  });

  final DateTime day;
  final String weekdayLabel;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final bool isToday = AppDateUtils.isToday(day);
    final TextStyle? weekdayStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
        );
    final TextStyle? dayStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: isToday ? colors.primary : colors.onSurface,
        );

    return Column(
      children: <Widget>[
        Text(weekdayLabel, style: weekdayStyle),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: isToday
              ? BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Text('${day.day}', style: dayStyle),
        ),
      ],
    );
  }
}

class _HourLabelsColumn extends StatelessWidget {
  const _HourLabelsColumn({
    required this.hourHeight,
    required this.hourFormat,
  });

  final double hourHeight;
  final DateFormat hourFormat;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return SizedBox(
      width: 44,
      child: Column(
        children: <Widget>[
          for (int hour = 0; hour < CalendarGridLayout.hoursPerDay; hour++)
            SizedBox(
              height: hourHeight,
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4, top: 2),
                  child: Text(
                    hour == 0
                        ? ''
                        : hourFormat.format(
                            DateTime(2000, 1, 1, hour),
                          ),
                    style: style,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatefulWidget {
  const _DayColumn({
    required this.day,
    required this.events,
    required this.hourHeight,
    required this.timelineHeight,
    required this.colors,
    required this.onEmptySlotLongPress,
    required this.onEventTap,
    required this.onEventLongPress,
  });

  final DateTime day;
  final List<CalendarEvent> events;
  final double hourHeight;
  final double timelineHeight;
  final ColorScheme colors;
  final void Function(DateTime day, DateTime start, DateTime end) onEmptySlotLongPress;
  final void Function(CalendarEvent event, DateTime day) onEventTap;
  final void Function(CalendarEvent event) onEventLongPress;

  @override
  State<_DayColumn> createState() => _DayColumnState();
}

class _DayColumnState extends State<_DayColumn> {
  DateTime? _selectionStart;
  DateTime? _selectionEnd;

  List<PlacedTimedEvent> get _placedEvents =>
      CalendarEventOverlapLayout.layoutDay(
        events: widget.events,
        day: widget.day,
      );

  void _clearSelection() {
    if (_selectionStart != null || _selectionEnd != null) {
      setState(() {
        _selectionStart = null;
        _selectionEnd = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isToday = AppDateUtils.isToday(widget.day);
    final List<PlacedTimedEvent> placed = _placedEvents;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (LongPressStartDetails details) {
        final DateTime start = CalendarGridLayout.snapSlotStart(
          day: widget.day,
          localY: details.localPosition.dy,
          hourHeight: widget.hourHeight,
        );
        setState(() {
          _selectionStart = start;
          _selectionEnd = start.add(CalendarGridLayout.defaultSlotDuration);
        });
      },
      onLongPressMoveUpdate: (LongPressMoveUpdateDetails details) {
        if (_selectionStart == null) {
          return;
        }
        setState(() {
          _selectionEnd = CalendarGridLayout.snapSelectionEnd(
            day: widget.day,
            start: _selectionStart!,
            localY: details.localPosition.dy,
            hourHeight: widget.hourHeight,
          );
        });
      },
      onLongPressEnd: (LongPressEndDetails details) {
        if (_selectionStart == null || _selectionEnd == null) {
          _clearSelection();
          return;
        }
        widget.onEmptySlotLongPress(
          widget.day,
          _selectionStart!,
          _selectionEnd!,
        );
        _clearSelection();
      },
      onLongPressCancel: _clearSelection,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: widget.colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                _HourGridLines(
                  hourHeight: widget.hourHeight,
                  color: widget.colors.outlineVariant.withValues(alpha: 0.35),
                ),
                for (final PlacedTimedEvent placedEvent in placed)
                  _EventBlock(
                    placedEvent: placedEvent,
                    columnMaxWidth: constraints.maxWidth,
                    hourHeight: widget.hourHeight,
                    colors: widget.colors,
                    onTap: () =>
                        widget.onEventTap(placedEvent.event, widget.day),
                    onLongPress: () =>
                        widget.onEventLongPress(placedEvent.event),
                  ),
                if (_selectionStart != null && _selectionEnd != null)
                  _SelectionOverlay(
                    start: _selectionStart!,
                    end: _selectionEnd!,
                    hourHeight: widget.hourHeight,
                    colors: widget.colors,
                  ),
                if (isToday)
                  _NowIndicator(
                    hourHeight: widget.hourHeight,
                    colors: widget.colors,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SelectionOverlay extends StatelessWidget {
  const _SelectionOverlay({
    required this.start,
    required this.end,
    required this.hourHeight,
    required this.colors,
  });

  final DateTime start;
  final DateTime end;
  final double hourHeight;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final double top = CalendarGridLayout.topOffsetForTime(start, hourHeight);
    final double height = CalendarGridLayout.heightForInterval(
      start: start,
      end: end,
      hourHeight: hourHeight,
    );

    return Positioned(
      top: top,
      left: 2,
      right: 2,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _HourGridLines extends StatelessWidget {
  const _HourGridLines({
    required this.hourHeight,
    required this.color,
  });

  final double hourHeight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int hour = 0; hour < CalendarGridLayout.hoursPerDay; hour++)
          Container(
            height: hourHeight,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: color),
              ),
            ),
          ),
      ],
    );
  }
}

class _NowIndicator extends StatelessWidget {
  const _NowIndicator({
    required this.hourHeight,
    required this.colors,
  });

  final double hourHeight;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final double top = CalendarGridLayout.topOffsetForTime(now, hourHeight);

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colors.error,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Container(
                height: 2,
                color: colors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventBlock extends StatelessWidget {
  const _EventBlock({
    required this.placedEvent,
    required this.columnMaxWidth,
    required this.hourHeight,
    required this.colors,
    required this.onTap,
    required this.onLongPress,
  });

  final PlacedTimedEvent placedEvent;
  final double columnMaxWidth;
  final double hourHeight;
  final ColorScheme colors;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final CalendarEvent event = placedEvent.event;
    final double top = CalendarGridLayout.topOffsetForTime(
      placedEvent.start,
      hourHeight,
    );
    final double height = CalendarGridLayout.heightForInterval(
      start: placedEvent.start,
      end: placedEvent.end,
      hourHeight: hourHeight,
    );
    final Color accent = CalendarContextColors.accentFor(
      context,
      calendarId: event.calendarId,
      fallbackColorValue: event.colorValue,
    );
    final ({Color background, Color foreground}) chipColors =
        AppColorUtils.chipFromAccent(accent, colors);
    final ({
      double left,
      double width,
      double backgroundOpacity,
    }) geometry = StackedOverlapGeometry.forGrid(
      columnMaxWidth: columnMaxWidth,
      columnIndex: placedEvent.columnIndex,
      columnCount: placedEvent.columnCount,
    );

    return Positioned(
      top: top,
      left: geometry.left,
      width: geometry.width,
      height: height,
      child: Material(
        color: chipColors.background.withValues(alpha: geometry.backgroundOpacity),
        borderRadius: BorderRadius.circular(4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: accent, width: 3),
                top: placedEvent.continuesFromPreviousDay
                    ? BorderSide(
                        color: accent.withValues(alpha: 0.6),
                        width: 1,
                      )
                    : BorderSide.none,
                bottom: placedEvent.continuesToNextDay
                    ? BorderSide(
                        color: accent.withValues(alpha: 0.6),
                        width: 1,
                      )
                    : BorderSide.none,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (placedEvent.continuesFromPreviousDay)
                  Icon(
                    Icons.arrow_upward,
                    size: 10,
                    color: chipColors.foreground.withValues(alpha: 0.7),
                  ),
                Flexible(
                  child: Text(
                    event.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: chipColors.foreground,
                        ),
                  ),
                ),
                if (placedEvent.continuesToNextDay)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(
                      Icons.arrow_downward,
                      size: 10,
                      color: chipColors.foreground.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

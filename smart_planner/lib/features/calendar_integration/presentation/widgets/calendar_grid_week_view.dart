import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_context_colors.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_occurrence.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_grid_layout.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';

/// Seven day columns with an hourly timeline (00:00–23:00) and positioned event blocks.
class CalendarGridWeekView extends StatelessWidget {
  const CalendarGridWeekView({
    required this.weekStart,
    required this.events,
    required this.onEmptySlotLongPress,
    required this.onEventTap,
    required this.onEventLongPress,
    this.hourHeight = CalendarGridLayout.defaultHourHeight,
    super.key,
  });

  final DateTime weekStart;
  final List<CalendarEvent> events;
  final void Function(DateTime day, DateTime start, DateTime end) onEmptySlotLongPress;
  final void Function(CalendarEvent event, DateTime day) onEventTap;
  final void Function(CalendarEvent event) onEventLongPress;
  final double hourHeight;

  static final DateFormat _weekdayFormat = DateFormat.E('ru');
  static final DateFormat _hourFormat = DateFormat('HH:mm', 'ru');

  List<DateTime> get _weekDays => List<DateTime>.generate(
        7,
        (int i) => AppDateUtils.startOfDay(weekStart.add(Duration(days: i))),
      );

  @override
  Widget build(BuildContext context) {
    final double timelineHeight = CalendarGridLayout.dayTimelineHeight(hourHeight);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      children: <Widget>[
        _WeekHeader(days: _weekDays, weekdayFormat: _weekdayFormat),
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: timelineHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _HourLabelsColumn(
                    hourHeight: hourHeight,
                    hourFormat: _hourFormat,
                  ),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        for (final DateTime day in _weekDays)
                          Expanded(
                            child: _DayColumn(
                              day: day,
                              events: events,
                              hourHeight: hourHeight,
                              timelineHeight: timelineHeight,
                              colors: colors,
                              onEmptySlotLongPress: onEmptySlotLongPress,
                              onEventTap: onEventTap,
                              onEventLongPress: onEventLongPress,
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

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.days,
    required this.weekdayFormat,
  });

  final List<DateTime> days;
  final DateFormat weekdayFormat;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
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

class _DayColumn extends StatelessWidget {
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

  List<_PlacedEvent> get _placedEvents {
    final List<_PlacedEvent> placed = <_PlacedEvent>[];
    for (final CalendarEvent event in events) {
      final ({DateTime start, DateTime end})? bounds =
          CalendarEventOccurrence.boundsOnDay(event, day);
      if (bounds == null) {
        continue;
      }
      placed.add(
        _PlacedEvent(
          event: event,
          start: bounds.start,
          end: bounds.end,
        ),
      );
    }
    placed.sort(
      (_PlacedEvent a, _PlacedEvent b) => a.start.compareTo(b.start),
    );
    return placed;
  }

  @override
  Widget build(BuildContext context) {
    final bool isToday = AppDateUtils.isToday(day);
    final List<_PlacedEvent> placed = _placedEvents;

    return GestureDetector(
      onLongPressStart: (LongPressStartDetails details) {
        final ({DateTime start, DateTime end}) slot =
            CalendarGridLayout.slotFromLocalY(
          day: day,
          localY: details.localPosition.dy,
          hourHeight: hourHeight,
        );
        onEmptySlotLongPress(day, slot.start, slot.end);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            _HourGridLines(
              hourHeight: hourHeight,
              color: colors.outlineVariant.withValues(alpha: 0.35),
            ),
            if (isToday) _NowIndicator(hourHeight: hourHeight, colors: colors),
            for (final _PlacedEvent placedEvent in placed)
              _EventBlock(
                placedEvent: placedEvent,
                hourHeight: hourHeight,
                colors: colors,
                onTap: () => onEventTap(placedEvent.event, day),
                onLongPress: () => onEventLongPress(placedEvent.event),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlacedEvent {
  const _PlacedEvent({
    required this.event,
    required this.start,
    required this.end,
  });

  final CalendarEvent event;
  final DateTime start;
  final DateTime end;
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
      child: Container(
        height: 2,
        color: colors.error,
      ),
    );
  }
}

class _EventBlock extends StatelessWidget {
  const _EventBlock({
    required this.placedEvent,
    required this.hourHeight,
    required this.colors,
    required this.onTap,
    required this.onLongPress,
  });

  final _PlacedEvent placedEvent;
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

    return Positioned(
      top: top,
      left: 2,
      right: 2,
      height: height,
      child: Material(
        color: accent.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: accent, width: 3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              event.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

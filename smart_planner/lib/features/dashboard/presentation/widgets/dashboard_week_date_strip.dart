import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/dashboard/domain/day_activity_marker.dart';

/// Horizontally scrollable week days with activity dots under each date.
class DashboardWeekDateStrip extends StatefulWidget {
  const DashboardWeekDateStrip({
    required this.selectedDate,
    required this.dayMarkers,
    required this.onDateSelected,
    super.key,
  });

  final DateTime selectedDate;
  final Map<int, DayActivityMarker> dayMarkers;
  final ValueChanged<DateTime> onDateSelected;

  static const double _dayWidth = 44;
  static const double _dotSize = 3.5;

  @override
  State<DashboardWeekDateStrip> createState() => _DashboardWeekDateStripState();
}

class _DashboardWeekDateStripState extends State<DashboardWeekDateStrip> {
  static final DateFormat _weekdayFormat = DateFormat.E('ru');
  final ScrollController _scrollController = ScrollController();
  int? _lastCenteredIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DashboardWeekDateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!AppDateUtils.isSameCalendarDay(
      oldWidget.selectedDate,
      widget.selectedDate,
    )) {
      _scrollToSelected();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) {
      return;
    }

    final List<DateTime> days = AppDateUtils.dateStripDays(widget.selectedDate);
    final int index = days.indexWhere(
      (DateTime d) => AppDateUtils.isSameCalendarDay(d, widget.selectedDate),
    );
    if (index < 0 || index == _lastCenteredIndex) {
      return;
    }

    _lastCenteredIndex = index;
    final double viewport = _scrollController.position.viewportDimension;
    final double target =
        (index * DashboardWeekDateStrip._dayWidth) -
        (viewport - DashboardWeekDateStrip._dayWidth) / 2;
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> days = AppDateUtils.dateStripDays(widget.selectedDate);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 72,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemExtent: DashboardWeekDateStrip._dayWidth,
        itemCount: days.length,
        itemBuilder: (BuildContext context, int index) {
          final DateTime day = days[index];
          final bool isSelected = AppDateUtils.isSameCalendarDay(
            day,
            widget.selectedDate,
          );
          final bool isToday = AppDateUtils.isToday(day);
          final DayActivityMarker marker = widget.dayMarkers[
                  AppDateUtils.dayKeyMs(day)] ??
              const DayActivityMarker.empty();

          return _DayCell(
            day: day,
            weekdayLabel: _weekdayFormat.format(day),
            isSelected: isSelected,
            isToday: isToday,
            marker: marker,
            colors: colors,
            dotSize: DashboardWeekDateStrip._dotSize,
            onTap: () => widget.onDateSelected(day),
          );
        },
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.weekdayLabel,
    required this.isSelected,
    required this.isToday,
    required this.marker,
    required this.colors,
    required this.dotSize,
    required this.onTap,
  });

  final DateTime day;
  final String weekdayLabel;
  final bool isSelected;
  final bool isToday;
  final DayActivityMarker marker;
  final ColorScheme colors;
  final double dotSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextStyle? weekdayStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: isSelected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
        );
    final TextStyle? dayStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: isSelected ? colors.onPrimaryContainer : colors.onSurface,
          fontWeight: FontWeight.w700,
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryContainer : null,
            borderRadius: BorderRadius.circular(10),
            border: isToday && !isSelected
                ? Border.all(color: colors.outline)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                weekdayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: weekdayStyle,
              ),
              const SizedBox(height: 2),
              Text('${day.day}', style: dayStyle),
              const SizedBox(height: 4),
              _DayMarkerDots(
                marker: marker,
                colors: colors,
                dotSize: dotSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayMarkerDots extends StatelessWidget {
  const _DayMarkerDots({
    required this.marker,
    required this.colors,
    required this.dotSize,
  });

  final DayActivityMarker marker;
  final ColorScheme colors;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    if (!marker.hasAnyIndicator) {
      return SizedBox(height: dotSize);
    }

    final List<Widget> dots = <Widget>[];
    if (marker.hasCalendarEvents) {
      dots.add(_MarkerDot(
        color: _calendarDotColor(marker.calendarColorValue, colors),
        size: dotSize,
      ));
    }
    if (marker.hasLocalTasks) {
      dots.add(_MarkerDot(
        color: colors.secondary,
        size: dotSize,
      ));
    }

    return SizedBox(
      height: dotSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < dots.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: 3),
            dots[i],
          ],
        ],
      ),
    );
  }

  static Color _calendarDotColor(int? colorValue, ColorScheme colors) {
    if (colorValue == null) {
      return colors.primary;
    }
    if (colorValue > 0xFFFFFF) {
      return Color(colorValue);
    }
    return Color(0xFF000000 | colorValue);
  }
}

class _MarkerDot extends StatelessWidget {
  const _MarkerDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

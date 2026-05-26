import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/dashboard/domain/day_activity_marker.dart';
import 'package:smart_planner/features/dashboard/presentation/widgets/day_marker_dots.dart';
import 'package:table_calendar/table_calendar.dart';

/// Month grid with activity dots under each day (same markers as the dashboard strip).
class CalendarGridMonthView extends StatelessWidget {
  const CalendarGridMonthView({
    required this.focusedDay,
    required this.dayMarkers,
    required this.onDaySelected,
    required this.onPageChanged,
    super.key,
  });

  final DateTime focusedDay;
  final Map<int, DayActivityMarker> dayMarkers;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onPageChanged;

  static final DateFormat _monthTitleFormat = DateFormat.yMMMM('ru');

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            _monthTitleFormat.format(focusedDay),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Expanded(
          child: TableCalendar<void>(
            locale: 'ru',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: focusedDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableGestures: AvailableGestures.horizontalSwipe,
            headerVisible: false,
            daysOfWeekHeight: 28,
            rowHeight: 52,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: true,
              todayDecoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
              selectedDecoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                color: colors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
              weekendTextStyle: TextStyle(color: colors.onSurfaceVariant),
              defaultTextStyle: TextStyle(color: colors.onSurface),
              outsideTextStyle: TextStyle(
                color: colors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
              weekendStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            selectedDayPredicate: (DateTime day) =>
                AppDateUtils.isSameCalendarDay(day, focusedDay),
            onDaySelected: (DateTime selectedDay, DateTime focused) {
              onDaySelected(selectedDay);
            },
            onPageChanged: onPageChanged,
            calendarBuilders: CalendarBuilders<void>(
              markerBuilder: (
                BuildContext context,
                DateTime day,
                List<void> events,
              ) {
                final DayActivityMarker marker = dayMarkers[
                        AppDateUtils.dayKeyMs(day)] ??
                    const DayActivityMarker.empty();
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: DayMarkerDots(marker: marker),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_occurrence.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/dashboard/domain/compressed_events_strip_layout.dart';
import 'package:smart_planner/features/dashboard/presentation/widgets/dashboard_all_day_events_row.dart';
import 'package:smart_planner/features/dashboard/presentation/widgets/dashboard_local_events_strip.dart';

/// Header + horizontal strip or empty state for local calendar events.
class DashboardLocalEventsSection extends StatelessWidget {
  const DashboardLocalEventsSection({
    required this.selectedDate,
    required this.events,
    required this.timeFormat,
    required this.onEventTap,
    required this.onEventLongPress,
    super.key,
  });

  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final DateFormat timeFormat;
  final void Function(CalendarEvent event) onEventTap;
  final void Function(CalendarEvent event) onEventLongPress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final String dayLabel = AppDateUtils.isToday(selectedDate)
        ? 'events_day_today'.tr()
        : L10n.dateFormat('d MMMM', context: context).format(selectedDate);

    final List<CalendarEvent> allDay =
        CalendarEventOccurrence.allDayEventsOnDay(events, selectedDate);
    final List<CalendarEvent> timed =
        CompressedEventsStripLayout.timedEventsForDay(events, selectedDate);
    final bool hasAnyEvents = allDay.isNotEmpty || timed.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'events_section_title'.tr(
              namedArgs: <String, String>{'day': dayLabel},
            ),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!hasAnyEvents)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'events_empty_day'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            )
          else ...<Widget>[
            DashboardAllDayEventsRow(
              events: events,
              selectedDate: selectedDate,
              onEventTap: onEventTap,
              onEventLongPress: onEventLongPress,
            ),
            DashboardLocalEventsStrip(
              events: events,
              selectedDate: selectedDate,
              timeFormat: timeFormat,
              onEventTap: onEventTap,
              onEventLongPress: onEventLongPress,
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/theme/app_color_utils.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_context_colors.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_occurrence.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/dashboard/presentation/widgets/dashboard_local_events_strip.dart';

/// All-day event chips shown above the timed events strip.
class DashboardAllDayEventsRow extends StatelessWidget {
  const DashboardAllDayEventsRow({
    required this.events,
    required this.selectedDate,
    required this.onEventTap,
    required this.onEventLongPress,
    super.key,
  });

  final List<CalendarEvent> events;
  final DateTime selectedDate;
  final void Function(CalendarEvent event) onEventTap;
  final void Function(CalendarEvent event) onEventLongPress;

  @override
  Widget build(BuildContext context) {
    final List<CalendarEvent> allDay =
        CalendarEventOccurrence.allDayEventsOnDay(events, selectedDate);
    if (allDay.isEmpty) {
      return const SizedBox.shrink();
    }

    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'events_all_day_header'.tr(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: allDay
                .map(
                  (CalendarEvent event) => _AllDayChip(
                    event: event,
                    selectedDate: selectedDate,
                    onTap: () => onEventTap(event),
                    onLongPress: () => onEventLongPress(event),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AllDayChip extends StatelessWidget {
  const _AllDayChip({
    required this.event,
    required this.selectedDate,
    required this.onTap,
    required this.onLongPress,
  });

  final CalendarEvent event;
  final DateTime selectedDate;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color accent = CalendarContextColors.accentFor(
      context,
      calendarId: event.calendarId,
      fallbackColorValue: event.colorValue,
    );
    final ({Color background, Color foreground}) chipColors =
        AppColorUtils.chipFromAccent(accent, colors);

    final DateTime eventStartDay = AppDateUtils.startOfDay(event.start);
    final DateTime eventEndDay =
        AppDateUtils.startOfDay(event.end.subtract(const Duration(minutes: 1)));
    final DateTime dayStart = AppDateUtils.startOfDay(selectedDate);
    final bool continues =
        eventStartDay.isBefore(dayStart) || eventEndDay.isAfter(dayStart);

    return Material(
      color: chipColors.background,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: accent, width: 4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (continues)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.date_range,
                    size: 14,
                    color: chipColors.foreground.withValues(alpha: 0.8),
                  ),
                ),
              Flexible(
                child: Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: chipColors.foreground,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

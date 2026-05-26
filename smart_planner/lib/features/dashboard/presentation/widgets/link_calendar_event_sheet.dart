import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_context_colors.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';

/// Picker sheet: link a task to one of the day's local calendar events.
class LinkCalendarEventSheet extends StatelessWidget {
  const LinkCalendarEventSheet({
    required this.events,
    required this.taskTitle,
    super.key,
  });

  final List<CalendarEvent> events;
  final String taskTitle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final DateFormat timeFormat = L10n.dateFormat('Hm', context: context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'link_event_sheet_title'.tr(),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              taskTitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (events.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'link_event_sheet_empty'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: events.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final CalendarEvent event = events[index];
                    final Color accent = CalendarContextColors.accentFor(
                      context,
                      calendarId: event.calendarId,
                      fallbackColorValue: event.colorValue,
                    );
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colors.outlineVariant),
                      ),
                      leading: VerticalDivider(
                        width: 4,
                        thickness: 4,
                        color: accent,
                      ),
                      title: Text(event.title),
                      subtitle: Text(
                        '${timeFormat.format(event.start)} – '
                        '${timeFormat.format(event.end)}',
                      ),
                      onTap: () => Navigator.of(context).pop(event),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

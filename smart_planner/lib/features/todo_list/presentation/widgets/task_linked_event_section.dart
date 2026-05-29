import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_context_colors.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_section_header.dart';

/// Linked calendar event block inside an expanded task tile.
class TaskLinkedEventSection extends StatelessWidget {
  const TaskLinkedEventSection({
    required this.linkedEvent,
    required this.onLink,
    required this.onUnlink,
    super.key,
  });

  final CalendarEvent? linkedEvent;
  final VoidCallback onLink;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final DateFormat timeFormat = L10n.dateFormat('Hm', context: context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TaskTileSectionHeader(
          icon: Icons.event,
          title: 'task_linked_event_section_title'.tr(),
        ),
        const SizedBox(height: 8),
        if (linkedEvent == null)
          OutlinedButton.icon(
            onPressed: onLink,
            icon: const Icon(Icons.link),
            label: Text('task_relation_button'.tr()),
          )
        else ...<Widget>[
          Builder(
            builder: (BuildContext context) {
              final CalendarEvent event = linkedEvent!;
              final Color accent = CalendarContextColors.accentFor(
                context,
                calendarId: event.calendarId,
                fallbackColorValue: event.colorValue,
              );
              return Material(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              event.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${timeFormat.format(event.start)} – '
                              '${timeFormat.format(event.end)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'child_tasks_unlink_tooltip'.tr(),
                        onPressed: onUnlink,
                        icon: const Icon(Icons.link_off),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

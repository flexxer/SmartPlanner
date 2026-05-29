import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/features/notifications/domain/reminder_labels.dart';

/// Read-only reminder row for task/event detail screens.
class ReminderDetailRow extends StatelessWidget {
  const ReminderDetailRow({
    this.minutesBefore,
    this.reminderAt,
    this.fireAt,
    this.inactiveHint,
    super.key,
  });

  /// Offset before event start (events only).
  final int? minutesBefore;

  /// Absolute fire time (tasks).
  final DateTime? reminderAt;

  /// When set and in the future, shown as “notification at …” (events).
  final DateTime? fireAt;

  final String? inactiveHint;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final DateTime? at = reminderAt;
    final String value = at != null
        ? L10n.dateFormat('d MMM yyyy, HH:mm', context: context).format(at)
        : ReminderLabels.labelForMinutes(minutesBefore);
    final DateTime? notifyAt = at ?? fireAt;
    final bool showFireAt = at == null &&
        notifyAt != null &&
        notifyAt.isAfter(DateTime.now()) &&
        minutesBefore != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          Icons.notifications_outlined,
          size: 22,
          color: colors.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: '${'field_reminder'.tr()}: ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    TextSpan(
                      text: value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (showFireAt && notifyAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'reminder_fire_at'.tr(
                      namedArgs: <String, String>{
                        'datetime': L10n.dateFormat(
                          'd MMM yyyy, HH:mm',
                          context: context,
                        ).format(notifyAt),
                      },
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              if (inactiveHint != null && inactiveHint!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    inactiveHint!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

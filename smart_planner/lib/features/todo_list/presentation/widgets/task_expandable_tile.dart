import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_context_colors.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_attachments_section.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_badge.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_child_tasks_section.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_priority_ui.dart';

/// Compact dashboard task row; tap opens [TaskDetailScreen].
class TaskExpandableTile extends StatelessWidget {
  const TaskExpandableTile({
    required this.task,
    required this.selectedDate,
    required this.onToggleComplete,
    required this.onOpenDetail,
    required this.childTasksBundle,
    required this.attachments,
    this.contextCalendar,
    this.linkedEvent,
    this.onOpenLinkedEvent,
    this.onLinkToCalendarEvent,
    super.key,
  });

  final Task task;
  final DateTime selectedDate;
  final VoidCallback onToggleComplete;
  final VoidCallback onOpenDetail;
  final ChildTasksBundle childTasksBundle;
  final List<TaskAttachment> attachments;
  final DeviceCalendarInfo? contextCalendar;
  final CalendarEvent? linkedEvent;
  final VoidCallback? onOpenLinkedEvent;
  final VoidCallback? onLinkToCalendarEvent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isOverdue = task.dynamicOverdueDays > 0;
    final String? description = task.description?.trim();
    final bool hasDescription =
        description != null && description.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        elevation: 1,
        shadowColor: colors.shadow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _TaskCompletionTapTarget(
              isCompleted: task.isCompleted,
              onToggle: onToggleComplete,
            ),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onOpenDetail,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    task.title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: task.isCompleted
                                          ? colors.onSurface.withValues(
                                              alpha: 0.6,
                                            )
                                          : null,
                                    ),
                                  ),
                                  if (hasDescription) ...<Widget>[
                                    const SizedBox(height: 2),
                                    Text(
                                      description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: colors.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        _TaskBadgesRow(
                          task: task,
                          selectedDate: selectedDate,
                          isOverdue: isOverdue,
                          contextCalendar: contextCalendar,
                          linkedEvent: linkedEvent,
                          childTasksBundle: childTasksBundle,
                          attachments: attachments,
                          onOpenLinkedEvent: onOpenLinkedEvent,
                          onLinkToCalendarEvent: onLinkToCalendarEvent,
                          onChildTasksBadgeTap: childTasksBundle.hasChildren
                              ? onOpenDetail
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCompletionTapTarget extends StatelessWidget {
  const _TaskCompletionTapTarget({
    required this.isCompleted,
    required this.onToggle,
  });

  final bool isCompleted;
  final VoidCallback onToggle;

  static const double _minTouchTarget = 48;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        customBorder: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
          ),
        ),
        child: SizedBox(
          width: _minTouchTarget,
          height: _minTouchTarget,
          child: Center(
            child: IgnorePointer(
              child: Checkbox(
                value: isCompleted,
                onChanged: (_) {},
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskBadgesRow extends StatelessWidget {
  const _TaskBadgesRow({
    required this.task,
    required this.selectedDate,
    required this.isOverdue,
    this.contextCalendar,
    required this.linkedEvent,
    required this.childTasksBundle,
    required this.attachments,
    this.onOpenLinkedEvent,
    this.onLinkToCalendarEvent,
    this.onChildTasksBadgeTap,
  });

  final Task task;
  final DateTime selectedDate;
  final bool isOverdue;
  final DeviceCalendarInfo? contextCalendar;
  final CalendarEvent? linkedEvent;
  final ChildTasksBundle childTasksBundle;
  final List<TaskAttachment> attachments;
  final VoidCallback? onOpenLinkedEvent;
  final VoidCallback? onLinkToCalendarEvent;
  final VoidCallback? onChildTasksBadgeTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: <Widget>[
        if (_contextCalendarBadge(context) case final Widget calendarBadge)
          calendarBadge,
        TaskBadge(
          label: TaskPriorityUi.label(task.priority),
          backgroundColor:
              TaskPriorityUi.backgroundColor(task.priority, colors),
          foregroundColor:
              TaskPriorityUi.foregroundColor(task.priority, colors),
          icon: Icons.flag_outlined,
        ),
        TaskBadge(
          label: _dueBadgeLabel(context, task, selectedDate),
          backgroundColor: isOverdue
              ? colors.errorContainer
              : colors.primaryContainer,
          foregroundColor: isOverdue
              ? colors.onErrorContainer
              : colors.onPrimaryContainer,
          icon: Icons.event_outlined,
        ),
        if (isOverdue)
          TaskBadge(
            label: L10n.overdueDays(task.dynamicOverdueDays),
            backgroundColor: colors.errorContainer,
            foregroundColor: colors.onErrorContainer,
            icon: Icons.schedule,
          ),
        ..._linkedEntityBadges(context, colors),
        if (checklistAttachmentProgressBadgeLabel(attachments)
            case final String checklistProgress)
          TaskBadge(
            label: checklistProgress,
            backgroundColor: colors.secondaryContainer,
            foregroundColor: colors.onSecondaryContainer,
            icon: Icons.fact_check,
          ),
        if (nonChecklistAttachmentCountBadgeLabel(attachments)
            case final String attachCount)
          TaskBadge(
            label: attachCount,
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.onPrimaryContainer,
            icon: Icons.attach_file,
          ),
      ],
    );
  }

  Widget? _contextCalendarBadge(BuildContext context) {
    final String calendarId = task.calendarId.trim();
    if (calendarId.isEmpty) {
      return null;
    }

    final DeviceCalendarInfo? info = contextCalendar;
    final String label = info?.name ?? calendarId;
    final ({Color background, Color foreground}) badgeColors =
        CalendarContextColors.badgeColorsFor(
      context,
      calendarId: calendarId,
      fallbackColorValue: info?.colorValue,
    );

    return TaskBadge(
      label: label,
      backgroundColor: badgeColors.background,
      foregroundColor: badgeColors.foreground,
      icon: Icons.calendar_month_outlined,
    );
  }

  List<Widget> _linkedEntityBadges(BuildContext context, ColorScheme colors) {
    final List<Widget> badges = <Widget>[];

    if (linkedEvent != null) {
      badges.add(
        TaskBadge(
          label: _linkedEventBadgeLabel(context, linkedEvent!),
          backgroundColor: colors.secondaryContainer,
          foregroundColor: colors.onSecondaryContainer,
          icon: Icons.event,
          onTap: onOpenLinkedEvent,
        ),
      );
    } else if (onLinkToCalendarEvent != null) {
      badges.add(
        TaskBadge(
          label: 'task_to_event'.tr(),
          backgroundColor: colors.surfaceContainerHighest,
          foregroundColor: colors.onSurfaceVariant,
          icon: Icons.link,
          onTap: onLinkToCalendarEvent,
        ),
      );
    }

    if (childTaskProgressBadgeLabel(childTasksBundle) case final String progress) {
      badges.add(
        TaskBadge(
          label: progress,
          backgroundColor: colors.tertiaryContainer,
          foregroundColor: colors.onTertiaryContainer,
          icon: Icons.account_tree,
          onTap: onChildTasksBadgeTap,
        ),
      );
    }

    return badges;
  }

  String _linkedEventBadgeLabel(BuildContext context, CalendarEvent event) {
    final String title = event.title.trim();
    if (title.isEmpty) {
      return 'task_event_fallback'.tr();
    }
    if (title.length <= 20) {
      return title;
    }
    return '${title.substring(0, 18)}…';
  }

  String _dueBadgeLabel(BuildContext context, Task task, DateTime selectedDate) {
    final DateTime? due = task.dueDate;
    if (due == null) {
      return 'no_due_date'.tr();
    }
    if (AppDateUtils.isSameCalendarDay(due, selectedDate) &&
        AppDateUtils.isToday(selectedDate)) {
      return 'due_today'.tr();
    }
    return L10n.dateFormat('d MMM yyyy', context: context).format(due);
  }
}


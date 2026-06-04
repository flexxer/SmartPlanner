import 'package:flutter/material.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_badges_row.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_priority_icon.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_tile_list_context.dart';

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
    required this.listContext,
    this.visibleCalendarCount = 1,
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
  final TaskTileListContext listContext;
  final int visibleCalendarCount;

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
                            Padding(
                              padding: const EdgeInsets.only(top: 2, right: 6),
                              child: TaskPriorityIcon(
                                priority: task.priority,
                              ),
                            ),
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
                        TaskBadgesRow(
                          task: task,
                          selectedDate: selectedDate,
                          isOverdue: isOverdue,
                          listContext: listContext,
                          visibleCalendarCount: visibleCalendarCount,
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


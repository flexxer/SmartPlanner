import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_badge.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_priority_ui.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_attachments_section.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_child_tasks_section.dart';

/// Горизонтальная плитка задачи: свёрнутое превью и плавное раскрытие деталей.
class TaskExpandableTile extends StatefulWidget {
  const TaskExpandableTile({
    required this.task,
    required this.selectedDate,
    required this.onToggleComplete,
    required this.onPostpone,
    required this.onPostponeToTomorrow,
    required this.childTasksBundle,
    required this.onToggleChildComplete,
    required this.onDetachChild,
    required this.onLinkExistingTask,
    required this.attachments,
    required this.attachmentRepository,
    required this.onDeleteAttachment,
    required this.onToggleChecklistItem,
    required this.onAddAttachment,
    super.key,
  });

  final Task task;
  final DateTime selectedDate;
  final ChildTasksBundle childTasksBundle;
  final List<TaskAttachment> attachments;
  final TaskAttachmentRepository attachmentRepository;
  final VoidCallback onToggleComplete;
  final VoidCallback onPostpone;
  final VoidCallback onPostponeToTomorrow;
  final void Function(Id childTaskId) onToggleChildComplete;
  final void Function(Id childTaskId) onDetachChild;
  final VoidCallback onLinkExistingTask;
  final void Function(Id attachmentId) onDeleteAttachment;
  final void Function(Id attachmentId, int itemLocalId) onToggleChecklistItem;
  final VoidCallback onAddAttachment;

  @override
  State<TaskExpandableTile> createState() => _TaskExpandableTileState();
}

class _TaskExpandableTileState extends State<TaskExpandableTile> {
  static const Duration _expandDuration = Duration(milliseconds: 280);
  static const double _minTouchTarget = 48;
  static final DateFormat _dueFormat = DateFormat('d MMM yyyy', 'ru');
  static final DateFormat _createdFormat = DateFormat('d MMM yyyy, HH:mm', 'ru');

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final Task task = widget.task;
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool isOverdue = _isOverdueOnSelectedDay(task, widget.selectedDate);
    final String? description = task.description?.trim();
    final bool hasDescription =
        description != null && description.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        elevation: 1,
        shadowColor: colors.shadow.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _TaskCompletionTapTarget(
                  isCompleted: task.isCompleted,
                  onToggle: widget.onToggleComplete,
                  minTouchTarget: _minTouchTarget,
                ),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 12, 8, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                AnimatedRotation(
                                  turns: _expanded ? 0.5 : 0,
                                  duration: _expandDuration,
                                  curve: Curves.easeInOut,
                                  child: Icon(
                                    Icons.expand_more,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            if (hasDescription && !_expanded) ...<Widget>[
                              const SizedBox(height: 6),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            _TaskBadgesRow(
                              task: task,
                              selectedDate: widget.selectedDate,
                              isOverdue: isOverdue,
                              childTasksBundle: widget.childTasksBundle,
                              attachments: widget.attachments,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: _expandDuration,
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? _ExpandedDetails(
                      task: task,
                      description: description,
                      hasDescription: hasDescription,
                      isOverdue: isOverdue,
                      dueFormat: _dueFormat,
                      createdFormat: _createdFormat,
                      onPostpone: widget.onPostpone,
                      onPostponeToTomorrow: widget.onPostponeToTomorrow,
                      childTasksBundle: widget.childTasksBundle,
                      onToggleChildComplete: widget.onToggleChildComplete,
                      onDetachChild: widget.onDetachChild,
                      onLinkExistingTask: widget.onLinkExistingTask,
                      attachments: widget.attachments,
                      attachmentRepository: widget.attachmentRepository,
                      onDeleteAttachment: widget.onDeleteAttachment,
                      onToggleChecklistItem: widget.onToggleChecklistItem,
                      onAddAttachment: widget.onAddAttachment,
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isOverdueOnSelectedDay(Task task, DateTime selectedDate) {
    if (task.overdueCount <= 0) {
      return false;
    }
    final DateTime? due = task.dueDate;
    if (due == null) {
      return false;
    }
    return !AppDateUtils.isSameCalendarDay(due, selectedDate);
  }
}

/// Dedicated completion control: own [Material] + [InkWell] splash, ≥48dp target.
class _TaskCompletionTapTarget extends StatelessWidget {
  const _TaskCompletionTapTarget({
    required this.isCompleted,
    required this.onToggle,
    required this.minTouchTarget,
  });

  final bool isCompleted;
  final VoidCallback onToggle;
  final double minTouchTarget;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        customBorder: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
          ),
        ),
        splashColor: colors.primary.withValues(alpha: 0.12),
        highlightColor: colors.primary.withValues(alpha: 0.08),
        child: SizedBox(
          width: minTouchTarget,
          height: minTouchTarget,
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
    required this.childTasksBundle,
    required this.attachments,
  });

  final Task task;
  final DateTime selectedDate;
  final bool isOverdue;
  final ChildTasksBundle childTasksBundle;
  final List<TaskAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: <Widget>[
        TaskBadge(
          label: TaskPriorityUi.label(task.priority),
          backgroundColor:
              TaskPriorityUi.backgroundColor(task.priority, colors),
          foregroundColor:
              TaskPriorityUi.foregroundColor(task.priority, colors),
          icon: Icons.flag_outlined,
        ),
        TaskBadge(
          label: _dueBadgeLabel(task, selectedDate),
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
            label: _overdueLabel(task.overdueCount),
            backgroundColor: colors.errorContainer,
            foregroundColor: colors.onErrorContainer,
            icon: Icons.schedule,
          ),
        ..._linkedAndChecklistBadges(
          colors: colors,
          childTasksBundle: childTasksBundle,
          attachments: attachments,
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

  static List<Widget> _linkedAndChecklistBadges({
    required ColorScheme colors,
    required ChildTasksBundle childTasksBundle,
    required List<TaskAttachment> attachments,
  }) {
    final List<Widget> badges = <Widget>[];

    if (childTaskProgressBadgeLabel(childTasksBundle) case final String linked) {
      badges.add(
        TaskBadge(
          label: linked,
          backgroundColor: colors.tertiaryContainer,
          foregroundColor: colors.onTertiaryContainer,
          icon: Icons.account_tree,
        ),
      );
    }

    if (checklistAttachmentProgressBadgeLabel(attachments)
        case final String checklistProgress) {
      badges.add(
        TaskBadge(
          label: checklistProgress,
          backgroundColor: colors.secondaryContainer,
          foregroundColor: colors.onSecondaryContainer,
          icon: Icons.fact_check,
        ),
      );
    }

    if (badges.isEmpty) {
      return badges;
    }

    return <Widget>[
      Wrap(
        spacing: 4,
        runSpacing: 6,
        children: badges,
      ),
    ];
  }

  static String _dueBadgeLabel(Task task, DateTime selectedDate) {
    final DateTime? due = task.dueDate;
    if (due == null) {
      return 'Без срока';
    }
    if (AppDateUtils.isSameCalendarDay(due, selectedDate) &&
        AppDateUtils.isToday(selectedDate)) {
      return 'Срок сегодня';
    }
    return DateFormat('d MMM yyyy', 'ru').format(due);
  }

  static String _overdueLabel(int count) {
    final int mod10 = count % 10;
    final int mod100 = count % 100;
    if (mod10 == 1 && mod100 != 11) {
      return 'Тянется $count день';
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return 'Тянется $count дня';
    }
    return 'Тянется $count дней';
  }
}

class _ExpandedDetails extends StatelessWidget {
  const _ExpandedDetails({
    required this.task,
    required this.description,
    required this.hasDescription,
    required this.isOverdue,
    required this.dueFormat,
    required this.createdFormat,
    required this.onPostpone,
    required this.onPostponeToTomorrow,
    required this.childTasksBundle,
    required this.onToggleChildComplete,
    required this.onDetachChild,
    required this.onLinkExistingTask,
    required this.attachments,
    required this.attachmentRepository,
    required this.onDeleteAttachment,
    required this.onToggleChecklistItem,
    required this.onAddAttachment,
  });

  final Task task;
  final ChildTasksBundle childTasksBundle;
  final List<TaskAttachment> attachments;
  final TaskAttachmentRepository attachmentRepository;
  final String? description;
  final bool hasDescription;
  final bool isOverdue;
  final DateFormat dueFormat;
  final DateFormat createdFormat;
  final VoidCallback onPostpone;
  final VoidCallback onPostponeToTomorrow;
  final void Function(Id childTaskId) onToggleChildComplete;
  final void Function(Id childTaskId) onDetachChild;
  final VoidCallback onLinkExistingTask;
  final void Function(Id attachmentId) onDeleteAttachment;
  final void Function(Id attachmentId, int itemLocalId) onToggleChecklistItem;
  final VoidCallback onAddAttachment;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(52, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Divider(height: 1, color: colors.outlineVariant),
          const SizedBox(height: 12),
          TaskChildTasksSection(
            bundle: childTasksBundle,
            onToggleChildComplete: onToggleChildComplete,
            onDetachChild: onDetachChild,
            onLinkExistingTask: onLinkExistingTask,
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: colors.outlineVariant),
          const SizedBox(height: 16),
          TaskAttachmentsSection(
            attachments: attachments,
            attachmentRepository: attachmentRepository,
            onDeleteAttachment: onDeleteAttachment,
            onToggleChecklistItem: onToggleChecklistItem,
            onAddAttachment: onAddAttachment,
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: colors.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Подробности',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (hasDescription)
            Text(
              description!,
              style: theme.textTheme.bodyMedium,
            )
          else
            Text(
              'Описание не задано',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 12),
          _DetailLine(
            icon: Icons.flag_outlined,
            label: 'Приоритет',
            value: TaskPriorityUi.label(task.priority),
          ),
          const SizedBox(height: 6),
          _DetailLine(
            icon: Icons.event_outlined,
            label: 'Срок',
            value: task.dueDate != null
                ? dueFormat.format(task.dueDate!)
                : 'Не задан',
          ),
          if (isOverdue) ...<Widget>[
            const SizedBox(height: 6),
            _DetailLine(
              icon: Icons.warning_amber_outlined,
              label: 'Просрочка',
              value: _TaskBadgesRow._overdueLabel(task.overdueCount),
              valueColor: colors.error,
            ),
          ],
          const SizedBox(height: 6),
          _DetailLine(
            icon: Icons.add_circle_outline,
            label: 'Создана',
            value: createdFormat.format(task.createDate),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPostponeToTomorrow,
                  icon: const Icon(Icons.today_outlined, size: 18),
                  label: const Text('На завтра'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onPostpone,
                  icon: const Icon(Icons.event_repeat, size: 18),
                  label: const Text('Перенести'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(color: valueColor ?? colors.onSurface),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

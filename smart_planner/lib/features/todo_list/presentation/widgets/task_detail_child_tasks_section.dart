import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/presentation/widgets/collapsing_completion_tile.dart';
import 'package:smart_planner/core/theme/app_theme.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_section_header.dart';

/// Child tasks under a parent [Task] with completion animations.
class TaskDetailChildTasksSection extends StatelessWidget {
  const TaskDetailChildTasksSection({
    required this.activeChildren,
    required this.completedChildren,
    required this.completedCount,
    required this.totalCount,
    required this.onReorder,
    required this.onToggleChildComplete,
    required this.onDetachChild,
    required this.onLinkExistingTask,
    required this.onOpenChild,
    super.key,
  });

  final List<Task> activeChildren;
  final List<Task> completedChildren;
  final int completedCount;
  final int totalCount;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(Id childTaskId) onToggleChildComplete;
  final void Function(Id childTaskId) onDetachChild;
  final VoidCallback onLinkExistingTask;
  final void Function(Task child) onOpenChild;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final DateFormat dueFormat =
        L10n.dateFormat('d MMM yyyy', context: context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TaskTileSectionHeader(
          icon: Icons.account_tree,
          title: 'child_tasks_title'.tr(),
          trailing: totalCount > 0 ? '$completedCount/$totalCount' : null,
          iconColor: colors.tertiary,
        ),
        const SizedBox(height: 8),
        if (activeChildren.isEmpty && completedChildren.isEmpty)
          Text(
            'child_tasks_empty'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          )
        else if (activeChildren.isEmpty)
          Text(
            'child_tasks_all_done'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        if (activeChildren.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: activeChildren.length,
            onReorder: onReorder,
            itemBuilder: (BuildContext context, int index) {
              final Task child = activeChildren[index];
              return _ReorderableChildRow(
                key: ValueKey<int>(child.id),
                index: index,
                child: child,
                dueFormat: dueFormat,
                onToggleComplete: () => onToggleChildComplete(child.id),
                onDetach: () => onDetachChild(child.id),
                onOpen: () => onOpenChild(child),
              );
            },
          ),
        if (completedChildren.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            'child_tasks_completed'.tr(),
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          ...completedChildren.map(
            (Task child) => _CompletedChildRow(
              child: child,
              onToggleComplete: () => onToggleChildComplete(child.id),
              onOpen: () => onOpenChild(child),
            ),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onLinkExistingTask,
          icon: const Icon(Icons.link, size: 18),
          label: Text('task_relation_button'.tr()),
        ),
      ],
    );
  }
}

class _ReorderableChildRow extends StatelessWidget {
  const _ReorderableChildRow({
    required super.key,
    required this.index,
    required this.child,
    required this.dueFormat,
    required this.onToggleComplete,
    required this.onDetach,
    required this.onOpen,
  });

  final int index;
  final Task child;
  final DateFormat dueFormat;
  final VoidCallback onToggleComplete;
  final VoidCallback onDetach;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final String? dueLabel =
        child.dueDate != null ? dueFormat.format(child.dueDate!) : null;

    return CollapsingCompletionTile(
      key: ValueKey<String>('child-active-${child.id}'),
      onAfterCollapse: onToggleComplete,
      builder: (VoidCallback onToggle) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: colors.surface,
          shape: AppTheme.insetCardShape(colors),
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.drag_handle,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: false,
                      onChanged: (_) => onToggle(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          child.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (dueLabel != null)
                          Text(
                            'due_label'.tr(
                              namedArgs: <String, String>{'date': dueLabel},
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDetach,
                    icon: Icon(
                      Icons.link_off,
                      size: 18,
                      color: colors.onSurfaceVariant,
                    ),
                    tooltip: 'child_tasks_unlink_tooltip'.tr(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CompletedChildRow extends StatelessWidget {
  const _CompletedChildRow({
    required this.child,
    required this.onToggleComplete,
    required this.onOpen,
  });

  final Task child;
  final VoidCallback onToggleComplete;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return CollapsingCompletionTile(
      key: ValueKey<String>('child-done-${child.id}'),
      onAfterCollapse: onToggleComplete,
      builder: (VoidCallback onToggle) {
        return InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: true,
                    onChanged: (_) => onToggle(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    child.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

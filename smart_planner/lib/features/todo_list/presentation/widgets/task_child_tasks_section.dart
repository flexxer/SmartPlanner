import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/task_hierarchy.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_section_header.dart';

/// Linked child [Task] rows inside an expanded parent tile.
class TaskChildTasksSection extends StatelessWidget {
  const TaskChildTasksSection({
    required this.bundle,
    required this.onToggleChildComplete,
    required this.onDetachChild,
    required this.onLinkExistingTask,
    super.key,
  });

  final ChildTasksBundle bundle;
  final void Function(Id childTaskId) onToggleChildComplete;
  final void Function(Id childTaskId) onDetachChild;
  final VoidCallback onLinkExistingTask;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final List<Task> children = bundle.activeChildren;
    final DateFormat dueFormat = L10n.dateFormat('d MMM', context: context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TaskTileSectionHeader(
          icon: Icons.account_tree,
          title: 'child_tasks_title'.tr(),
          trailing: bundle.hasChildren
              ? '${bundle.completedCount}/${bundle.totalCount}'
              : null,
          iconColor: colors.tertiary,
        ),
        const SizedBox(height: 8),
        if (children.isEmpty)
          Text(
            bundle.allCompleted
                ? 'child_tasks_all_done'.tr()
                : 'child_tasks_empty'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...children.map(
            (Task child) => _ChildTaskRow(
              child: child,
              dueFormat: dueFormat,
              onToggleComplete: () => onToggleChildComplete(child.id),
              onDetach: () => onDetachChild(child.id),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onLinkExistingTask,
          icon: const Icon(Icons.link, size: 18),
          label: Text('child_tasks_link'.tr()),
        ),
      ],
    );
  }
}

class _ChildTaskRow extends StatelessWidget {
  const _ChildTaskRow({
    required this.child,
    required this.dueFormat,
    required this.onToggleComplete,
    required this.onDetach,
  });

  final Task child;
  final DateFormat dueFormat;
  final VoidCallback onToggleComplete;
  final VoidCallback onDetach;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final String? dueLabel = child.dueDate != null
        ? dueFormat.format(child.dueDate!)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: false,
              onChanged: (_) => onToggleComplete(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  child.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
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
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'child_detach_parent_tooltip'.tr(),
          ),
        ],
      ),
    );
  }
}

String? childTaskProgressBadgeLabel(ChildTasksBundle? bundle) {
  if (bundle == null || !bundle.hasChildren) {
    return null;
  }
  return '${bundle.completedCount}/${bundle.totalCount}';
}

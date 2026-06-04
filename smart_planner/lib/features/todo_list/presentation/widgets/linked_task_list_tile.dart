import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Task row for linked-task lists (event detail, relation picker).
class LinkedTaskListTile extends StatelessWidget {
  const LinkedTaskListTile({
    required this.task,
    required this.onTap,
    this.onToggleComplete,
    this.useCard = true,
    super.key,
  });

  final Task task;
  final VoidCallback onTap;
  final ValueChanged<Id>? onToggleComplete;
  final bool useCard;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final Widget tile = ListTile(
      contentPadding: useCard ? null : EdgeInsets.zero,
      leading: onToggleComplete != null
          ? Checkbox(
              value: task.isCompleted,
              onChanged: (_) => onToggleComplete!(task.id),
            )
          : null,
      title: Text(
        task.title,
        style: task.isCompleted
            ? theme.textTheme.bodyLarge?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: colors.onSurfaceVariant,
              )
            : theme.textTheme.bodyLarge,
      ),
      subtitle: task.dueDate != null ? _dueSubtitle(context) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );

    if (!useCard) {
      return tile;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      child: tile,
    );
  }

  Widget _dueSubtitle(BuildContext context) {
    return Text(
      'due_label'.tr(
        namedArgs: <String, String>{
          'date': L10n.dateFormat('d MMM yyyy', context: context)
              .format(task.dueDate!),
        },
      ),
    );
  }
}

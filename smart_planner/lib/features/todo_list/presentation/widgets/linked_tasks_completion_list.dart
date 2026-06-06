import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/presentation/widgets/sliding_completion_list.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';

/// Linked tasks on event detail with slide-to-end completion animation.
class LinkedTasksCompletionList extends StatelessWidget {
  const LinkedTasksCompletionList({
    required this.tasks,
    required this.onToggleComplete,
    required this.onOpenTask,
    super.key,
  });

  final List<Task> tasks;
  final void Function(Id taskId) onToggleComplete;
  final void Function(Task task) onOpenTask;

  static const double _cardBottomMargin = 8;
  static const double _horizontalPadding = 16;
  static const double _leadingWidth = 52;

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = Theme.of(context).textTheme.bodyLarge!;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxTextWidth = _maxTextWidth(constraints.maxWidth);

        return SlidingCompletionList<Task>(
          items: tasks,
          idOf: (Task task) => task.id,
          isCompleted: (Task task) => task.isCompleted,
          toggleItem: (Task task) => task..isCompleted = !task.isCompleted,
          itemExtent: (Task task) =>
              _rowExtent(context, task, maxTextWidth, titleStyle) +
              _cardBottomMargin,
          moveCompletedToEnd: true,
          onToggle: (Task task) => onToggleComplete(task.id),
          itemBuilder: (
            BuildContext context,
            Task task, {
            required bool syncStyleWithSlide,
            required Animation<double>? styleProgress,
            required VoidCallback onToggle,
          }) {
            return _LinkedTaskRow(
              task: task,
              syncStyleWithSlide: syncStyleWithSlide,
              styleProgress: styleProgress,
              onToggle: onToggle,
              onOpen: () => onOpenTask(task),
            );
          },
        );
      },
    );
  }

  static double _maxTextWidth(double constraintWidth) {
    if (constraintWidth.isFinite &&
        constraintWidth > _leadingWidth + _horizontalPadding) {
      return constraintWidth - _leadingWidth - _horizontalPadding;
    }
    return 240;
  }

  static double _rowExtent(
    BuildContext context,
    Task task,
    double maxTextWidth,
    TextStyle titleStyle,
  ) {
    double height = completionCheckboxRowExtent(
      context: context,
      text: task.title,
      maxTextWidth: maxTextWidth,
      textStyle: titleStyle,
      maxLines: 2,
      verticalPadding: 16,
      minHeight: 48,
    );
    if (task.dueDate != null) {
      final TextStyle subtitleStyle =
          Theme.of(context).textTheme.bodySmall ?? const TextStyle();
      final String dueLabel = 'due_label'.tr(
        namedArgs: <String, String>{
          'date': L10n.dateFormat('d MMM yyyy', context: context)
              .format(task.dueDate!),
        },
      );
      final TextPainter subtitlePainter = TextPainter(
        text: TextSpan(text: dueLabel, style: subtitleStyle),
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout(maxWidth: maxTextWidth);
      height += subtitlePainter.height + 2;
    }
    return height;
  }
}

class _LinkedTaskRow extends StatelessWidget {
  const _LinkedTaskRow({
    required this.task,
    required this.onToggle,
    required this.onOpen,
    this.syncStyleWithSlide = false,
    this.styleProgress,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onOpen;
  final bool syncStyleWithSlide;
  final Animation<double>? styleProgress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextStyle activeStyle = theme.textTheme.bodyLarge!;
    final TextStyle completedStyle = theme.textTheme.bodyLarge!.copyWith(
      decoration: TextDecoration.lineThrough,
      decorationColor: colors.onSurfaceVariant.withValues(alpha: 0.7),
      color: colors.onSurfaceVariant,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Checkbox(
                value: task.isCompleted,
                onChanged: (_) => onToggle(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                      CompletionTextLabel(
                        text: task.title,
                        isCompleted: task.isCompleted,
                        activeStyle: activeStyle,
                        completedStyle: completedStyle,
                        syncStyleWithSlide: syncStyleWithSlide,
                        styleProgress: styleProgress,
                        maxLines: 2,
                      ),
                      if (task.dueDate != null)
                        Text(
                          'due_label'.tr(
                            namedArgs: <String, String>{
                              'date': L10n.dateFormat(
                                'd MMM yyyy',
                                context: context,
                              ).format(task.dueDate!),
                            },
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Icon(
                  Icons.chevron_right,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

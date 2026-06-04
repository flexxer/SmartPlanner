import 'package:flutter/material.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';
import 'package:smart_planner/features/todo_list/presentation/widgets/task_priority_ui.dart';

/// Compact priority flag shown beside a task title (all priority levels).
class TaskPriorityIcon extends StatelessWidget {
  const TaskPriorityIcon({
    required this.priority,
    this.size = 20,
    super.key,
  });

  final TaskPriority priority;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: TaskPriorityUi.label(priority),
      child: Icon(
        TaskPriorityUi.iconData(priority),
        size: size,
        color: TaskPriorityUi.iconColor(priority, colors),
      ),
    );
  }
}

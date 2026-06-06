import 'package:flutter/material.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';

/// Priority labels, colors, and list icons.
abstract final class TaskPriorityUi {
  static String label(TaskPriority priority) {
    return L10n.priorityLabel(priority);
  }

  static IconData iconData(TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low || TaskPriority.medium => Icons.flag_outlined,
      TaskPriority.high || TaskPriority.urgent => Icons.flag,
    };
  }

  static Color iconColor(TaskPriority priority, ColorScheme colors) {
    return switch (priority) {
      TaskPriority.low => colors.onPrimaryContainer.withValues(alpha: 0.72),
      TaskPriority.medium => colors.onSecondaryContainer,
      TaskPriority.high => colors.onTertiaryContainer,
      TaskPriority.urgent => colors.error,
    };
  }

  static Color backgroundColor(TaskPriority priority, ColorScheme colors) {
    return switch (priority) {
      TaskPriority.low => colors.primaryContainer,
      TaskPriority.medium => colors.secondaryContainer,
      TaskPriority.high => colors.tertiaryContainer,
      TaskPriority.urgent => colors.errorContainer,
    };
  }

  static Color foregroundColor(TaskPriority priority, ColorScheme colors) {
    return switch (priority) {
      TaskPriority.low => colors.onPrimaryContainer,
      TaskPriority.medium => colors.onSecondaryContainer,
      TaskPriority.high => colors.onTertiaryContainer,
      TaskPriority.urgent => colors.onErrorContainer,
    };
  }
}

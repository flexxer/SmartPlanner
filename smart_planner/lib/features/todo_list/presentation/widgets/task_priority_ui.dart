import 'package:flutter/material.dart';
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';

/// Priority badge labels and colors.
abstract final class TaskPriorityUi {
  static String label(TaskPriority priority) {
    return L10n.priorityLabel(priority);
  }

  static Color backgroundColor(TaskPriority priority, ColorScheme colors) {
    return switch (priority) {
      TaskPriority.low => colors.surfaceContainerHighest,
      TaskPriority.medium => colors.secondaryContainer,
      TaskPriority.high => colors.tertiaryContainer,
      TaskPriority.urgent => colors.errorContainer,
    };
  }

  static Color foregroundColor(TaskPriority priority, ColorScheme colors) {
    return switch (priority) {
      TaskPriority.low => colors.onSurfaceVariant,
      TaskPriority.medium => colors.onSecondaryContainer,
      TaskPriority.high => colors.onTertiaryContainer,
      TaskPriority.urgent => colors.onErrorContainer,
    };
  }
}

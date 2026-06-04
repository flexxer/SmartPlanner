import 'package:isar/isar.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';

/// Parsed `daylinx://` action for routing.
sealed class DeepLinkAction {
  const DeepLinkAction();
}

/// Triggers a home-widget payload refresh (same data as day-status notification).
final class DeepLinkRefreshWidgetAction extends DeepLinkAction {
  const DeepLinkRefreshWidgetAction();
}

/// Parsed `daylinx://create?...` deep link ready for UI routing.
sealed class DeepLinkCreateAction extends DeepLinkAction {
  const DeepLinkCreateAction({required this.title});

  final String title;
}

/// Opens [TaskFormSheet] with prefilled fields.
final class DeepLinkCreateTaskAction extends DeepLinkCreateAction {
  const DeepLinkCreateTaskAction({
    required super.title,
    this.priority,
  });

  final TaskPriority? priority;
}

/// Opens [EventFormSheet] with prefilled title and optional start time.
final class DeepLinkCreateEventAction extends DeepLinkCreateAction {
  const DeepLinkCreateEventAction({
    required super.title,
    this.start,
    this.end,
  });

  final DateTime? start;
  final DateTime? end;
}

/// Opens [TaskFormSheet] with a saved [UiTemplate] applied.
final class DeepLinkCreateTaskFromTemplateAction extends DeepLinkAction {
  const DeepLinkCreateTaskFromTemplateAction({required this.templateId});

  final Id templateId;
}

import 'package:smart_planner/features/todo_list/domain/entities/task_priority.dart';

/// Parsed `daylinx://create?...` deep link ready for UI routing.
sealed class DeepLinkCreateAction {
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

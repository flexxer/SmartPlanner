import 'package:isar/isar.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';

/// Parent link state for a child task before detach-on-delete.
class DeletedChildParentState {
  const DeletedChildParentState({
    required this.childId,
    required this.parentTaskId,
    required this.sortOrder,
  });

  final Id childId;
  final Id parentTaskId;
  final int sortOrder;
}

/// Full task graph slice restorable after delete + undo.
class DeletedTaskSnapshot {
  const DeletedTaskSnapshot({
    required this.task,
    required this.attachments,
    required this.children,
    this.linkedEventId,
  });

  final Task task;
  final List<TaskAttachment> attachments;
  final List<DeletedChildParentState> children;
  final Id? linkedEventId;
}

Task taskSnapshot(Task source) {
  final Task copy = Task.create(
    title: source.title,
    description: source.description,
    dueDate: source.dueDate,
    createDate: source.createDate,
    isCompleted: source.isCompleted,
    priority: source.priority,
    parentTaskId: source.parentTaskId,
    sortOrder: source.sortOrder,
    calendarId: source.calendarId,
    googleTaskId: source.googleTaskId,
    googleTaskListId: source.googleTaskListId,
    linkedEventId: source.linkedEventId,
    reminderAt: source.reminderAt,
  )
    ..id = source.id
    ..updatedAt = source.updatedAt
    ..recurrenceRuleJson = source.recurrenceRuleJson;
  return copy;
}

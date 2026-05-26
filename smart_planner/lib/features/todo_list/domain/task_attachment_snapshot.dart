import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';

/// Deep copy of a [TaskAttachment] for undo-after-delete restore.
TaskAttachment taskAttachmentSnapshot(TaskAttachment source) {
  final TaskAttachment copy = TaskAttachment.create(
    taskId: source.taskId,
    type: source.type,
    payloadJson: source.payloadJson,
    label: source.label,
    sortOrder: source.sortOrder,
    createdAt: source.createdAt,
  );
  copy.id = source.id;
  return copy;
}

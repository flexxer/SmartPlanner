import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

/// Local attachment on a [Task] (contact, image, URL, location, note).
///
/// Pure domain model — no Isar annotations. Persistence is handled by
/// `TaskAttachmentModel` in the data layer.
class TaskAttachment {
  TaskAttachment({this.id = 0});

  TaskAttachment.create({
    required this.taskId,
    required this.type,
    required this.payloadJson,
    this.label,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Database id; `0` until persisted.
  int id = 0;

  int taskId = 0;

  TaskAttachmentType type = TaskAttachmentType.note;

  String payloadJson = '';

  /// Optional display label; falls back to payload summary in UI.
  String? label;

  int sortOrder = 0;

  DateTime createdAt = DateTime.now();
}

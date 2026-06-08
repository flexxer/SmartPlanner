import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

part 'task_attachment.g.dart';

/// Local attachment on a [Task] (contact, image, URL, location, note).
@collection
class TaskAttachment {
  Id id = Isar.autoIncrement;

  @Index()
  late int taskId;

  @Enumerated(EnumType.ordinal)
  late TaskAttachmentType type;

  late String payloadJson;

  /// Optional display label; falls back to payload summary in UI.
  String? label;

  int sortOrder = 0;

  late DateTime createdAt;

  TaskAttachment();

  TaskAttachment.create({
    required this.taskId,
    required this.type,
    required this.payloadJson,
    this.label,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

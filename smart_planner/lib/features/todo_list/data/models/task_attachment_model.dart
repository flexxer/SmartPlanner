import 'package:isar_community/isar.dart';

import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

part 'task_attachment_model.g.dart';

/// Isar persistence model for [TaskAttachment].
@collection
class TaskAttachmentModel {
  Id id = Isar.autoIncrement;

  @Index()
  late int taskId;

  @Enumerated(EnumType.ordinal)
  late TaskAttachmentType type;

  late String payloadJson;

  String? label;

  int sortOrder = 0;

  late DateTime createdAt;

  TaskAttachment toDomain() => TaskAttachment(id: id)
    ..taskId = taskId
    ..type = type
    ..payloadJson = payloadJson
    ..label = label
    ..sortOrder = sortOrder
    ..createdAt = createdAt;

  static TaskAttachmentModel fromDomain(TaskAttachment attachment) {
    final TaskAttachmentModel model = TaskAttachmentModel()
      ..taskId = attachment.taskId
      ..type = attachment.type
      ..payloadJson = attachment.payloadJson
      ..label = attachment.label
      ..sortOrder = attachment.sortOrder
      ..createdAt = attachment.createdAt;
    if (attachment.id > 0) {
      model.id = attachment.id;
    }
    return model;
  }
}

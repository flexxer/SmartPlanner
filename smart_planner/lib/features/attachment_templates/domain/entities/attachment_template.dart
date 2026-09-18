import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

/// Reusable attachment preset (location, checklist, link, note, contact).
///
/// Pure domain model — no Isar annotations. Persistence is handled by
/// `AttachmentTemplateModel` in the data layer.
class AttachmentTemplate {
  AttachmentTemplate({this.id = 0});

  factory AttachmentTemplate.create({
    required String title,
    required TaskAttachmentType type,
    required String payloadJson,
    int sortOrder = 0,
  }) {
    return AttachmentTemplate()
      ..title = title
      ..type = type
      ..payloadJson = payloadJson
      ..sortOrder = sortOrder;
  }

  /// Database id; `0` until persisted.
  int id;

  String title = '';

  TaskAttachmentType type = TaskAttachmentType.note;

  /// JSON payload matching `TaskAttachmentCodec` for [type].
  String payloadJson = '';

  int sortOrder = 0;
}

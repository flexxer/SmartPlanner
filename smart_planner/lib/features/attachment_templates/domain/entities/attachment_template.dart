import 'package:isar/isar.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

part 'attachment_template.g.dart';

/// Reusable attachment preset (location, checklist, link, note, contact).
@collection
class AttachmentTemplate {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, caseSensitive: false)
  late String title;

  @Enumerated(EnumType.ordinal)
  late TaskAttachmentType type;

  /// JSON payload matching [TaskAttachmentCodec] for [type].
  String payloadJson = '';

  int sortOrder = 0;

  AttachmentTemplate();

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
}

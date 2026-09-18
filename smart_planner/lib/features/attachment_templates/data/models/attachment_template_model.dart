import 'package:isar_community/isar.dart';

import 'package:smart_planner/features/attachment_templates/domain/entities/attachment_template.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

part 'attachment_template_model.g.dart';

/// Isar persistence model for [AttachmentTemplate].
@collection
@Name('AttachmentTemplate')
class AttachmentTemplateModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, caseSensitive: false)
  late String title;

  @Enumerated(EnumType.ordinal)
  late TaskAttachmentType type;

  String payloadJson = '';

  int sortOrder = 0;

  AttachmentTemplate toDomain() => AttachmentTemplate(id: id)
    ..title = title
    ..type = type
    ..payloadJson = payloadJson
    ..sortOrder = sortOrder;

  static AttachmentTemplateModel fromDomain(AttachmentTemplate template) {
    final AttachmentTemplateModel model = AttachmentTemplateModel()
      ..title = template.title
      ..type = template.type
      ..payloadJson = template.payloadJson
      ..sortOrder = template.sortOrder;
    if (template.id > 0) {
      model.id = template.id;
    }
    return model;
  }
}

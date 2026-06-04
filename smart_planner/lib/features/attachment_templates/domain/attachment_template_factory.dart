import 'package:smart_planner/features/attachment_templates/domain/attachment_template_labels.dart';
import 'package:smart_planner/features/attachment_templates/domain/entities/attachment_template.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_ref.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

/// Builds [AttachmentTemplate] rows from attachments or existing templates.
class AttachmentTemplateFactory {
  AttachmentTemplateFactory._();

  static AttachmentTemplate fromTaskAttachment(
    TaskAttachment attachment, {
    required String title,
    int sortOrder = 0,
  }) {
    return AttachmentTemplate.create(
      title: title,
      type: attachment.type,
      payloadJson: attachment.payloadJson,
      sortOrder: sortOrder,
    );
  }

  static AttachmentTemplate fromEventAttachment(
    EventAttachment attachment, {
    required String title,
    int sortOrder = 0,
  }) {
    return AttachmentTemplate.create(
      title: title,
      type: attachment.type,
      payloadJson: attachment.payloadJson,
      sortOrder: sortOrder,
    );
  }

  static AttachmentTemplate fromAttachmentRef(
    AttachmentRef attachment, {
    required String title,
    int sortOrder = 0,
  }) {
    return AttachmentTemplate.create(
      title: title,
      type: attachment.type,
      payloadJson: attachment.payloadJson,
      sortOrder: sortOrder,
    );
  }

  /// New template with the same payload; [title] defaults to source + copy suffix.
  static AttachmentTemplate duplicate(
    AttachmentTemplate source, {
    String? title,
    required int sortOrder,
  }) {
    final String resolvedTitle = title ??
        '${AttachmentTemplateLabels.displayTitle(source)} '
            '(${AttachmentTemplateLabels.copySuffix()})';
    return AttachmentTemplate.create(
      title: resolvedTitle.trim(),
      type: source.type,
      payloadJson: source.payloadJson,
      sortOrder: sortOrder,
    );
  }

  static bool canSaveAsTemplate(TaskAttachmentType type) {
    return switch (type) {
      TaskAttachmentType.contact ||
      TaskAttachmentType.image ||
      TaskAttachmentType.file =>
        false,
      TaskAttachmentType.url ||
      TaskAttachmentType.location ||
      TaskAttachmentType.note ||
      TaskAttachmentType.checklist =>
        true,
    };
  }
}

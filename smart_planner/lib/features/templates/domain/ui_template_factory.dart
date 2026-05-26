import 'package:smart_planner/features/templates/domain/entities/ui_template.dart';
import 'package:smart_planner/features/templates/domain/ui_template_embedded_attachment_codec.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';

/// Builds [UiTemplate] records from tasks and applies them when creating new tasks.
class UiTemplateFactory {
  UiTemplateFactory._();

  static const List<TaskAttachmentType> _embeddedPriority = <TaskAttachmentType>[
    TaskAttachmentType.location,
    TaskAttachmentType.url,
    TaskAttachmentType.note,
  ];

  /// Copies task title, description, checklist lines, and first embeddable attachment.
  static UiTemplate fromTask({
    required Task task,
    required List<TaskAttachment> attachments,
    String? titleOverride,
  }) {
    final List<String> checklistLines = <String>[];

    for (final TaskAttachment attachment in attachments) {
      if (attachment.type != TaskAttachmentType.checklist) {
        continue;
      }
      final ChecklistAttachmentPayload checklist =
          TaskAttachmentCodec.checklist(attachment);
      for (final ChecklistItemPayload item in checklist.items) {
        final String text = item.text.trim();
        if (text.isNotEmpty) {
          checklistLines.add(text);
        }
      }
    }

    TaskAttachment? embeddedSource;
    for (final TaskAttachmentType preferred in _embeddedPriority) {
      for (final TaskAttachment attachment in attachments) {
        if (attachment.type == preferred) {
          embeddedSource = attachment;
          break;
        }
      }
      if (embeddedSource != null) {
        break;
      }
    }

    final String? description = task.description?.trim();
    return UiTemplate.create(
      title: titleOverride ?? task.title,
      templateDescription:
          description != null && description.isNotEmpty ? description : null,
      checklistItems: checklistLines,
      embeddedAttachmentJson: embeddedSource != null
          ? UiTemplateEmbeddedAttachmentCodec.encodeFromAttachment(
              embeddedSource,
            )
          : null,
    );
  }
}

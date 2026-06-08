import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/templates/domain/entities/ui_template.dart';
import 'package:smart_planner/features/templates/domain/ui_template_embedded_attachment_codec.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';
import 'package:smart_planner/features/todo_list/domain/task_attachment_codec.dart';

/// Creates [TaskAttachment] rows from a [UiTemplate] after a task is saved.
class UiTemplateApplicator {
  UiTemplateApplicator({
    required TaskAttachmentRepository attachmentRepository,
  }) : _attachmentRepository = attachmentRepository;

  final TaskAttachmentRepository _attachmentRepository;

  Future<void> applyToTask({
    required Id taskId,
    required UiTemplate template,
  }) async {
    int sortOrder = await _attachmentRepository.nextSortOrder(taskId);

    final List<String> lines = template.checklistItems
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);

    if (lines.isNotEmpty) {
      final List<ChecklistItemPayload> items = <ChecklistItemPayload>[];
      int nextId = 1;
      for (final String line in lines) {
        items.add(
          ChecklistItemPayload(
            localId: nextId++,
            text: line,
          ),
        );
      }
      final String payloadJson = TaskAttachmentCodec.encodeMap(
        ChecklistAttachmentPayload(
          title: template.title.trim().isEmpty ? null : template.title.trim(),
          items: items,
        ).toJson(),
      );
      await _attachmentRepository.save(
        TaskAttachment.create(
          taskId: taskId,
          type: TaskAttachmentType.checklist,
          payloadJson: payloadJson,
          sortOrder: sortOrder++,
        ),
      );
    }

    final UiTemplateEmbeddedAttachment? embedded =
        UiTemplateEmbeddedAttachmentCodec.decode(
      template.embeddedAttachmentJson,
    );
    if (embedded != null) {
      await _attachmentRepository.save(
        TaskAttachment.create(
          taskId: taskId,
          type: embedded.type,
          payloadJson: embedded.payloadJson,
          label: embedded.label,
          sortOrder: sortOrder,
        ),
      );
    }
  }
}

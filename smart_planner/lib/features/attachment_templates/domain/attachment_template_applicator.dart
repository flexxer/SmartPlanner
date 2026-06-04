import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:smart_planner/features/attachment_templates/domain/entities/attachment_template.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/event_attachment_repository.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_attachment.dart';
import 'package:smart_planner/features/todo_list/data/repositories/task_attachment_repository.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

/// Whether [template] has enough data to create an attachment without extra input.
bool attachmentTemplateIsReady(AttachmentTemplate template) {
  if (template.payloadJson.trim().isEmpty) {
    return template.type != TaskAttachmentType.location;
  }
  if (template.type == TaskAttachmentType.location) {
    try {
      final Object? decoded = jsonDecode(template.payloadJson);
      if (decoded is! Map<String, dynamic>) {
        return false;
      }
      final LocationAttachmentPayload location =
          LocationAttachmentPayload.fromJson(decoded);
      return location.latitude != 0 || location.longitude != 0;
    } on Object {
      return false;
    }
  }
  return true;
}

/// Creates a task or event attachment from a saved [AttachmentTemplate].
class AttachmentTemplateApplicator {
  AttachmentTemplateApplicator._();

  static Future<bool> applyToTask({
    required AttachmentTemplate template,
    required Id taskId,
    required TaskAttachmentRepository repository,
  }) async {
    if (!attachmentTemplateIsReady(template)) {
      return false;
    }
    final int sortOrder = await repository.nextSortOrder(taskId);
    final String? label = _labelForTemplate(template);
    await repository.save(
      TaskAttachment.create(
        taskId: taskId,
        type: template.type,
        payloadJson: template.payloadJson,
        label: label,
        sortOrder: sortOrder,
      ),
    );
    return true;
  }

  static Future<bool> applyToEvent({
    required AttachmentTemplate template,
    required Id eventId,
    required EventAttachmentRepository repository,
  }) async {
    if (!attachmentTemplateIsReady(template)) {
      return false;
    }
    final int sortOrder = await repository.nextSortOrder(eventId);
    final String? label = _labelForTemplate(template);
    await repository.save(
      EventAttachment.create(
        eventId: eventId,
        type: template.type,
        payloadJson: template.payloadJson,
        label: label,
        sortOrder: sortOrder,
      ),
    );
    return true;
  }

  static String? _labelForTemplate(AttachmentTemplate template) {
    if (template.type == TaskAttachmentType.checklist) {
      try {
        final Object? decoded = jsonDecode(template.payloadJson);
        if (decoded is Map<String, dynamic>) {
          return ChecklistAttachmentPayload.fromJson(decoded).title;
        }
      } on Object {
        return null;
      }
    }
    if (template.type == TaskAttachmentType.location) {
      try {
        final Object? decoded = jsonDecode(template.payloadJson);
        if (decoded is Map<String, dynamic>) {
          final LocationAttachmentPayload location =
              LocationAttachmentPayload.fromJson(decoded);
          return location.label ?? location.placeName;
        }
      } on Object {
        return null;
      }
    }
    return null;
  }
}

import 'dart:convert';

import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

/// Decode/encode [TaskAttachment.payloadJson].
class TaskAttachmentCodec {
  TaskAttachmentCodec._();

  static Map<String, dynamic> decodeMap(TaskAttachment attachment) {
    return jsonDecode(attachment.payloadJson) as Map<String, dynamic>;
  }

  static String encodeMap(Map<String, dynamic> map) => jsonEncode(map);

  static ContactAttachmentPayload contact(TaskAttachment attachment) {
    return ContactAttachmentPayload.fromJson(decodeMap(attachment));
  }

  static ImageAttachmentPayload image(TaskAttachment attachment) {
    return ImageAttachmentPayload.fromJson(decodeMap(attachment));
  }

  static UrlAttachmentPayload url(TaskAttachment attachment) {
    return UrlAttachmentPayload.fromJson(decodeMap(attachment));
  }

  static LocationAttachmentPayload location(TaskAttachment attachment) {
    return LocationAttachmentPayload.fromJson(decodeMap(attachment));
  }

  static NoteAttachmentPayload note(TaskAttachment attachment) {
    return NoteAttachmentPayload.fromJson(decodeMap(attachment));
  }

  static ChecklistAttachmentPayload checklist(TaskAttachment attachment) {
    return ChecklistAttachmentPayload.fromJson(decodeMap(attachment));
  }

  static String summaryLabel(TaskAttachment attachment) {
    if (attachment.label != null && attachment.label!.trim().isNotEmpty) {
      return attachment.label!.trim();
    }
    return switch (attachment.type) {
      TaskAttachmentType.contact =>
        TaskAttachmentCodec.contact(attachment).displayName,
      TaskAttachmentType.image => 'Фото',
      TaskAttachmentType.url => _urlDisplayLabel(
          TaskAttachmentCodec.url(attachment),
        ),
      TaskAttachmentType.location => locationDisplayTitle(
          location(attachment),
          attachmentLabel: attachment.label,
        ),
      TaskAttachmentType.note => _noteSummaryLabel(
          TaskAttachmentCodec.note(attachment),
        ),
      TaskAttachmentType.checklist => _checklistSummaryLabel(
          TaskAttachmentCodec.checklist(attachment),
        ),
    };
  }

  static String _urlDisplayLabel(UrlAttachmentPayload payload) {
    final String? title = payload.label?.trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }
    return payload.url;
  }

  static String _noteSummaryLabel(NoteAttachmentPayload note) {
    final String? title = note.title?.trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }
    return _notePreview(note.body);
  }

  static String _checklistSummaryLabel(ChecklistAttachmentPayload checklist) {
    final String? title = checklist.title?.trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }
    return 'Чеклист';
  }

  static String locationDisplayTitle(
    LocationAttachmentPayload payload, {
    String? attachmentLabel,
  }) {
    final String? fromAttachment = attachmentLabel?.trim();
    if (fromAttachment != null && fromAttachment.isNotEmpty) {
      return fromAttachment;
    }
    return payload.resolvedPlaceTitle ?? 'Место на карте';
  }

  static String _notePreview(String body) {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) {
      return 'Заметка';
    }
    if (trimmed.length <= 48) {
      return trimmed;
    }
    return '${trimmed.substring(0, 48)}…';
  }
}

/// Visible label for a URL attachment (title if set, otherwise URL).
String urlAttachmentLinkLabel(UrlAttachmentPayload payload) {
  final String? title = payload.label?.trim();
  if (title != null && title.isNotEmpty) {
    return title;
  }
  return payload.url;
}

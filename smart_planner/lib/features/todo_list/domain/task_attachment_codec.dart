import 'dart:convert';

import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_payloads.dart';
import 'package:smart_planner/features/todo_list/domain/entities/attachment_ref.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

/// Decode/encode [TaskAttachment.payloadJson].
class TaskAttachmentCodec {
  TaskAttachmentCodec._();

  static Map<String, dynamic> decodeMap(AttachmentRef attachment) {
    return jsonDecode(attachment.payloadJson) as Map<String, dynamic>;
  }

  static Map<String, dynamic> decodeMapFromTask(TaskAttachment attachment) =>
      decodeMap(AttachmentRef.fromTask(attachment));

  static String encodeMap(Map<String, dynamic> map) => jsonEncode(map);

  static ContactAttachmentPayload contact(TaskAttachment attachment) =>
      contactRef(AttachmentRef.fromTask(attachment));

  static ContactAttachmentPayload contactRef(AttachmentRef attachment) {
    return ContactAttachmentPayload.fromJson(decodeMap(attachment));
  }

  static ImageAttachmentPayload image(TaskAttachment attachment) =>
      imageRef(AttachmentRef.fromTask(attachment));

  static ImageAttachmentPayload imageRef(AttachmentRef attachment) {
    return ImageAttachmentPayload.fromJson(decodeMap(attachment));
  }

  static FileAttachmentPayload fileRef(AttachmentRef attachment) {
    return FileAttachmentPayload.fromJson(decodeMap(attachment));
  }

  static UrlAttachmentPayload url(TaskAttachment attachment) =>
      urlRef(AttachmentRef.fromTask(attachment));

  static UrlAttachmentPayload urlRef(AttachmentRef attachment) {
    return UrlAttachmentPayload.fromJson(decodeMap(attachment));
  }

  static LocationAttachmentPayload location(TaskAttachment attachment) =>
      locationRef(AttachmentRef.fromTask(attachment));

  static LocationAttachmentPayload locationRef(AttachmentRef attachment) {
    return LocationAttachmentPayload.fromJson(decodeMap(attachment));
  }

  static NoteAttachmentPayload note(TaskAttachment attachment) =>
      noteRef(AttachmentRef.fromTask(attachment));

  static NoteAttachmentPayload noteRef(AttachmentRef attachment) {
    return NoteAttachmentPayload.fromJson(decodeMap(attachment));
  }

  static ChecklistAttachmentPayload checklist(TaskAttachment attachment) =>
      checklistRef(AttachmentRef.fromTask(attachment));

  static ChecklistAttachmentPayload checklistRef(AttachmentRef attachment) {
    return ChecklistAttachmentPayload.fromJson(decodeMap(attachment));
  }

  static String summaryLabel(TaskAttachment attachment) =>
      summaryLabelRef(AttachmentRef.fromTask(attachment));

  static String summaryLabelRef(AttachmentRef attachment) {
    if (attachment.label != null && attachment.label!.trim().isNotEmpty) {
      return attachment.label!.trim();
    }
    return switch (attachment.type) {
      TaskAttachmentType.contact => contactRef(attachment).displayName,
      TaskAttachmentType.image => L10n.tr('attachment_summary_photo'),
      TaskAttachmentType.file => _fileSummaryLabel(fileRef(attachment)),
      TaskAttachmentType.url => _urlDisplayLabel(urlRef(attachment)),
      TaskAttachmentType.location => locationDisplayTitle(
          locationRef(attachment),
          attachmentLabel: attachment.label,
        ),
      TaskAttachmentType.note => _noteSummaryLabel(noteRef(attachment)),
      TaskAttachmentType.checklist =>
        _checklistSummaryLabel(checklistRef(attachment)),
    };
  }

  static String _fileSummaryLabel(FileAttachmentPayload payload) {
    final String name = payload.fileName.trim();
    if (name.isNotEmpty) {
      return name;
    }
    return L10n.tr('attachment_summary_file');
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
    return L10n.tr('attachment_summary_checklist');
  }

  static String locationDisplayTitle(
    LocationAttachmentPayload payload, {
    String? attachmentLabel,
  }) {
    final String? fromAttachment = attachmentLabel?.trim();
    if (fromAttachment != null && fromAttachment.isNotEmpty) {
      return fromAttachment;
    }
    return payload.resolvedPlaceTitle ?? L10n.tr('attachment_summary_place');
  }

  static String _notePreview(String body) {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) {
      return L10n.tr('attachment_summary_note');
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

import 'dart:convert';

import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

/// Encodes/decodes [UiTemplate.embeddedAttachmentJson] for location, URL, or note payloads.
class UiTemplateEmbeddedAttachmentCodec {
  UiTemplateEmbeddedAttachmentCodec._();

  static const String _typeKey = 'type';
  static const String _labelKey = 'label';
  static const String _payloadKey = 'payload';

  static String encode({
    required TaskAttachmentType type,
    required String payloadJson,
    String? label,
  }) {
    if (!_supportedTypes.contains(type)) {
      throw ArgumentError.value(type, 'type', 'Unsupported embedded attachment type');
    }
    return jsonEncode(<String, dynamic>{
      _typeKey: type.name,
      if (label != null && label.trim().isNotEmpty) _labelKey: label.trim(),
      _payloadKey: jsonDecode(payloadJson) as Map<String, dynamic>,
    });
  }

  static UiTemplateEmbeddedAttachment? decode(String? json) {
    if (json == null || json.trim().isEmpty) {
      return null;
    }
    final Map<String, dynamic> map =
        jsonDecode(json) as Map<String, dynamic>;
    final String? typeName = map[_typeKey] as String?;
    if (typeName == null) {
      return null;
    }
    TaskAttachmentType? type;
    for (final TaskAttachmentType candidate in TaskAttachmentType.values) {
      if (candidate.name == typeName) {
        type = candidate;
        break;
      }
    }
    if (type == null || !_supportedTypes.contains(type)) {
      return null;
    }
    final Map<String, dynamic> payload =
        map[_payloadKey] as Map<String, dynamic>? ?? <String, dynamic>{};
    return UiTemplateEmbeddedAttachment(
      type: type,
      label: map[_labelKey] as String?,
      payloadJson: jsonEncode(payload),
    );
  }

  static String? encodeFromAttachment(TaskAttachment attachment) {
    if (!_supportedTypes.contains(attachment.type)) {
      return null;
    }
    return encode(
      type: attachment.type,
      payloadJson: attachment.payloadJson,
      label: attachment.label,
    );
  }

  static const Set<TaskAttachmentType> _supportedTypes = <TaskAttachmentType>{
    TaskAttachmentType.location,
    TaskAttachmentType.url,
    TaskAttachmentType.note,
  };
}

/// Decoded embedded attachment ready to persist on a [Task].
class UiTemplateEmbeddedAttachment {
  const UiTemplateEmbeddedAttachment({
    required this.type,
    required this.payloadJson,
    this.label,
  });

  final TaskAttachmentType type;
  final String payloadJson;
  final String? label;
}

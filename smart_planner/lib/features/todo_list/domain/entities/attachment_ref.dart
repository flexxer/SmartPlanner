import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

/// Unified attachment view for shared UI (tasks and calendar events).
class AttachmentRef {
  const AttachmentRef({
    required this.id,
    required this.type,
    required this.payloadJson,
    this.label,
  });

  final Id id;
  final TaskAttachmentType type;
  final String payloadJson;
  final String? label;

  factory AttachmentRef.fromTask(TaskAttachment attachment) {
    return AttachmentRef(
      id: attachment.id,
      type: attachment.type,
      payloadJson: attachment.payloadJson,
      label: attachment.label,
    );
  }

  factory AttachmentRef.fromEvent(EventAttachment attachment) {
    return AttachmentRef(
      id: attachment.id,
      type: attachment.type,
      payloadJson: attachment.payloadJson,
      label: attachment.label,
    );
  }
}

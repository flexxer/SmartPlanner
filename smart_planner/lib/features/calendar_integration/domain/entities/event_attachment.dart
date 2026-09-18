import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

/// Local attachment on a [CalendarEvent] (same types as [TaskAttachment]).
///
/// Pure domain model — no Isar annotations. Persistence is handled by
/// `EventAttachmentModel` in the data layer.
class EventAttachment {
  EventAttachment({this.id = 0});

  EventAttachment.create({
    required this.eventId,
    required this.type,
    required this.payloadJson,
    this.label,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Database id; `0` until persisted.
  int id = 0;

  int eventId = 0;

  TaskAttachmentType type = TaskAttachmentType.note;

  String payloadJson = '';

  String? label;

  int sortOrder = 0;

  DateTime createdAt = DateTime.now();
}

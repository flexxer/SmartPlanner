import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

part 'event_attachment.g.dart';

/// Local attachment on a [CalendarEvent] (same types as [TaskAttachment]).
@collection
class EventAttachment {
  Id id = Isar.autoIncrement;

  @Index()
  late int eventId;

  @Enumerated(EnumType.ordinal)
  late TaskAttachmentType type;

  late String payloadJson;

  String? label;

  int sortOrder = 0;

  late DateTime createdAt;

  EventAttachment();

  EventAttachment.create({
    required this.eventId,
    required this.type,
    required this.payloadJson,
    this.label,
    this.sortOrder = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

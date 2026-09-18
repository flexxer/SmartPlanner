import 'package:isar_community/isar.dart';

import 'package:smart_planner/features/calendar_integration/domain/entities/event_attachment.dart';
import 'package:smart_planner/features/todo_list/domain/entities/task_attachment_type.dart';

part 'event_attachment_model.g.dart';

/// Isar persistence model for [EventAttachment].
@collection
class EventAttachmentModel {
  Id id = Isar.autoIncrement;

  @Index()
  late int eventId;

  @Enumerated(EnumType.ordinal)
  late TaskAttachmentType type;

  late String payloadJson;

  String? label;

  int sortOrder = 0;

  late DateTime createdAt;

  EventAttachment toDomain() => EventAttachment(id: id)
    ..eventId = eventId
    ..type = type
    ..payloadJson = payloadJson
    ..label = label
    ..sortOrder = sortOrder
    ..createdAt = createdAt;

  static EventAttachmentModel fromDomain(EventAttachment attachment) {
    final EventAttachmentModel model = EventAttachmentModel()
      ..eventId = attachment.eventId
      ..type = attachment.type
      ..payloadJson = attachment.payloadJson
      ..label = attachment.label
      ..sortOrder = attachment.sortOrder
      ..createdAt = attachment.createdAt;
    if (attachment.id > 0) {
      model.id = attachment.id;
    }
    return model;
  }
}

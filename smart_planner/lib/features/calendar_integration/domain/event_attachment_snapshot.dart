import 'package:smart_planner/features/calendar_integration/domain/entities/event_attachment.dart';

/// Deep copy of an [EventAttachment] for undo-after-delete restore.
EventAttachment eventAttachmentSnapshot(EventAttachment source) {
  final EventAttachment copy = EventAttachment.create(
    eventId: source.eventId,
    type: source.type,
    payloadJson: source.payloadJson,
    label: source.label,
    sortOrder: source.sortOrder,
    createdAt: source.createdAt,
  );
  copy.id = source.id;
  return copy;
}

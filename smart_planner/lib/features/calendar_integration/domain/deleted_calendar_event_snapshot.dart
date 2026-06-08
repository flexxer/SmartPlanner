import 'package:isar_community/isar.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_attachment.dart';
import 'package:smart_planner/features/calendar_integration/domain/event_attachment_snapshot.dart'
    show eventAttachmentSnapshot;

/// Restorable calendar event + attachments + task links after delete + undo.
class DeletedCalendarEventSnapshot {
  const DeletedCalendarEventSnapshot({
    required this.event,
    required this.attachments,
    required this.linkedTaskIds,
    required this.wasSyncedToDevice,
    this.deleteThisInstanceOnly = false,
  });

  final CalendarEvent event;
  final List<EventAttachment> attachments;
  final List<Id> linkedTaskIds;
  final bool wasSyncedToDevice;
  final bool deleteThisInstanceOnly;
}

CalendarEvent calendarEventSnapshot(CalendarEvent source) {
  final CalendarEvent copy = CalendarEvent.fromDevice(
    deviceEventId: source.deviceEventId,
    title: source.title,
    start: source.start,
    end: source.end,
    calendarId: source.calendarId,
    colorValue: source.colorValue,
    googleEventId: source.googleEventId,
    recurrenceRule: source.recurrenceRule,
    linkedTaskIds: List<int>.from(source.linkedTaskIds),
    source: source.source,
  )
    ..id = source.id
    ..updatedAt = source.updatedAt
    ..reminderMinutesBefore = source.reminderMinutesBefore;
  return copy;
}

List<EventAttachment> eventAttachmentsSnapshot(List<EventAttachment> sources) =>
    sources.map(eventAttachmentSnapshot).toList();

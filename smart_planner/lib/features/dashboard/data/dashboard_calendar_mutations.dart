import 'package:isar/isar.dart';
import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/deleted_calendar_event_snapshot.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_attachment.dart';
import 'package:smart_planner/features/calendar_integration/domain/exceptions/calendar_exceptions.dart';
import 'package:smart_planner/features/dashboard/data/dashboard_dependencies.dart';

/// Calendar-side mutations used by [DashboardBloc].
class DashboardCalendarMutations {
  DashboardCalendarMutations(this._deps);

  final DashboardDependencies _deps;

  Future<DeletedCalendarEventSnapshot?> captureEventForDelete(
    Id eventId, {
    bool thisInstanceOnly = false,
  }) async {
    final CalendarEvent? event = await _deps.localCalendarEvents.getById(eventId);
    if (event == null) {
      return null;
    }
    final List<EventAttachment> attachments =
        await _deps.eventAttachments.getAttachmentsForEvent(eventId);
    final bool wasSynced =
        !event.isLocalOnly && await _isWritableCalendar(event.calendarId);
    return DeletedCalendarEventSnapshot(
      event: calendarEventSnapshot(event),
      attachments: eventAttachmentsSnapshot(attachments),
      linkedTaskIds: List<Id>.from(event.linkedTaskIds),
      wasSyncedToDevice: wasSynced,
      deleteThisInstanceOnly: thisInstanceOnly,
    );
  }

  Future<void> deleteCalendarEvent(
    Id eventId, {
    bool thisInstanceOnly = false,
  }) async {
    final CalendarEvent? event = await _deps.localCalendarEvents.getById(eventId);
    if (event == null) {
      return;
    }

    await _deps.reminderSync.cancelEvent(eventId);
    await _deps.eventAttachments.deleteAllForEvent(eventId);
    await _deps.calendarEventWriter.delete(
      event,
      deleteThisInstanceOnly: thisInstanceOnly,
    );
  }

  Future<void> restoreDeletedEvent(DeletedCalendarEventSnapshot snapshot) async {
    final CalendarEvent event = snapshot.event;
    await _deps.localCalendarEvents.restoreEvent(event);

    for (final EventAttachment attachment in snapshot.attachments) {
      await _deps.eventAttachments.save(attachment);
    }

    for (final Id taskId in snapshot.linkedTaskIds) {
      await _deps.taskEventLinks.linkTaskToEvent(
        taskId: taskId,
        eventId: event.id,
      );
    }

    if (snapshot.wasSyncedToDevice) {
      final DeviceCalendarInfo? calendar =
          await _findWritableCalendar(event.calendarId);
      if (calendar != null) {
        try {
          final CalendarEvent synced = await _deps.calendarEventWriter.save(
            title: event.title,
            start: event.start,
            end: event.end,
            calendar: calendar,
            recurrence: event.recurrenceRule,
            reminderMinutesBefore: event.reminderMinutesBefore,
            existing: event,
          );
          await _deps.reminderSync.syncEvent(synced);
          return;
        } on CalendarServiceException {
          // Local row is restored; device sync can be retried from edit.
        }
      }
    }

    await _deps.reminderSync.syncEvent(event);
  }

  Future<bool> _isWritableCalendar(String calendarId) async {
    final DeviceCalendarInfo? calendar = await _findWritableCalendar(calendarId);
    return calendar != null;
  }

  Future<DeviceCalendarInfo?> _findWritableCalendar(String calendarId) async {
    try {
      final DeviceCalendarService deviceCalendar = DeviceCalendarService();
      final List<DeviceCalendarInfo> calendars =
          await deviceCalendar.getCalendars();
      for (final DeviceCalendarInfo calendar in calendars) {
        if (calendar.id == calendarId && !calendar.isReadOnly) {
          return calendar;
        }
      }
    } on CalendarServiceException {
      return null;
    }
    return null;
  }
}

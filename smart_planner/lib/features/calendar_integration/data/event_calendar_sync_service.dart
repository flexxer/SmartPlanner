import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_time_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/domain/exceptions/calendar_exceptions.dart';

/// Pushes a local [CalendarEvent] to one or more writable device calendars.
class EventCalendarSyncService {
  EventCalendarSyncService({
    DeviceCalendarService? deviceCalendar,
    LocalCalendarEventRepository? localEvents,
  })  : _deviceCalendar = deviceCalendar ?? DeviceCalendarService(),
        _localEvents = localEvents ?? LocalCalendarEventRepository();

  final DeviceCalendarService _deviceCalendar;
  final LocalCalendarEventRepository _localEvents;

  /// Creates or updates the event on each writable [calendars] row and persists
  /// the device id mapping on [event].
  Future<CalendarEvent> syncToCalendars({
    required CalendarEvent event,
    required List<DeviceCalendarInfo> calendars,
  }) async {
    if (calendars.isEmpty) {
      return event;
    }

    final bool allDay = CalendarEventTimeUtils.isAllDay(event);
    final Map<String, String> mapping =
        Map<String, String>.from(event.syncedDeviceEventIds);
    DeviceCalendarInfo? primaryCalendar;

    for (final DeviceCalendarInfo calendar in calendars) {
      if (calendar.isReadOnly) {
        continue;
      }
      primaryCalendar ??= calendar;

      final String? existingDeviceId = mapping[calendar.id];
      final String deviceEventId = await _deviceCalendar.createOrUpdateEvent(
        calendarId: calendar.id,
        title: event.title,
        start: event.start,
        end: event.end,
        deviceEventId: existingDeviceId,
        recurrence: event.recurrenceRule,
        reminderMinutesBefore: event.reminderMinutesBefore,
        allDay: allDay,
      );
      mapping[calendar.id] = deviceEventId;
    }

    if (mapping.isEmpty) {
      throw CalendarServiceException(
        'syncToCalendars',
        'No writable calendars selected',
      );
    }

    event
      ..syncedDeviceEventIds = mapping
      ..colorValue = primaryCalendar?.colorValue ?? event.colorValue;
    if (primaryCalendar != null) {
      event.calendarId = primaryCalendar.id;
    }
    event.markUpdated();
    await _localEvents.saveLocalEvent(event);
    return event;
  }

  /// Deletes device rows referenced by [event.syncedDeviceEventIds].
  Future<void> deleteFromSyncedCalendars(CalendarEvent event) async {
    final Map<String, String> mapping = event.syncedDeviceEventIds;
    if (mapping.isEmpty) {
      return;
    }

    for (final MapEntry<String, String> entry in mapping.entries) {
      try {
        await _deviceCalendar.deleteDeviceEvent(
          calendarId: entry.key,
          deviceEventId: entry.value,
        );
      } on CalendarServiceException {
        // Best-effort: local delete should still proceed.
      }
    }
  }
}

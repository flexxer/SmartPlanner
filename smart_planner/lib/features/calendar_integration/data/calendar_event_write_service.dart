import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/event_source.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_recurrence.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';
import 'package:smart_planner/features/calendar_integration/domain/exceptions/calendar_exceptions.dart';

/// Persists calendar events to the device provider and mirrors metadata in Isar.
class CalendarEventWriteService {
  CalendarEventWriteService({
    DeviceCalendarService? deviceCalendar,
    LocalCalendarEventRepository? localEvents,
  })  : _deviceCalendar = deviceCalendar ?? DeviceCalendarService(),
        _localEvents = localEvents ?? LocalCalendarEventRepository();

  final DeviceCalendarService _deviceCalendar;
  final LocalCalendarEventRepository _localEvents;

  Future<CalendarEvent> save({
    required String title,
    required DateTime start,
    required DateTime end,
    required DeviceCalendarInfo calendar,
    RecurrenceRule? recurrence,
    int? reminderMinutesBefore,
    CalendarEvent? existing,
    bool allDay = false,
  }) async {
    if (calendar.isReadOnly) {
      return _saveLocalOnly(
        title: title,
        start: start,
        end: end,
        calendar: calendar,
        recurrence: recurrence,
        reminderMinutesBefore: reminderMinutesBefore,
        existing: existing,
      );
    }

    final CalendarEvent? prior = existing;
    final String? priorDeviceId =
        prior != null && !prior.isLocalOnly ? prior.deviceEventId : null;
    final bool movedToAnotherCalendar = prior != null &&
        !prior.isLocalOnly &&
        prior.calendarId != calendar.id &&
        priorDeviceId != null;

    if (movedToAnotherCalendar) {
      await _deviceCalendar.deleteDeviceEvent(
        calendarId: prior.calendarId,
        deviceEventId: priorDeviceId,
      );
    }

    final String deviceEventId = await _deviceCalendar.createOrUpdateEvent(
      calendarId: calendar.id,
      title: title,
      start: start,
      end: end,
      deviceEventId: movedToAnotherCalendar ? null : priorDeviceId,
      recurrence: recurrence,
      reminderMinutesBefore: reminderMinutesBefore,
      allDay: allDay,
    );

    final CalendarEvent mirror = CalendarEvent.fromDevice(
      deviceEventId: deviceEventId,
      title: title,
      start: start,
      end: end,
      calendarId: calendar.id,
      colorValue: calendar.colorValue,
      recurrenceRule: recurrence,
      linkedTaskIds: prior?.linkedTaskIds ?? <int>[],
      source: EventSource.device,
    )..reminderMinutesBefore = reminderMinutesBefore;

    await _localEvents.upsertDeviceEvents(<CalendarEvent>[mirror]);

    final CalendarEvent? stored =
        await _localEvents.findByDeviceEventId(deviceEventId);
    if (stored == null) {
      throw CalendarServiceException(
        'upsertDeviceEvents',
        'Event not found after device save',
      );
    }

    if (prior != null && prior.isLocalOnly && prior.id != stored.id) {
      await _migrateLinksAndDeleteLocal(prior, stored);
    }

    return stored;
  }

  Future<void> delete(
    CalendarEvent event, {
    bool deleteThisInstanceOnly = false,
  }) async {
    if (!event.isLocalOnly && await _isWritableCalendar(event.calendarId)) {
      final bool recurring = CalendarEventRecurrence.hasRepeatingRule(event);
      if (recurring && deleteThisInstanceOnly) {
        await _deviceCalendar.deleteDeviceEventInstance(
          calendarId: event.calendarId,
          deviceEventId: event.deviceEventId,
          instanceStart: event.start,
          instanceEnd: event.end,
        );
      } else {
        await _deviceCalendar.deleteDeviceEvent(
          calendarId: event.calendarId,
          deviceEventId: event.deviceEventId,
        );
      }
    }
    await _localEvents.deleteLocalEvent(event.id);
  }

  Future<bool> _isWritableCalendar(String calendarId) async {
    try {
      final List<DeviceCalendarInfo> calendars =
          await _deviceCalendar.getCalendars();
      for (final DeviceCalendarInfo calendar in calendars) {
        if (calendar.id == calendarId) {
          return !calendar.isReadOnly;
        }
      }
      return false;
    } on CalendarServiceException {
      return false;
    }
  }

  Future<CalendarEvent> _saveLocalOnly({
    required String title,
    required DateTime start,
    required DateTime end,
    required DeviceCalendarInfo calendar,
    RecurrenceRule? recurrence,
    int? reminderMinutesBefore,
    CalendarEvent? existing,
  }) async {
    final CalendarEvent event = existing != null
        ? (existing
          ..title = title
          ..start = start
          ..end = end
          ..calendarId = calendar.id
          ..colorValue = calendar.colorValue
          ..recurrenceRule = recurrence
          ..reminderMinutesBefore = reminderMinutesBefore)
        : CalendarEvent.createLocal(
            title: title,
            start: start,
            end: end,
            calendarId: calendar.id,
            colorValue: calendar.colorValue,
            recurrenceRule: recurrence,
          )..reminderMinutesBefore = reminderMinutesBefore;

    await _localEvents.saveLocalEvent(event);
    return event;
  }

  Future<void> _migrateLinksAndDeleteLocal(
    CalendarEvent fromLocal,
    CalendarEvent toDevice,
  ) async {
    for (final int taskId in List<int>.from(fromLocal.linkedTaskIds)) {
      await _localEvents.linkTask(eventId: toDevice.id, taskId: taskId);
    }
    await _localEvents.deleteLocalEvent(fromLocal.id);
  }
}

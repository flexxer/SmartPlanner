import 'package:smart_planner/features/calendar_integration/data/event_calendar_sync_service.dart';
import 'package:smart_planner/features/calendar_integration/data/repositories/local_calendar_event_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/calendar_event_recurrence.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';

/// Persists calendar events in Isar and coordinates outbound device sync.
class CalendarEventWriteService {
  CalendarEventWriteService({
    DeviceCalendarService? deviceCalendar,
    LocalCalendarEventRepository? localEvents,
    EventCalendarSyncService? syncService,
  })  : _deviceCalendar = deviceCalendar ?? DeviceCalendarService(),
        _localEvents = localEvents ?? LocalCalendarEventRepository(),
        _syncService = syncService ??
            EventCalendarSyncService(
              deviceCalendar: deviceCalendar,
              localEvents: localEvents,
            );

  final DeviceCalendarService _deviceCalendar;
  final LocalCalendarEventRepository _localEvents;
  final EventCalendarSyncService _syncService;

  /// Saves event metadata in Isar only (no device write).
  Future<CalendarEvent> saveLocal({
    required String title,
    required DateTime start,
    required DateTime end,
    RecurrenceRule? recurrence,
    int? reminderMinutesBefore,
    CalendarEvent? existing,
    bool allDay = false,
  }) async {
    final CalendarEvent event = existing != null
        ? (existing
          ..title = title
          ..start = start
          ..end = end
          ..recurrenceRule = recurrence
          ..reminderMinutesBefore = reminderMinutesBefore)
        : CalendarEvent.createLocal(
            title: title,
            start: start,
            end: end,
            calendarId: '',
            recurrenceRule: recurrence,
          )..reminderMinutesBefore = reminderMinutesBefore;

    await _localEvents.saveLocalEvent(event);
    return event;
  }

  /// Saves locally, then pushes to [calendars] when the list is non-empty.
  Future<CalendarEvent> save({
    required String title,
    required DateTime start,
    required DateTime end,
    List<DeviceCalendarInfo> syncCalendars = const <DeviceCalendarInfo>[],
    RecurrenceRule? recurrence,
    int? reminderMinutesBefore,
    CalendarEvent? existing,
    bool allDay = false,
  }) async {
    final CalendarEvent saved = await saveLocal(
      title: title,
      start: start,
      end: end,
      recurrence: recurrence,
      reminderMinutesBefore: reminderMinutesBefore,
      existing: existing,
      allDay: allDay,
    );

    if (syncCalendars.isEmpty) {
      return saved;
    }

    return _syncService.syncToCalendars(
      event: saved,
      calendars: syncCalendars,
    );
  }

  Future<void> delete(
    CalendarEvent event, {
    bool deleteThisInstanceOnly = false,
  }) async {
    if (event.isSyncedToDevice) {
      await _syncService.deleteFromSyncedCalendars(event);
    } else if (!event.isLocalOnly &&
        await _isWritableCalendar(event.calendarId)) {
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
    if (calendarId.trim().isEmpty) {
      return false;
    }
    try {
      final List<DeviceCalendarInfo> calendars =
          await _deviceCalendar.getCalendars();
      for (final DeviceCalendarInfo calendar in calendars) {
        if (calendar.id == calendarId) {
          return !calendar.isReadOnly;
        }
      }
      return false;
    } on Object {
      return false;
    }
  }
}

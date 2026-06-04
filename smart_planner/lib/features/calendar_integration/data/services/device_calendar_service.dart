import 'package:device_calendar/device_calendar.dart' hide RecurrenceRule;
import 'package:smart_planner/core/localization/l10n.dart';
import 'package:smart_planner/core/timezone/timezone_monitor.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/data/android_calendar_instances_bridge.dart';
import 'package:smart_planner/features/calendar_integration/data/device_calendar_event_bridge.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/recurrence_rule.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/domain/exceptions/calendar_exceptions.dart';

/// Работа с локальными календарями устройства через [DeviceCalendarPlugin].
class DeviceCalendarService {
  DeviceCalendarService({DeviceCalendarPlugin? plugin})
      : _plugin = plugin ?? DeviceCalendarPlugin();

  final DeviceCalendarPlugin _plugin;

  /// Проверяет, выданы ли разрешения на чтение/запись календаря.
  Future<bool> hasPermissions() async {
    final Result<bool> result = await _plugin.hasPermissions();
    return _unwrapResult(result, operation: 'hasPermissions');
  }

  /// Запрашивает разрешения у пользователя. Возвращает `true`, если доступ выдан.
  Future<bool> requestPermissions() async {
    final Result<bool> result = await _plugin.requestPermissions();
    return _unwrapResult(result, operation: 'requestPermissions');
  }

  /// Проверяет разрешения и при необходимости показывает системный запрос.
  Future<bool> ensurePermissions() async {
    await TimezoneMonitor.applyIfChanged();
    if (await hasPermissions()) {
      return true;
    }
    return requestPermissions();
  }

  /// Все календари на устройстве. Перед вызовом желательно [ensurePermissions].
  Future<List<DeviceCalendarInfo>> getCalendars() async {
    if (!await ensurePermissions()) {
      throw CalendarPermissionDeniedException();
    }

    final Result<Iterable<Calendar>> result = await _plugin.retrieveCalendars();
    final Iterable<Calendar> calendars = _unwrapResult(
      result,
      operation: 'retrieveCalendars',
    );

    return calendars
        .where((Calendar c) => c.id != null && c.name != null)
        .map(_mapCalendar)
        .toList(growable: false);
  }

  /// События из [calendarIds] за период [[from], [to]] (включительно по датам).
  Future<List<CalendarEvent>> getEvents({
    required List<String> calendarIds,
    required DateTime from,
    required DateTime to,
  }) async {
    if (calendarIds.isEmpty) {
      return const <CalendarEvent>[];
    }
    if (from.isAfter(to)) {
      throw ArgumentError.value(
        from,
        L10n.tr('calendar_argument_from'),
        L10n.tr('calendar_date_range_invalid'),
      );
    }
    if (!await ensurePermissions()) {
      throw CalendarPermissionDeniedException();
    }

    final List<DeviceCalendarInfo> allCalendars = await getCalendars();
    final Map<String, int> colorByCalendarId = <String, int>{
      for (final DeviceCalendarInfo calendar in allCalendars)
        calendar.id: calendar.colorValue,
    };

    final Set<String> idsToQuery = calendarIds.toSet();

    // Android Instances: inclusive [start, end] in UTC millis.
    final DateTime queryStart = AppDateUtils.startOfDay(from);
    final DateTime queryEnd = AppDateUtils.startOfDay(to).add(
      const Duration(days: 1, milliseconds: -1),
    );
    final RetrieveEventsParams params = RetrieveEventsParams(
      startDate: queryStart,
      endDate: queryEnd,
    );

    final Map<String, CalendarEvent> uniqueByDeviceId = <String, CalendarEvent>{};
    var usedNativeAndroidReader = false;

    if (AndroidCalendarInstancesBridge.isSupported) {
      try {
        usedNativeAndroidReader = true;
        final List<AndroidCalendarInstanceRow> rows =
            await AndroidCalendarInstancesBridge.retrieveEvents(
          calendarIds: idsToQuery.toList(growable: false),
          start: queryStart,
          end: queryEnd,
        );
        for (final AndroidCalendarInstanceRow row in rows) {
          final CalendarEvent? mapped = _mapAndroidRow(
            row,
            colorByCalendarId[row.calendarId] ?? 0xFF5C6BC0,
          );
          if (mapped == null) {
            continue;
          }
          uniqueByDeviceId[_instanceKey(mapped)] = mapped;
        }
      } on Object {
        usedNativeAndroidReader = false;
      }
    }

    if (!usedNativeAndroidReader) {
      for (final String resolvedId in idsToQuery) {
        try {
          final Result<Iterable<Event>> result = await _plugin.retrieveEvents(
            resolvedId,
            params,
          );
          final Iterable<Event> pluginEvents = _unwrapResult(
            result,
            operation: 'retrieveEvents($resolvedId)',
          );

          for (final Event event in pluginEvents) {
            final int color = colorByCalendarId[event.calendarId ?? resolvedId] ??
                colorByCalendarId[resolvedId] ??
                0xFF5C6BC0;
            final CalendarEvent? mapped = _mapEvent(event, color);
            if (mapped == null) {
              continue;
            }
            uniqueByDeviceId[_instanceKey(mapped)] = mapped;
          }
        } on Object {
          // Skip calendars that fail to load; others may still contribute events.
        }
      }
    }

    final List<CalendarEvent> allEvents = uniqueByDeviceId.values.toList(
      growable: false,
    );

    allEvents.sort((CalendarEvent a, CalendarEvent b) => a.start.compareTo(b.start));
    return allEvents;
  }

  /// События, пересекающие календарный день [day] (с запасом по TZ и all-day).
  Future<List<CalendarEvent>> getEventsForDay({
    required List<String> calendarIds,
    required DateTime day,
  }) async {
    final DateTime dayStart = AppDateUtils.startOfDay(day);
    final DateTime dayEnd = dayStart.add(const Duration(days: 1));

    final List<CalendarEvent> fetched = await getEvents(
      calendarIds: calendarIds,
      from: dayStart.subtract(const Duration(days: 2)),
      to: dayEnd.add(const Duration(days: 2)),
    );

    return fetched
        .where(
          (CalendarEvent e) =>
              _overlapsCalendarDay(event: e, dayStart: dayStart, dayEnd: dayEnd),
        )
        .toList(growable: false);
  }

  static bool _overlapsCalendarDay({
    required CalendarEvent event,
    required DateTime dayStart,
    required DateTime dayEnd,
  }) {
    if (event.start.isBefore(dayEnd) && event.end.isAfter(dayStart)) {
      return true;
    }
    // All-day / midnight edge: event ends exactly at day start.
    return AppDateUtils.isSameCalendarDay(event.start, dayStart) ||
        AppDateUtils.isSameCalendarDay(event.end, dayStart);
  }

  /// События на сегодня.
  Future<List<CalendarEvent>> getEventsForToday({
    required List<String> calendarIds,
  }) =>
      getEventsForDay(calendarIds: calendarIds, day: DateTime.now());

  /// Creates or updates an event on the device calendar. Returns the device event id.
  Future<String> createOrUpdateEvent({
    required String calendarId,
    required String title,
    required DateTime start,
    required DateTime end,
    String? deviceEventId,
    RecurrenceRule? recurrence,
    int? reminderMinutesBefore,
  }) async {
    if (!await ensurePermissions()) {
      throw CalendarPermissionDeniedException();
    }

    final Event pluginEvent = DeviceCalendarEventBridge.toPluginEvent(
      calendarId: calendarId,
      title: title,
      start: start,
      end: end,
      deviceEventId: deviceEventId,
      recurrence: recurrence,
      reminderMinutesBefore: reminderMinutesBefore,
    );

    final Result<String>? result =
        await _plugin.createOrUpdateEvent(pluginEvent);
    if (result == null) {
      throw CalendarServiceException(
        'createOrUpdateEvent',
        L10n.tr('calendar_unknown_error'),
      );
    }
    final String id = _unwrapResult(
      result,
      operation: 'createOrUpdateEvent',
    );
    if (id.isEmpty) {
      throw CalendarServiceException(
        'createOrUpdateEvent',
        L10n.tr('calendar_unknown_error'),
      );
    }
    return id;
  }

  /// Deletes a single event instance from the device calendar.
  Future<bool> deleteDeviceEvent({
    required String calendarId,
    required String deviceEventId,
  }) async {
    if (!await ensurePermissions()) {
      throw CalendarPermissionDeniedException();
    }

    final Result<bool> result =
        await _plugin.deleteEvent(calendarId, deviceEventId);
    return _unwrapResult(result, operation: 'deleteEvent');
  }

  /// Deletes one occurrence of a recurring event (or following when [deleteFollowing]).
  Future<bool> deleteDeviceEventInstance({
    required String calendarId,
    required String deviceEventId,
    required DateTime instanceStart,
    required DateTime instanceEnd,
    bool deleteFollowing = false,
  }) async {
    if (!await ensurePermissions()) {
      throw CalendarPermissionDeniedException();
    }

    final Result<bool> result = await _plugin.deleteEventInstance(
      calendarId,
      deviceEventId,
      instanceStart.millisecondsSinceEpoch,
      instanceEnd.millisecondsSinceEpoch,
      deleteFollowing,
    );
    return _unwrapResult(result, operation: 'deleteEventInstance');
  }

  /// ID календарей Google на устройстве; если нет — все доступные.
  Future<List<String>> resolveDefaultCalendarIds() async {
    final List<DeviceCalendarInfo> calendars = await getCalendars();
    if (calendars.isEmpty) {
      return <String>[];
    }

    final List<DeviceCalendarInfo> googleCalendars =
        calendars.where((DeviceCalendarInfo c) => c.isGoogleAccount).toList();

    final List<DeviceCalendarInfo> source =
        googleCalendars.isNotEmpty ? googleCalendars : calendars;

    return source.map((DeviceCalendarInfo c) => c.id).toList(growable: false);
  }

  DeviceCalendarInfo _mapCalendar(Calendar calendar) {
    return DeviceCalendarInfo(
      id: calendar.id!,
      name: calendar.name!,
      colorValue: calendar.color ?? 0xFF5C6BC0,
      accountName: calendar.accountName,
      accountType: calendar.accountType,
      isReadOnly: calendar.isReadOnly ?? false,
      isDefault: calendar.isDefault ?? false,
    );
  }

  CalendarEvent? _mapAndroidRow(
    AndroidCalendarInstanceRow row,
    int calendarColor,
  ) {
    if (row.eventId.isEmpty || row.calendarId.isEmpty) {
      return null;
    }

    DateTime start = DateTime.fromMillisecondsSinceEpoch(row.startMs);
    DateTime end = DateTime.fromMillisecondsSinceEpoch(row.endMs);

    if (row.allDay) {
      start = AppDateUtils.startOfDay(start);
      end = start.add(const Duration(days: 1));
    } else if (!end.isAfter(start)) {
      end = start.add(const Duration(hours: 1));
    }

    final String title = row.title.trim();
    return CalendarEvent.fromDevice(
      deviceEventId: row.eventId,
      title: title.isEmpty ? L10n.tr('calendar_untitled_event') : title,
      start: start,
      end: end,
      calendarId: row.calendarId,
      colorValue: calendarColor,
    );
  }

  CalendarEvent? _mapEvent(Event event, int calendarColor) {
    final String? eventId = event.eventId;
    final String? calendarId = event.calendarId;
    DateTime? start = _toLocalDateTime(event.start);
    DateTime? end = _toLocalDateTime(event.end);

    if (eventId == null || calendarId == null || start == null) {
      return null;
    }

    if (event.allDay == true) {
      start = AppDateUtils.startOfDay(start);
      end = start.add(const Duration(days: 1));
    } else if (end == null || !end.isAfter(start)) {
      end = start.add(const Duration(hours: 1));
    }

    final String title = event.title?.trim() ?? '';
    return CalendarEvent.fromDevice(
      deviceEventId: eventId,
      title: title.isEmpty ? L10n.tr('calendar_untitled_event') : title,
      start: start,
      end: end,
      calendarId: calendarId,
      colorValue: calendarColor,
    );
  }

  DateTime? _toLocalDateTime(TZDateTime? value) {
    if (value == null) {
      return null;
    }
    // Instant from Android CalendarContract → local wall clock (same as system app).
    return DateTime.fromMillisecondsSinceEpoch(value.millisecondsSinceEpoch);
  }

  static String _instanceKey(CalendarEvent event) =>
      '${event.deviceEventId}_${event.start.millisecondsSinceEpoch}';

  T _unwrapResult<T>(Result<T> result, {required String operation}) {
    if (result.isSuccess && result.data != null) {
      return result.data as T;
    }

    // Empty event list: plugin may return success with an empty collection.
    if (result.errors.isEmpty && result.data is Iterable) {
      return result.data as T;
    }

    final String details = result.errors.isEmpty
        ? L10n.tr('calendar_unknown_error')
        : result.errors.map((Object e) => e.toString()).join('; ');
    throw CalendarServiceException(operation, details);
  }
}

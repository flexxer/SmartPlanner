import 'package:device_calendar/device_calendar.dart';
import 'package:smart_planner/core/utils/app_date_utils.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
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
      return <CalendarEvent>[];
    }
    if (from.isAfter(to)) {
      throw ArgumentError.value(from, 'from', 'Дата начала позже даты окончания');
    }
    if (!await ensurePermissions()) {
      throw CalendarPermissionDeniedException();
    }

    final Map<String, int> colorByCalendarId = await _loadCalendarColors();

    final List<CalendarEvent> allEvents = <CalendarEvent>[];
    final RetrieveEventsParams params = RetrieveEventsParams(
      startDate: from,
      endDate: to,
    );

    for (final String calendarId in calendarIds) {
      final Result<Iterable<Event>> result = await _plugin.retrieveEvents(
        calendarId,
        params,
      );
      final Iterable<Event> events = _unwrapResult(
        result,
        operation: 'retrieveEvents($calendarId)',
      );

      final int color = colorByCalendarId[calendarId] ?? 0xFF5C6BC0;
      for (final Event event in events) {
        final CalendarEvent? mapped = _mapEvent(event, color);
        if (mapped != null) {
          allEvents.add(mapped);
        }
      }
    }

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
      from: dayStart.subtract(const Duration(days: 1)),
      to: dayEnd.add(const Duration(days: 1)),
    );

    return fetched
        .where(
          (CalendarEvent e) => e.start.isBefore(dayEnd) && e.end.isAfter(dayStart),
        )
        .toList(growable: false);
  }

  /// События на сегодня.
  Future<List<CalendarEvent>> getEventsForToday({
    required List<String> calendarIds,
  }) =>
      getEventsForDay(calendarIds: calendarIds, day: DateTime.now());

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
    return CalendarEvent(
      id: eventId,
      title: title.isEmpty ? 'Без названия' : title,
      start: start,
      end: end,
      calendarId: calendarId,
      colorValue: calendarColor,
    );
  }

  Future<Map<String, int>> _loadCalendarColors() async {
    final Result<Iterable<Calendar>> result = await _plugin.retrieveCalendars();
    final Iterable<Calendar> calendars = _unwrapResult(
      result,
      operation: 'retrieveCalendars',
    );
    return <String, int>{
      for (final Calendar c in calendars)
        if (c.id != null) c.id!: c.color ?? 0xFF5C6BC0,
    };
  }

  DateTime? _toLocalDateTime(TZDateTime? value) {
    if (value == null) {
      return null;
    }
    return value.toLocal();
  }

  T _unwrapResult<T>(Result<T> result, {required String operation}) {
    if (result.isSuccess && result.data != null) {
      return result.data as T;
    }

    final String details = result.errors.isEmpty
        ? 'Неизвестная ошибка'
        : result.errors.map((Object e) => e.toString()).join('; ');
    throw CalendarServiceException(operation, details);
  }
}

import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/domain/repositories/calendar_repository.dart';

/// Репозиторий календарей устройства (обёртка над [DeviceCalendarService]).
class DeviceCalendarRepository implements CalendarRepository {
  DeviceCalendarRepository({DeviceCalendarService? service})
      : _service = service ?? DeviceCalendarService();

  final DeviceCalendarService _service;

  DeviceCalendarService get service => _service;

  @override
  Future<bool> hasPermissions() => _service.hasPermissions();

  @override
  Future<bool> requestPermissions() => _service.requestPermissions();

  @override
  Future<bool> ensurePermissions() => _service.ensurePermissions();

  @override
  Future<List<DeviceCalendarInfo>> getCalendars() => _service.getCalendars();

  @override
  Future<List<CalendarEvent>> fetchEvents({
    required DateTime from,
    required DateTime to,
    required List<String> calendarIds,
  }) =>
      _service.getEvents(
        calendarIds: calendarIds,
        from: from,
        to: to,
      );
}

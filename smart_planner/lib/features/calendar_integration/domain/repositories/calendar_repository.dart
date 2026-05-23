import 'package:smart_planner/features/calendar_integration/domain/entities/calendar_event.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';

/// Контракт доступа к календарям (устройство / в будущем Google API).
abstract class CalendarRepository {
  Future<bool> hasPermissions();

  Future<bool> requestPermissions();

  Future<bool> ensurePermissions();

  Future<List<DeviceCalendarInfo>> getCalendars();

  Future<List<CalendarEvent>> fetchEvents({
    required DateTime from,
    required DateTime to,
    required List<String> calendarIds,
  });
}

import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';

/// Filters device calendars that should participate in event import.
abstract final class ImportableDeviceCalendars {
  ImportableDeviceCalendars._();

  /// System birthday/holiday feeds — not user-created events.
  static bool isSystemFeed(DeviceCalendarInfo calendar) {
    final String type = (calendar.accountType ?? '').toLowerCase();
    final String account = (calendar.accountName ?? '').toLowerCase();
    final String name = calendar.name.toLowerCase();

    const List<String> blocked = <String>[
      'birthday',
      'birthdays',
      'holiday',
      'holidays',
      'contact',
      'samsungbirthday',
      'samsungholiday',
      'local.samsung',
    ];

    for (final String token in blocked) {
      if (type.contains(token) || account.contains(token) || name.contains(token)) {
        return true;
      }
    }
    return false;
  }

  /// All calendars on the device that can hold user events.
  static List<String> ids(List<DeviceCalendarInfo> allCalendars) {
    return allCalendars
        .where((DeviceCalendarInfo c) => !isSystemFeed(c))
        .map((DeviceCalendarInfo c) => c.id)
        .toList(growable: false);
  }
}

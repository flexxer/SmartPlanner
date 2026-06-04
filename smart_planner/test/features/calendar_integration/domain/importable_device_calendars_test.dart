import 'package:flutter_test/flutter_test.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/domain/importable_device_calendars.dart';

void main() {
  group('ImportableDeviceCalendars', () {
    test('excludes birthday and holiday feeds', () {
      const List<DeviceCalendarInfo> calendars = <DeviceCalendarInfo>[
        DeviceCalendarInfo(
          id: 'user',
          name: 'flexxer87@gmail.com',
          colorValue: 0xFF000000,
          accountName: 'flexxer87@gmail.com',
          accountType: 'com.google',
        ),
        DeviceCalendarInfo(
          id: 'birthdays',
          name: 'Birthdays',
          colorValue: 0xFF000000,
          accountName: 'local.samsungbirthday',
          accountType: 'local.samsungbirthday',
        ),
        DeviceCalendarInfo(
          id: 'holidays',
          name: 'Holidays in Russia',
          colorValue: 0xFF000000,
          accountName: 'Holiday',
          accountType: 'com.android.holiday',
        ),
      ];

      expect(
        ImportableDeviceCalendars.ids(calendars),
        <String>['user'],
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/domain/linked_calendar_ids_resolver.dart';

class _FakeCalendarService extends DeviceCalendarService {
  _FakeCalendarService({
    required this.calendars,
    this.granted = true,
  });

  final List<DeviceCalendarInfo> calendars;
  final bool granted;

  @override
  Future<bool> ensurePermissions() async => granted;

  @override
  Future<List<DeviceCalendarInfo>> getCalendars() async => calendars;

  @override
  Future<List<String>> resolveDefaultCalendarIds() async =>
      calendars.map((DeviceCalendarInfo c) => c.id).toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LinkedCalendarIdsResolver', () {
    test('drops stale saved ids and repairs preferences', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'selected_calendar_ids': <String>['stale-id', 'cal-2'],
      });
      final CalendarPreferencesRepository preferences =
          CalendarPreferencesRepository();
      final _FakeCalendarService service = _FakeCalendarService(
        calendars: const <DeviceCalendarInfo>[
          DeviceCalendarInfo(id: 'cal-1', name: 'One', colorValue: 0xFF000000),
          DeviceCalendarInfo(id: 'cal-2', name: 'Two', colorValue: 0xFF000000),
        ],
      );

      final List<String> resolved = await LinkedCalendarIdsResolver.resolve(
        calendarService: service,
        preferences: preferences,
      );

      expect(resolved, <String>['cal-2']);
      expect(await preferences.getSelectedCalendarIds(), <String>['cal-2']);
    });

    test('falls back to defaults when all saved ids are stale', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'selected_calendar_ids': <String>['gone'],
      });
      final CalendarPreferencesRepository preferences =
          CalendarPreferencesRepository();
      final _FakeCalendarService service = _FakeCalendarService(
        calendars: const <DeviceCalendarInfo>[
          DeviceCalendarInfo(id: 'cal-1', name: 'One', colorValue: 0xFF000000),
        ],
      );

      final List<String> resolved = await LinkedCalendarIdsResolver.resolve(
        calendarService: service,
        preferences: preferences,
      );

      expect(resolved, <String>['cal-1']);
      expect(await preferences.getSelectedCalendarIds(), <String>['cal-1']);
    });

    test('expandForDeviceSync includes localized primary with same account email',
        () {
      const List<DeviceCalendarInfo> calendars = <DeviceCalendarInfo>[
        DeviceCalendarInfo(
          id: 'email-id',
          name: 'flexxer87@gmail.com',
          colorValue: 0xFF000000,
          accountName: 'flexxer87@gmail.com',
          accountType: 'com.google',
        ),
        DeviceCalendarInfo(
          id: 'primary-localized',
          name: 'Мой календарь',
          colorValue: 0xFF000000,
          accountName: 'flexxer87@gmail.com',
          accountType: 'com.google',
        ),
      ];

      final List<String> syncIds = LinkedCalendarIdsResolver.expandForDeviceSync(
        selectedIds: const <String>['email-id'],
        allCalendars: calendars,
      );

      expect(syncIds, containsAll(<String>['email-id', 'primary-localized']));
    });

    test('expandForDeviceSync includes all device calendars when any selected',
        () {
      const List<DeviceCalendarInfo> calendars = <DeviceCalendarInfo>[
        DeviceCalendarInfo(
          id: 'primary',
          name: 'flexxer87@gmail.com',
          colorValue: 0xFF000000,
          accountName: 'flexxer87@gmail.com',
          accountType: 'com.google',
        ),
        DeviceCalendarInfo(
          id: 'samsung',
          name: 'Samsung Calendar',
          colorValue: 0xFF000000,
          accountName: 'flexxer87@gmail.com',
          accountType: 'com.google',
        ),
        DeviceCalendarInfo(
          id: 'other-account',
          name: 'other@gmail.com',
          colorValue: 0xFF000000,
          accountName: 'other@gmail.com',
          accountType: 'com.google',
        ),
        DeviceCalendarInfo(
          id: 'birthdays',
          name: 'Birthdays',
          colorValue: 0xFF000000,
          accountName: 'local.samsungbirthday',
          accountType: 'local.samsungbirthday',
        ),
      ];

      final List<String> syncIds = LinkedCalendarIdsResolver.expandForDeviceSync(
        selectedIds: const <String>['primary'],
        allCalendars: calendars,
      );

      expect(syncIds, containsAll(<String>['primary', 'samsung', 'other-account', 'birthdays']));
    });
  });
}

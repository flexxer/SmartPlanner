import 'package:smart_planner/features/calendar_integration/data/calendar_preferences_repository.dart';
import 'package:smart_planner/features/calendar_integration/data/services/device_calendar_service.dart';
import 'package:smart_planner/features/calendar_integration/domain/entities/device_calendar_info.dart';
import 'package:smart_planner/features/calendar_integration/domain/exceptions/calendar_exceptions.dart';

/// Loads device calendars that the user enabled in app settings.
class LinkedCalendarsLoader {
  LinkedCalendarsLoader({
    DeviceCalendarService? calendarService,
    CalendarPreferencesRepository? preferences,
  })  : _calendarService = calendarService ?? DeviceCalendarService(),
        _preferences = preferences ?? CalendarPreferencesRepository();

  final DeviceCalendarService _calendarService;
  final CalendarPreferencesRepository _preferences;

  Future<LinkedCalendarsLoadResult> load({
    List<String>? selectedCalendarIds,
  }) async {
    try {
      final bool granted = await _calendarService.ensurePermissions();
      if (!granted) {
        return const LinkedCalendarsLoadResult(
          permissionDenied: true,
        );
      }

      final List<DeviceCalendarInfo> allCalendars =
          await _calendarService.getCalendars();

      if (allCalendars.isEmpty) {
        return const LinkedCalendarsLoadResult(
          calendars: <DeviceCalendarInfo>[],
          noneLinked: true,
        );
      }

      final List<String> linkedIds = await _resolveLinkedIds(
        selectedCalendarIds: selectedCalendarIds,
        allCalendars: allCalendars,
      );

      final List<DeviceCalendarInfo> matched =
          _matchCalendars(allCalendars, linkedIds);

      if (matched.isNotEmpty) {
        return LinkedCalendarsLoadResult(calendars: matched);
      }

      // Saved IDs may be stale; still let the user pick any device calendar.
      return LinkedCalendarsLoadResult(
        calendars: allCalendars,
        showingAllDeviceCalendars: true,
      );
    } on CalendarPermissionDeniedException {
      return const LinkedCalendarsLoadResult(permissionDenied: true);
    } catch (e) {
      return LinkedCalendarsLoadResult(errorMessage: e.toString());
    }
  }

  static List<DeviceCalendarInfo> _matchCalendars(
    List<DeviceCalendarInfo> allCalendars,
    List<String> linkedIds,
  ) {
    if (linkedIds.isEmpty) {
      return <DeviceCalendarInfo>[];
    }

    final Set<String> linkedSet = linkedIds.map(_normalizeId).toSet();
    return allCalendars
        .where((DeviceCalendarInfo c) => linkedSet.contains(_normalizeId(c.id)))
        .toList(growable: false);
  }

  static String _normalizeId(String id) => id.trim();

  Future<List<String>> _resolveLinkedIds({
    required List<String>? selectedCalendarIds,
    required List<DeviceCalendarInfo> allCalendars,
  }) async {
    final List<String>? saved = await _preferences.getSelectedCalendarIds();
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }

    if (selectedCalendarIds != null && selectedCalendarIds.isNotEmpty) {
      return selectedCalendarIds;
    }

    final Set<String> googleIds = allCalendars
        .where((DeviceCalendarInfo c) => c.isGoogleAccount)
        .map((DeviceCalendarInfo c) => c.id)
        .toSet();
    if (googleIds.isNotEmpty) {
      return googleIds.toList(growable: false);
    }

    return allCalendars.map((DeviceCalendarInfo c) => c.id).toList();
  }
}

class LinkedCalendarsLoadResult {
  const LinkedCalendarsLoadResult({
    this.calendars = const <DeviceCalendarInfo>[],
    this.permissionDenied = false,
    this.noneLinked = false,
    this.showingAllDeviceCalendars = false,
    this.errorMessage,
  });

  final List<DeviceCalendarInfo> calendars;
  final bool permissionDenied;
  final bool noneLinked;
  final bool showingAllDeviceCalendars;
  final String? errorMessage;

  bool get hasCalendars => calendars.isNotEmpty;
}
